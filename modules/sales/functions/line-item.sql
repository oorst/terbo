/**
 * Create a line_item_t given a product_uuid.
 * Use this function to populate fields when creating line items for an order
 * or when checking the price of a product.
 */

CREATE OR REPLACE FUNCTION sales.line_item_price(uuid, OUT result sales.line_item_t)
RETURNS TABLE (
  product_uuid  uuid,
  product_gross numeric(10,2),
  product_price numeric(10,2),
) AS
$$
BEGIN
  SELECT
    li.line_item_id,
    li.order_id,
    li.product_id,
    li.line_position,
    pv.sku,
    pv.code AS product_code,
    pv.name AS product_name,
    pv.short_desc AS product_short_desc,
    pv.uom_name,
    pv.uom_abbr,
    li.code,
    li.name,
    li.short_desc,
    gr.gross,
    gr.total_gross,
    net.price,
    net.total_price,
    li.discount,
    li.uom_id,
    li.quantity,
    li.tax,
    li.note,
    li.created,
    li.end_at
  FROM sales.line_item li
  INNER JOIN sales.order o
    USING (order_id)
  LEFT JOIN prd.product_v pv
    USING (product_id)
  LEFT JOIN prd.price(li.product_id) pr
    ON pr.product_id = li.product_id
  LEFT JOIN LATERAL (
    SELECT
      li.line_item_id, 
      CASE
        WHEN li.gross IS NOT NULL THEN li.gross
        ELSE pr.gross
      END AS gross,
      CASE
        WHEN li.total_gross IS NOT NULL THEN li.total_gross
        WHEN li.gross IS NOT NULL THEN (li.gross * li.quantity)::numeric(10,2)
        ELSE (pr.gross * li.quantity)::numeric(10,2)
      END AS total_gross
  ) gr ON gr.line_item_id = li.line_item_id
  LEFT JOIN LATERAL (
    SELECT
      li.line_item_id, 
      CASE
        WHEN li.price IS NOT NULL THEN li.price
        ELSE pr.price
      END AS price,
      CASE
        WHEN li.total_price IS NOT NULL THEN li.total_price
        ELSE (gr.total_gross * 1.1)::numeric(10,2)
      END AS total_price
  ) net ON net.line_item_id = li.line_item_id
  WHERE li.line_item_id = $1;
END
$$
LANGUAGE 'plpgsql';
