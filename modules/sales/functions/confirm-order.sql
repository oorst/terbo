CREATE OR REPLACE FUNCTION sales.confirm_order (json, OUT result  json) AS
$$
BEGIN
  UPDATE sales.order o SET (
    status
  ) = (
    'CONFIRMED'::order_status_t
  )
  WHERE o.order_id = ($1->>'order_id')::integer;
  
  -- Fill in line item fields
  WITH locked_line_item AS
  (
    SELECT
      li.line_item_id,
      locked_pricing.gross,
      locked_pricing.price,
      CASE
        WHEN li.total_price IS NOT NULL THEN
          (li.total_price * 0.909090909)::numeric(10,2)
        WHEN li.total_gross IS NOT NULL THEN li.total_gross
        ELSE (locked_pricing.gross * li.quantity)::numeric(10,2)
      END AS total_gross,
      CASE
        WHEN li.total_price IS NOT NULL THEN li.total_price
        WHEN li.total_gross IS NOT NULL THEN (li.total_gross * 1.1)::numeric(10,2)
        ELSE (locked_pricing.price * li.quantity)::numeric(10,2)
      END AS total_price
    FROM sales.line_item li
    LEFT JOIN prd.product_v pv
      ON pv.product_id = li.product_id
    LEFT JOIN prd.price(li.product_id) pr
      ON pr.product_id = li.product_id
    LEFT JOIN LATERAL (
      SELECT
        li.line_item_id,
        -- Gross
        CASE
          WHEN li.price IS NOT NULL THEN
            (li.price * 0.9090909)::numeric(10,2)
          WHEN li.gross IS NOT NULL THEN li.gross
          ELSE pr.gross
        END AS gross,
        -- Price
        CASE
          WHEN li.price IS NOT NULL THEN li.price
          WHEN li.gross IS NOT NULL THEN (li.gross * 1.1)::numeric(10,2)
          ELSE pr.price
        END AS price
    ) locked_pricing ON locked_pricing.line_item_id = li.line_item_id
    WHERE li.order_id = ($1->>'order_id')::integer
  )
  UPDATE sales.line_item li SET (
    gross,
    price,
    total_gross,
    total_price
  ) = (
    lo.gross,
    lo.price,
    lo.total_gross,
    lo.total_price
  )
  FROM locked_line_item lo
  WHERE li.line_item_id = lo.line_item_id;
  
  SELECT format('{ "order_id": %s, "status": "CONFIRMED" }', $1->>'order_id')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
