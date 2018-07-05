CREATE OR REPLACE FUNCTION prd.get_product_abbr (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_id AS id,
      pr.uuid,
      pr.type,
      COALESCE(pr.code, fam.code) AS code,
      COALESCE(pr.sku, fam.sku) AS sku,
      COALESCE(pr.manufacturer_code, fam.manufacturer_code) AS "manufacturerCode",
      COALESCE(pr.supplier_code, fam.supplier_code) AS "supplierCode",
      COALESCE(pr.name, fam.name) AS name,
      COALESCE(pr.description, fam.description) AS description,
      pr.created,
      pr.modified
    FROM prd.product pr
    LEFT JOIN prd.product fam
      ON fam.product_id = pr.family_id
    WHERE pr.product_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.get_product_abbr (json, OUT result json) AS
$$
BEGIN
  SELECT prd.get_product_abbr(product_id) INTO result
  FROM prd.product
  WHERE product_id = ($1->>'id')::integer OR code = ($1->>'code') OR sku = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
