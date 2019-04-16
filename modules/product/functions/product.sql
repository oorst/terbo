CREATE OR REPLACE FUNCTION prd.product (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_id,
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
      uom.uom_id,
      -- UOM
      uom.name AS uom_name,
      uom.abbr AS uom_abbr,
      uom.type AS uom_type,
      -- Family
      fam.name AS family_name,
      fam.code AS family_code,
      -- Manufacturer
      man.party_id AS manufacturer_id,
      man.name AS manufacturer_name,
      -- Supplier
      sup.party_id AS supplier_id,
      sup.name AS supplier_name,
      -- Tags
      (
        SELECT json_agg(tag.name)
        FROM prd.product_tag pt
        INNER JOIN tag
          USING (tag_id)
        WHERE pt.product_id = pr.product_id
      ) AS tags,
      -- Is this a composite product?
      NULLIF(
        EXISTS(
          SELECT
          FROM prd.component component
          WHERE component.parent_id = pr.product_id
        ),
        FALSE
      ) AS is_composite,
      -- Is this an assembly product?
      NULLIF(
        EXISTS(
          SELECT
          FROM prd.part part
          WHERE part.product_id = pr.product_id AND part.parent_uuid IS NULL
        ),
        FALSE
      ) AS is_assembly,
      -- Pricing
      price.gross,
      price.cost,
      price.gross - price.cost AS profit,
      -- Timestamps
      pr.created,
      pr.modified
    FROM prd.product pr
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = pr.family_id
    LEFT JOIN (
      SELECT
        party_id,
        name,
        type
      FROM party_v
    ) man
      ON man.party_id = pr.manufacturer_id
    LEFT JOIN (
      SELECT
        party_id,
        name,
        type
      FROM party_v
    ) sup
      ON sup.party_id = pr.supplier_id
    LEFT JOIN prd.price(pr.product_id) price
      ON price.product_id = pr.product_id
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
  WHERE product_id = ($1->>'product_id')::integer OR code = ($1->>'code') OR sku = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
