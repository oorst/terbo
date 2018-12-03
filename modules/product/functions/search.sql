CREATE OR REPLACE FUNCTION prd.search (json, OUT result json) AS
$$
-- This function uses regular expressions to match code and names.
-- Probably not very efficient
DECLARE
  regex text;
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  regex = '.*' || ($1->>'search')::text || '.*';

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.product_id AS "productId",
      p.name,
      p.short_desc AS "shortDescription",
      p.code,
      p.sku,
      p.manufacturer_code AS "manufacturerCode",
      p.supplier_code AS "supplierCode",
      p.description,
      p.data->'attributes' AS attributes,
      fam.product_id AS "familyId",
      fam.name AS "familyName",
      fam.code AS "familyCode",
      fam.sku AS "familySku",
      fam.manufacturer_code AS "familyManufacturerCode",
      fam.supplier_code AS "familySupplierCode",
      fam.description AS "familyDescription",
      coalesce(p.name, fam.name) AS "$name",
      coalesce(p.sku, p.code, p.supplier_code, p.manufacturer_code) AS "$code"
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE CONCAT(
      p.code,
      p.sku,
      p.name,
      fam.code,
      fam.supplier_code,
      fam.manufacturer_code,
      fam.name
    ) ~* regex
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
