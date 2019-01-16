/**
Create the JSON required for displaying document details
*/

CREATE OR REPLACE FUNCTION sales.create_document (integer, OUT result jsonb) AS
$$
BEGIN
  WITH line_item AS (
    SELECT
      li.*
    FROM sales.line_items($1) li
    LEFT JOIN prd.product_uom_v pu
      ON pu.product_id = li.product_id AND pu.uom_id = li.uom_id
    WHERE li.order_id = $1
      AND (li.end_at IS NULL)
    ORDER BY li.line_position
  ), totals AS (
    SELECT
      li.line_item_id,
      -- Gross line total
      CASE
        WHEN li.gross_line_total IS NOT NULL THEN
          li.gross_line_total
        WHEN li.gross IS NOT NULL THEN
          (li.gross * coalesce(li.quantity, 1.000))::numeric(10,2)
        WHEN li.net_line_total IS NOT NULL THEN
          (li.net_line_total * 0.90909)::numeric(10,2) -- TODO get rid of this constant!
        ELSE NULL
      END AS gross_line_total,
      -- Net line total
      CASE
        WHEN li.net_line_total IS NOT NULL THEN
          li.net_line_total
        WHEN li.gross_line_total IS NOT NULL THEN
          (li.gross_line_total * 1.1)::numeric(10,2)
        WHEN li.gross IS NOT NULL THEN
          (li.gross * coalesce(li.quantity, 1.000))::numeric(10,2) * 1.1 -- TODO get rid of this constant!
        ELSE NULL
      END AS net_line_total
    FROM line_item li
  )
  SELECT
    jsonb_build_object(
      'lineItems', jsonb_strip_nulls(jsonb_agg(r))
    ) INTO result
  FROM (
    SELECT
      li.line_item_id AS "lineItemId",
      li.product_id AS "productId",
      li.quantity,
      li.tax,
      li.note,
      li.code,
      li.name,
      li.short_desc AS "shortDescription",
      li.discount,
      li.gross,
      li.cost,
      t.gross_line_total AS "grossLineTotal",
      t.net_line_total AS "netLineTotal",
      (t.net_line_total - t.gross_line_total) AS "taxLineTotal",
      pv.name AS "productName",
      pv.code AS "productCode",
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr"
    FROM line_item li
    LEFT JOIN totals t
      ON t.line_item_id = li.line_item_id
    LEFT JOIN prd.product_list_v pv
      ON pv.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = li.uom_id
  ) r;
END
$$
LANGUAGE 'plpgsql';
