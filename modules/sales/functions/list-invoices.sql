CREATE OR REPLACE FUNCTION sales.list_invoices (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId",
      recipient.name AS "recipientName",
      NULLIF(
        (
          (i.payment_status = 'OWING') AND (i.due_date < CURRENT_TIMESTAMP)
        ),
        FALSE
      ) AS overdue
    FROM sales.invoice i
    LEFT JOIN party_v recipient
      ON recipient.party_id = i.recipient_id
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
    WHERE $1->'orderId' IS NOT NULL
      AND i.order_id = ($1->>'orderId')::integer

    UNION ALL

    SELECT
      i.*
    FROM sales.invoice i
    INNER JOIN sales.partial_invoice par
      USING (invoice_id)
    WHERE $1->'invoiceId' IS NOT NULL
      AND par.parent_id = ($1->>'invoiceId')::integer
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId",
      i.issued_at AS "issuedAt",
      p.name AS "recipientName"
    FROM invoice i
    LEFT JOIN party_v p
      ON p.party_id = i.recipient_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
