CREATE OR REPLACE FUNCTION prd.units (integer, OUT result json) AS
$$
BEGIN
  SELECT
    json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      pu.product_uom_id AS "productUomId",
      pu.uom_id AS "uomId",
      pu.multiply,
      pu.divide,
      pu.weight,
      pu.rounding_rule AS "roundingRule",
      puv.is_primary AS "isPrimary",
      puv.gross,
      puv.cost,
      puv.price,
      pr.margin_id AS "marginId",
      pr.markup,
      pr.markup_id AS "markupId",
      pr.tax_excluded AS "taxExcluded",
      puv.name,
      puv.type,
      puv.abbr
    FROM prd.product_uom pu
    INNER JOIN prd.product_uom_v puv
      USING (product_uom_id)
    LEFT JOIN prd.price pr
      ON pr.price_id = puv.price_id
    WHERE pu.product_id = $1
    ORDER BY puv.is_primary, pu.product_uom_id
  ) r;
END
$$
LANGUAGE 'plpgsql';
