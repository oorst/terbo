/**

*/
CREATE OR REPLACE FUNCTION prd.create_price (json) RETURNS VOID AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."productUomId" AS product_uom_id,
      p.cost,
      p.gross,
      p.net,
      p.margin,
      p."marginId" AS margin_id,
      p.markup,
      p."markupId" AS markup_id,
      p."taxExcluded" AS tax_excluded
    FROM json_to_record($1) AS p (
      "productUomId"  integer,
      cost            numeric(10,2),
      "costUomId"     integer,
      gross           numeric(10,2),
      net             numeric(10,2),
      margin          numeric(5,2),
      "marginId"      integer,
      markup          numeric(10,2),
      "markupId"      integer,
      "taxExcluded"   boolean
    )
    WHERE p."productUomId" IS NOT NULL
  )
  INSERT INTO prd.price (
    product_uom_id,
    cost,
    gross,
    margin,
    margin_id,
    markup,
    markup_id,
    tax_excluded
  )
  SELECT DISTINCT ON (pr.product_uom_id)
    p.product_uom_id,
    CASE
      WHEN $1->'cost' IS NOT NULL AND p.cost IS NULL THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.cost, pr.cost)
    END,
    CASE
      WHEN json_typeof($1->'gross') = 'null' THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.gross, pr.gross)
    END,
    CASE
      WHEN $1->'margin' IS NOT NULL AND p.margin IS NULL THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.margin, pr.margin)
    END,
    CASE
      WHEN $1->'marginId' IS NOT NULL AND p.margin_id IS NULL THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.margin_id, pr.margin_id)
    END,
    CASE
      WHEN $1->'markup' IS NOT NULL AND p.markup IS NULL THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.markup, pr.markup)
    END,
    CASE
      WHEN $1->'markupId' IS NOT NULL AND p.markup_id IS NULL THEN -- an actual 'null' is present in the json payload
        NULL
      ELSE coalesce(p.markup_id, pr.markup_id)
    END,
    coalesce(p.tax_excluded, pr.tax_excluded)
  FROM payload p
  LEFT JOIN prd.price pr
    USING (product_uom_id)
  ORDER BY pr.product_uom_id, pr.price_id DESC;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
