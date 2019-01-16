CREATE OR REPLACE FUNCTION prd.product (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_id AS "productId",
      pr.type,
      pr.code,
      pr.sku,
      pr.name,
      pr.short_desc AS "shortDescription",
      pr.description,
      pr.attributes,
      pr.url,
      -- Family
      fam.name AS "familyName",
      coalesce(pr.sku, pr.code, pr.supplier_code, pr.manufacturer_code) AS "$code",
      fam.code AS "familyCode",
      fam.manufacturer_code AS "familyManufacturerCode",
      fam.supplier_code AS "familySupplierCode",
      man.id AS "manufacturerId",
      man.name AS "manufacturerName",
      pr.manufacturer_code AS "manufacturerCode",
      -- Supplier
      sup.id AS "supplierId",
      sup.name AS "supplierName",
      pr.supplier_code AS "supplierCode",
      pr.data,
      -- Units
      prd.uoms(pr.product_id) AS units,
      -- Tags
      (
        SELECT json_agg(tag.name)
        FROM prd.product_tag pt
        INNER JOIN tag
          USING (tag_id)
        WHERE pt.product_id = pr.product_id
      ) AS tags,
      NOT (component IS NULL) AS "isComposite",
      pr.created,
      pr.modified
    FROM prd.product pr
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = pr.family_id
    LEFT JOIN (
      SELECT
        party_id AS id,
        name,
        type
      FROM party_v
    ) man
      ON man.id = pr.manufacturer_id
    LEFT JOIN (
      SELECT
        party_id AS id,
        name,
        type
      FROM party_v
    ) sup
      ON sup.id = pr.supplier_id
    LEFT JOIN prd.component component
      ON component.parent_id = pr.product_id
    WHERE pr.product_id = $1
      AND (pr.end_at IS NULL OR pr.end_at > CURRENT_TIMESTAMP)
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.product (json, OUT result json) AS
$$
BEGIN
  SELECT prd.product(product_id) INTO result
  FROM prd.product
  WHERE product_id = ($1->>'productId')::integer OR code = ($1->>'code') OR sku = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
