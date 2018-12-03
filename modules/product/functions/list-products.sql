CREATE OR REPLACE FUNCTION prd.list_products (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.product_id AS "productId",
      p.short_desc AS "shortDescription",
      p.name,
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
      fam.description AS "familyDescription"
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE p.tsv @@ to_tsquery($1->>'search' || '.*')
    AND ($1->'type' IS NULL OR p.type = ($1->>'type')::product_t)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
