/**
 * Create a line_item_t given a product_uuid.
 * Use this function to populate fields when creating line items for an order
 * or when checking the price of a product.
 */

CREATE OR REPLACE FUNCTION sales.line_item(uuid, OUT result sales.line_item_t) AS
$$
BEGIN
  SELECT
    li.line_item_uuid,
    li.order_uuid,
    li.product_uuid,
    li.line_position,
    p.code,
    p.sku,
    p.name AS product_name,
    p.short_desc AS product_short_desc,
    li.gross AS line_item_gross,  -- User defined gross of the line
    pr.product_gross,
    li.price AS line_item_price,  -- User defined price of the line
    pr.product_price,
    (COALESCE(li.gross, pr.product_gross) * li.quantity) AS line_gross,
    (COALESCE(li.price, pr.product_price) * li.quantity) AS line_price,
    p.uom_id,
    p.uom_name,
    p.uom_abbr,
    li.quantity,
    FALSE AS tax_excluded,
    NULL::uuid AS delivery_uuid,
    li.created,
    li.modified
  INTO
    result
  FROM sales.line_item li
  LEFT JOIN prd.product_v p
    USING (product_uuid)
  LEFT JOIN sales.product_price(li.product_uuid) pr
    ON pr.product_uuid = li.product_uuid
  WHERE li.line_item_uuid = $1;
END
$$
LANGUAGE 'plpgsql';
