CREATE OR REPLACE FUNCTION sales.line_item(integer)
RETURNS TABLE (
  line_item_id       integer,
  order_id           integer,
  product_id         integer,
  line_position      smallint,
  sku                text,
  product_code       text,
  product_name       text,
  product_short_desc text,
  uom_name           text,
  uom_abbr           text,
  code               text,
  name               text,
  short_desc         text,
  gross              numeric(10,2),
  total_gross        numeric(10,2),
  price              numeric(10,2),
  total_price        numeric(10,2),
  discount           numeric(5,2),
  uom_id             integer,
  quantity           numeric(10,3),
  tax                boolean,
  note               text,
  created            timestamp,
  end_at             timestamp
) AS
$$
BEGIN
  RETURN QUERY
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
