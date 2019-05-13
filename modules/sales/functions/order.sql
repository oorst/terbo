CREATE OR REPLACE FUNCTION sales.order (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      o.order_uuid,
      o.customer_uuid,
      o.status,
      o.data,
      o.short_desc,
      o.created,
      p.name AS customer_name
    FROM sales.order o
    LEFT JOIN core.party_v p
      ON p.party_uuid = o.customer_uuid
    WHERE o.order_uuid = ($1->>'order_uuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
