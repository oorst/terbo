/**
Provide the normal form of a product in json format
*/

CREATE OR REPLACE FUNCTION prd.product_to_json (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.product_id AS "productId",
      p.family_id AS "familyId",
      to_json(supplier) AS supplier,
      p.supplier_code AS "supplierCode",
      p.code,
      p.name,
      p.description,
      p.data,
      p.type,
      p.weight,
      p.composite_id AS "compositeId",
      p.created AS "createdAt",
      p.ended_at AS "endedAt",
      p.modified,
      cost.cost_id AS "costId",
      cost.amount AS "cost",
      cost.created AS "costCreatedAt",
      price.price_id AS "priceId",
      price.gross,
      price.net,
      price.markup AS "percentMarkup",
      price.created AS "priceCreatedAt",
      markup.name AS "markupName",
      markup.amount AS "markup",
      markup.created AS "markupCreatedAt"
    FROM prd.product p
    LEFT JOIN party supplier
      ON party_id = p.supplier_id
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (cost.product_id)
        *
      FROM prd.cost cost
      WHERE cost.product_id = p.product_id
      ORDER BY cost.product_id, cost.cost_id DESC
    ) cost
      ON cost.product_id = p.product_id
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (price.product_id)
        *
      FROM prd.price price
      WHERE price.product_id = p.product_id
      ORDER BY price.product_id, price.price_id DESC
    ) price
      ON price.product_id = p.product_id
    LEFT JOIN prd.markup markup
      ON markup.markup_id = price.markup_id
    WHERE p.product_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.get_product (json, OUT result json) AS
$$
BEGIN
  SELECT prd.product_to_json(product_id) INTO result
  FROM prd.product
  WHERE product_id = ($1->>'productId')::integer OR code = ($1->>'code');
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
