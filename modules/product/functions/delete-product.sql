CREATE OR REPLACE FUNCTION prd.delete_product (json, OUT result json) AS
$$
BEGIN
  DELETE FROM prd.product p
  WHERE p.product_id = ($1->>'id')::integer;

  SELECT json_build_object('deleted', TRUE) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
