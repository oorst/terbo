CREATE OR REPLACE FUNCTION sales.line_items(integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      li.line_item_id,
      li.order_id,
      li.product_id,
      li.line_position,
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
    FROM sales.order o
    INNER JOIN sales.line_item li
      USING (order_id)
    LEFT JOIN prd.product_v pv
      USING (product_id)
    LEFT JOIN prd.price(product_id) pr
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
    WHERE o.order_id = $1
    ORDER BY li.line_position, li.created
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.line_items(json, OUT result json) AS
$$
BEGIN
  SELECT sales.line_items(($1->>'order_id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql';
