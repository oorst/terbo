CREATE OR REPLACE FUNCTION scm.create_component (json, parent_uuid uuid DEFAULT NULL, OUT result json) AS
$$
DECLARE
  _i record;
BEGIN
  WITH payload AS (
    SELECT
      p."parentUuid" AS parent_uuid,
      p."productId" AS product_id,
      p."prototypeUuid" AS prototype_uuid,
      p.name,
      p.type,
      p.components,
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "parentUuid"    uuid,
      "productId"     integer,
      "prototypeUuid" uuid,
      name            text,
      type            scm_item_t,
      components      json,
      "userId"        integer
    )
  ), new_item AS (
    INSERT INTO scm.item (
      type,
      name,
      product_id,
      prototype_uuid
    )
    SELECT
      CASE p.type
        WHEN 'SUBASSEMBLY' THEN 'ITEM'
        ELSE p.type
      END,
      p.name,
      p.product_id,
      p.prototype_uuid
    FROM payload p
    WHERE p.type IN ('PART', 'ITEM', 'SUBASSEMBLY')
    RETURNING item_uuid
  ), new_component AS (
    INSERT INTO scm.component (
      parent_uuid,
      item_uuid,
      product_id
    )
    SELECT
      coalesce($2, p.parent_uuid),
      (SELECT item_uuid FROM new_item),
      p.product_id
    FROM payload p
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      c.item_uuid AS "itemUuid",
      c.product_id AS "productId"
    FROM new_component c
  ) r;

  -- Create components from children
  FOR _i IN SELECT * FROM json_array_elements($1->'components')
  LOOP
    PERFORM scm.create_component(_i.value, (result->>'itemUuid')::uuid);
  END LOOP;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
