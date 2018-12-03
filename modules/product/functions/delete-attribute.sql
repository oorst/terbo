CREATE OR REPLACE FUNCTION prd.delete_attribute (json, OUT result json) AS
$$
BEGIN
  DELETE FROM prd.product_attribute a
  WHERE a.attribute_id = ($1->>'attributeId')::integer;

  SELECT json_build_object(
    'ok', TRUE,
    'attributeId', ($1->>'attributeId')::integer
  ) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
