CREATE OR REPLACE FUNCTION prd.get_product (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_id AS id,
      pr.type,
      pr.code,
      pr.sku,
      pr.name,
      pr.description,
      pr.url,
      -- Family
      fam.name AS "familyName",
      coalesce(pr.name, fam.name) AS "$name",
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
      -- UOM
      (
        SELECT to_json(r)
        FROM (
          SELECT
            uom.uom_id AS id,
            uom.name AS name,
            uom.abbr AS abbr,
            uom.type AS type
        ) r
        WHERE NOT (r IS NULL)
      ) AS uom,
      -- Units
      (
        SELECT json_agg(r)
        FROM (
          SELECT
            pu.multiply,
            pu.divide,
            uom.name,
            uom.abbr
          FROM prd.product_uom pu
          INNER JOIN prd.uom uom
            ON uom.uom_id = pu.uom_id
          WHERE pu.product_id = pr.product_id
        ) r
      ) AS units,
      -- Tags
      (
        SELECT json_agg(tag.name)
        FROM prd.product_tag pt
        INNER JOIN prd.tag tag
          USING (tag_id)
        WHERE pt.product_id = pr.product_id
      ) AS tags,
      (
        SELECT json_agg(r)
        FROM (
          SELECT
            cost.amount,
            cost.created,
            cost.end_at AS "endAt"
          FROM prd.cost cost
          WHERE cost.product_id = pr.product_id
          ORDER BY cost.created DESC
        ) r
      ) AS "costHistory",
      (
        SELECT json_agg(r)
        FROM (
          SELECT
            price.price_id AS "priceId",
            price.gross,
            price.net,
            price.markup,
            price.markup_id AS "markupId",
            price.created
          FROM prd.price price
          WHERE price.product_id = pr.product_id
          ORDER BY price.created DESC
        ) r
      ) AS "priceHistory",
      -- Composition
      composition.composition_id AS "compositionId",
      composition.explode AS "explode",
      (
        SELECT array_agg(c)
        FROM (
          SELECT
            component.component_id AS "componentId",
            component.quantity,
            component.product_id AS "productId",
            p.name
          FROM prd.component component
          LEFT JOIN prd.product_abbr_v p
            USING (product_id)
          WHERE component.parent_id = pr.product_id
            AND component.end_at IS NULL
        ) c
      ) AS components,
      -- Pricing
      coalesce(
        prd.composite_product_gross(pr.product_id),
        price.gross,
        cost.amount * (1 + (coalesce(price.markup, markup.amount)) / 100.00)
      )::numeric(10,2) AS "$gross",
      price.net AS net,
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
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (cost.product_id)
        cost.product_id,
        cost.amount
      FROM prd.cost cost
      WHERE cost.product_id = pr.product_id AND (cost.end_at > CURRENT_TIMESTAMP OR cost.end_at IS NULL)
      ORDER BY cost.product_id, cost.cost_id DESC
    ) cost
      ON cost.product_id = pr.product_id
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (price.product_id)
        price.product_id,
        price.price_id,
        price.gross,
        price.net,
        price.markup,
        price.markup_id
      FROM prd.price price
      WHERE price.product_id = pr.product_id
      ORDER BY price.product_id, price.price_id DESC
    ) price
      ON price.product_id = pr.product_id
    LEFT JOIN prd.markup markup
      ON markup.markup_id = price.markup_id
    LEFT JOIN prd.composition composition
      ON composition.composition_id = pr.composition_id
    WHERE pr.product_id = $1
      AND (pr.end_at IS NULL OR pr.end_at > CURRENT_TIMESTAMP)
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.get_product (json, OUT result json) AS
$$
BEGIN
  SELECT prd.get_product(product_id) INTO result
  FROM prd.product
  WHERE product_id = ($1->>'id')::integer OR code = ($1->>'code') OR sku = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
