CREATE OR REPLACE FUNCTION prd.create_component (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."parentId" AS parent_id,
      j."productId" AS product_id,
      j.quantity
    FROM json_to_record($1) AS j (
      "parentId"  integer,
      "productId" integer,
      quantity    numeric(10,3)
    )
  ), component AS (
    INSERT INTO prd.component (
      parent_id,
      product_id,
      quantity
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      component_id AS "componentId"
    FROM component
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
