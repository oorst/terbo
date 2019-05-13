CREATE OR REPLACE FUNCTION sales.list_invoices (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_uuid,
      recipient.name,
      NULLIF(
        (
          (i.payment_status = 'OWING') AND (i.due_date < CURRENT_TIMESTAMP)
        ),
        FALSE
      ) AS overdue
    FROM sales.invoice i
    LEFT JOIN core.party_v recipient
      ON recipient.party_uuid = i.recipient_uuid
    LIMIT 20
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION sales.list_invoices (json, OUT result json) AS
$$
BEGIN
  WITH invoice AS (
    SELECT
      i.*
    FROM sales.invoice i
    WHERE $1->'order_uuid' IS NOT NULL
      AND i.order_uuid = ($1->>'order_uuid')::uuid

    UNION ALL

    SELECT
      i.*
    FROM sales.invoice i
    INNER JOIN sales.partial_invoice par
      USING (invoice_uuid)
    WHERE $1->'invoice_uuid' IS NOT NULL
      AND par.parent_uuid = ($1->>'invoice_uuid')::uuid
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_uuid,
      i.issued_at,
      p.name AS recipient_name
    FROM invoice i
    LEFT JOIN core.party_v p
      ON p.party_uuid = i.recipient_uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
