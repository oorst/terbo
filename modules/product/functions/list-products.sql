CREATE OR REPLACE FUNCTION prd.listProducts (json, OUT result json) AS
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
      p.productId AS "productId",
      p.name,
      p.code,
      p.sku,
      p.manufacturerCode AS "manufacturerCode",
      p.supplierCode AS "supplierCode",
      p.description,
      p.data->'attributes' AS attributes,
      fam.productId AS "familyId",
      fam.name AS "familyName",
      fam.code AS "familyCode",
      fam.sku AS "familySku",
      fam.manufacturerCode AS "familyManufacturerCode",
      fam.supplierCode AS "familySupplierCode",
      fam.description AS "familyDescription",
      coalesce(p.name, fam.name) AS "$name",
      coalesce(p.sku, p.code, p.supplierCode, p.manufacturerCode) AS "$code"
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.productId = p.familyId
    WHERE CONCAT(
      p.code,
      p.sku,
      p.name,
      fam.code,
      fam.supplierCode,
      fam.manufacturerCode,
      fam.name
    ) ~* regex
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
