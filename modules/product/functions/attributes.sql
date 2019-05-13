CREATE OR REPLACE FUNCTION prd.attributes (json, OUT result json) AS
$$
BEGIN
  SELECT
    json_strip_nulls(json_agg(r))
  INTO
    result
  FROM (
    SELECT
      attr.attribute_uuid,
      attr.name,
      attr.value
    FROM prd.product_attribute attr
    WHERE attr.product_uuid = ($1->>'product_uuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
