CREATE OR REPLACE FUNCTION prd.attributes (json) RETURNS TABLE (
  "attributeId" integer,
  name          text,
  value         text
) AS
$$
BEGIN
  RETURN QUERY
  SELECT
    attr.attribute_id AS "attributeId",
    attr.name,
    attr.value
  FROM prd.product_attribute attr
  WHERE attr.product_id = ($1->>'productId')::integer;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
