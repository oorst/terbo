CREATE OR REPLACE FUNCTION prd.create_product (json, OUT result json) AS
$$
DECLARE
  new_product_uuid uuid;
BEGIN
  INSERT INTO prd.product (
    type,
    name,
    code,
    sku,
    short_desc,
    family_uuid
  )
  SELECT
    p.type::prd.product_t,
    p.name,
    p.code,
    p.sku,
    p.short_desc,
    p.family_uuid
  FROM json_to_record($1) AS p (
    type        text,
    name        text,
    code        text,
    sku         text,
    short_desc  text,
    family_uuid uuid
  )
  RETURNING product_uuid INTO new_product_uuid;

  SELECT prd.product(new_product_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
