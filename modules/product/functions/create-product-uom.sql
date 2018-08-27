CREATE OR REPLACE FUNCTION prd.create_product_uom (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."productId" AS product_id,
      j."uomId" AS uom_id,
      divide,
      multiply
    FROM json_to_record($1) AS j (
      "productId" integer,
      "uomId"     integer,
      divide      numeric(10,3),
      multiply    numeric(10,3)
    )
  ), product_uom AS (
    INSERT INTO prd.product_uom (
      product_id,
      uom_id,
      divide,
      multiply
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      product_uom_id AS "productUomId",
      uom_id AS "uomId",
      divide,
      multiply
    FROM product_uom
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
