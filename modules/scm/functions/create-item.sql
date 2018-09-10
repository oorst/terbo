CREATE OR REPLACE FUNCTION scm.create_item (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."productId" AS product_id,
      UPPER(p.type)::scm_item_t AS type,
      p.name,
      p."parentUuid" AS parent_uuid
    FROM json_to_record($1) AS p (
      "productId"  integer,
      type         text,
      name         text,
      "parentUuid" uuid
    )
  ), new_item AS (
    INSERT INTO scm.item (
      product_id,
      type,
      name
    )
    SELECT
      product_id,
      type,
      name
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
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
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
