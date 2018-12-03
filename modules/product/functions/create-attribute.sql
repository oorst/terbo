CREATE OR REPLACE FUNCTION prd.create_attribute (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."productId" AS product_id,
      j.name,
      j.value
    FROM json_to_record($1) AS j (
      "productId" integer,
      name        text,
      value       text
    )
  ), attribute AS (
    INSERT INTO prd.product_attribute (
      product_id,
      name,
      value
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      attribute_id AS "attributeId",
      product_id AS "productId",
      name,
      value
    FROM attribute
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
