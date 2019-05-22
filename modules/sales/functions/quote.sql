CREATE OR REPLACE FUNCTION sales.quote (uuid, OUT result json) AS
$$
BEGIN
  WITH quote AS (
    SELECT
      q.quote_uuid,
      d.document_num,
      d.approval_status,
      to_char(q.expiry_date, core.setting('default_date_format')) AS expiry_date,
      o.order_uuid,
      p.name AS customer_name
    FROM sales.quote q
    INNER JOIN core.document d
      ON d.document_uuid = q.quote_uuid
    INNER JOIN sales.order o
      ON o.order_uuid = q.order_uuid
    LEFT JOIN core.party p
      ON p.party_uuid = o.customer_uuid
    WHERE q.quote_uuid = $1
  )
  SELECT json_strip_nulls(to_json(q)) INTO result
  FROM quote q;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.quote (json, OUT result json) AS
$$
BEGIN
  result = sales.quote(($1->>'quote_uuid')::uuid);
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
