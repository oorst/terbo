CREATE OR REPLACE FUNCTION sales.list_orders (json, OUT result json) AS
$$
BEGIN
  IF $1->>'search' IS NULL THEN
    SELECT json_strip_nulls(json_agg(r)) INTO result
    FROM (
      SELECT
        o.order_id AS "orderId",
        o.status,
        o.nickname,
        o.short_desc AS "shortDescription",
        buyer.name AS "buyerName"
      FROM sales.order o
      LEFT JOIN party_v buyer
        ON buyer.party_id = o.buyer_id
      ORDER BY o.order_id DESC
      LIMIT 20
    ) r;
  ELSE
    SELECT json_strip_nulls(json_agg(r)) INTO result
    FROM (
      SELECT
        o.order_id AS "orderId",
        o.status,
        o.nickname,
        o.short_desc AS "shortDescription",
        buyer.name AS "buyerName"
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
      ORDER BY o.order_id DESC
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
