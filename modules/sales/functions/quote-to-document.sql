CREATE OR REPLACE FUNCTION sales.quote_to_document (integer, OUT result jsonb) AS
$$
BEGIN
  SELECT jsonb_strip_nulls(to_jsonb(r)) INTO result
  FROM (
    SELECT
      q.*,
      (
        SELECT array_agg(li)
        FROM sales.line_item_v li
        WHERE li.order_id = q.order_id
      ) AS line_items,
      t.*
    FROM sales.quote q
    LEFT JOIN sales.order_totals(q.order_id) t
      USING (order_id)
    WHERE q.quote_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';
