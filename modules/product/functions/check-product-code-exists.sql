CREATE OR REPLACE FUNCTION
prd.check_product_code_exists (json, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT EXISTS (SELECT FROM prd.product WHERE code = $1->>'code') AS "exists"
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
