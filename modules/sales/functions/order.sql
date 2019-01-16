CREATE OR REPLACE FUNCTION sales.order (json, OUT result json) AS
$$
BEGIN
  WITH line_item AS (
    SELECT
      *
    FROM sales.line_item li
    WHERE li.order_id = ($1->>'orderId')::integer
  ), line_item_gross AS (
    SELECT
      line_item_id,
      CASE
        WHEN li.gross_line_total IS NOT NULL THEN
          li.gross_line_total
        ELSE (li.gross * li.quantity)::numeric(10,2)
      END AS gross_line_total
    FROM line_item li
  ), line_item_net AS (
    SELECT
      li.line_item_id,
      CASE
        WHEN li.net_line_total IS NOT NULL THEN
          li.net_line_total
        ELSE (g.gross_line_total * 1.1)::numeric(10,2)
      END AS net_line_total,
      -- Calcualte the gross line total when the net line total is given
      CASE
        WHEN li.net_line_total IS NOT NULL THEN
          (li.net_line_total / 1.1)::numeric(10,2)
        ELSE NULL
      END AS gross_line_total
    FROM line_item li
    INNER JOIN line_item_gross g
      ON g.line_item_id = li.line_item_id
  ), totals AS (
    SELECT
      sum(coalesce(n.gross_line_total, g.gross_line_total)) AS total_gross,
      sum(n.net_line_total) AS total_net
    FROM line_item_gross g
    INNER JOIN line_item_net n
      USING (line_item_id)
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      o.order_id AS "orderId",
      o.buyer_id AS "buyerId",
      p.name AS "buyerName",
      o.status,
      o.data,
      o.notes,
      o.purchase_order_num AS "purchaseOrderNumber",
      o.short_desc AS "shortDescription",
      (SELECT total_gross FROM totals) AS "grossTotal",
      (SELECT total_net FROM totals) AS "netTotal",
      o.created
    FROM sales.order o
    LEFT JOIN party_v p
      ON p.party_id = o.buyer_id
    WHERE o.order_id = ($1->>'orderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
