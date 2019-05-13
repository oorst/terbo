CREATE OR REPLACE FUNCTION sales.list_orders (json, OUT result json) AS
$$
BEGIN
  IF $1->>'search' IS NULL THEN
    SELECT json_strip_nulls(json_agg(r)) INTO result
    FROM (
      SELECT
        o.order_uuid,
        o.status,
        o.nickname,
        o.short_desc,
        o.buyer_uuid,
        buyer.name
        o.created
      FROM sales.order o
      LEFT JOIN core.party_v buyer
        ON buyer.party_uuid = o.buyer_uuid
      ORDER BY o.created DESC
      LIMIT 20
    ) r;
  ELSE
    SELECT json_strip_nulls(json_agg(r)) INTO result
    FROM (
      SELECT
        o.order_uuid,
        o.status,
        o.nickname,
        o.short_desc,
        o.buyer_uuid,
        buyer.name,
        o.created
      FROM sales.order o
      INNER JOIN core.party_v buyer
        ON buyer.party_uuid = o.buyer_uuid
      WHERE o.tsv @@ to_tsquery(($1->>'search') || ':*')
      ORDER BY o.created DESC
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
