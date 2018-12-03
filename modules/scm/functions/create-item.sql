CREATE OR REPLACE FUNCTION scm.create_item (json, OUT result json) AS
$$
DECLARE
  _i record;
BEGIN
  WITH payload AS (
    SELECT
      p."productId" AS product_id,
      p."prototypeUuid" AS prototype_uuid,
      UPPER(p.type)::scm_item_t AS type,
      p.name
    FROM json_to_record($1) AS p (
      "productId"     integer,
      "prototypeUuid" uuid,
      type            text,
      name            text
    )
  ), new_item AS (
    INSERT INTO scm.item (
      product_id,
      prototype_uuid,
      type,
      name
    )
    SELECT
      product_id,
      prototype_uuid,
      type,
      name
    FROM payload
    RETURNING *
  )
  SELECT
    json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS "itemUuid",
      i.type,
      i.name,
      p.product_id AS "productId",
      p.name AS "productName"
    FROM new_item i
    LEFT JOIN prd.product_list_v p
      USING (product_id)
  ) r;

  FOR _i IN SELECT * FROM json_array_elements($1->'components')
  LOOP
    PERFORM scm.create_component(_i.value, (result->>'itemUuid')::uuid);
  END LOOP;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
