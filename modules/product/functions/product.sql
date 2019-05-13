CREATE OR REPLACE FUNCTION prd.product (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_uuid,
      pr.name,
      pr.type,
      pr.code,
      pr.sku,
      pr.supplier_code AS supplier_code,
      pr.manufacturer_code,
      pr.supplier_code,
      pr.short_desc,
      pr.description,
      pr.url,
      pr.data,
      pr.weight,
      uom.uom_id,
      -- UOM
      uom.name AS uom_name,
      uom.abbr AS uom_abbr,
      uom.type AS uom_type,
      -- Family
      fam.name AS family_name,
      fam.code AS family_code,
      -- Manufacturer
      man.party_uuid AS manufacturer_id,
      man.name AS manufacturer_name,
      -- Supplier
      sup.party_uuid AS supplier_id,
      sup.name AS supplier_name,
      -- Is this a composite product?
      NULLIF(
        EXISTS(
          SELECT
          FROM prd.component component
          WHERE component.parent_uuid = pr.product_uuid
        ),
        FALSE
      ) AS is_composite,
      -- Is this an assembly product?
      NULLIF(
        EXISTS(
          SELECT
          FROM prd.part part
          WHERE part.product_uuid = pr.product_uuid AND part.parent_uuid IS NULL
        ),
        FALSE
      ) AS is_assembly,
      -- Timestamps
      pr.created,
      pr.modified
    FROM prd.product pr
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN prd.product fam
      ON fam.product_uuid = pr.family_uuid
    LEFT JOIN (
      SELECT
        party_uuid,
        name,
        kind
      FROM core.party_v
    ) man
      ON man.party_uuid = pr.manufacturer_uuid
    LEFT JOIN (
      SELECT
        party_uuid,
        name,
        kind
      FROM core.party_v
    ) sup
      ON sup.party_uuid = pr.supplier_uuid
    WHERE pr.product_uuid = $1
      AND (pr.end_at IS NULL OR pr.end_at > CURRENT_TIMESTAMP)
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.product (json, OUT result json) AS
$$
BEGIN
  SELECT prd.product(p.product_uuid) INTO result
  FROM prd.product p
  WHERE p.product_uuid = ($1->>'product_uuid')::uuid OR code = ($1->>'code') OR sku = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
