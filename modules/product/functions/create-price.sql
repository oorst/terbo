/**

*/
CREATE OR REPLACE FUNCTION prd.create_price (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."productId" AS product_id,
      j.cost,
      j."costUomId" AS cost_uom_id,
      j.gross,
      j.net,
      j.margin,
      j."marginId" AS margin_id,
      j.markup,
      j."markupId" AS markup_id,
      j.tax
    FROM json_to_record($1) AS j (
      "productId"     integer,
      cost            numeric(10,2),
      "costUomId"     integer,
      gross           numeric(10,2),
      net             numeric(10,2),
      margin          numeric(5,2),
      "marginId"      integer,
      markup          numeric(10,2),
      "markupId"      integer,
      tax             boolean
    )
  ), price AS (
    INSERT INTO prd.price (
      product_id,
      cost,
      cost_uom_id,
      margin,
      margin_id,
      markup,
      markup_id,
      tax
    )
    SELECT
      p.product_id,
      coalesce(p.cost, pr.cost),
      coalesce(p.cost_uom_id, pr.cost_uom_id),
      coalesce(p.margin, pr.margin),
      coalesce(p.margin_id, pr.margin_id),
      coalesce(p.markup, pr.markup),
      coalesce(p.markup_id, pr.markup_id),
      coalesce(p.tax, pr.tax)
    FROM payload p
    LEFT JOIN LATERAL (
      SELECT
        *
      FROM prd.price price
      WHERE price.product_id = p.product_id
    ) AS pr
      USING (product_id)

    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      price_id AS "priceId",
      product_id AS "productId",
      cost,
      cost_uom_id AS "costUomId",
      gross,
      net,
      margin,
      margin_id AS "marginId",
      markup,
      markup_id AS "markupId",
      tax
    FROM price
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
