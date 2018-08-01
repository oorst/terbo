CREATE OR REPLACE FUNCTION sales.list_orders (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      o.order_id AS "orderId",
      o.status
    FROM sales.order o
    WHERE to_tsvector(
      concat_ws(' ',
        o.buyer_id,
        o.created_by
      )
    ) @@ plainto_tsquery(
      concat_ws(' ',
        $1->>'search',
        $1->>'userId'
      )
    )
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
