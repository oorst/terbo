CREATE OR REPLACE FUNCTION sales.list_orders (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      o.order_id AS "orderId",
      o.status,
      buyer.name
    FROM sales.order o
    INNER JOIN party_v buyer
      ON buyer.party_id = o.buyer_id
    WHERE to_tsvector(
      concat_ws(' ',
        buyer.name
      )
    ) @@ plainto_tsquery(
      concat_ws(' ',
        $1->>'search'
      )
    )
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
