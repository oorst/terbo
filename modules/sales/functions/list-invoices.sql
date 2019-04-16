CREATE OR REPLACE FUNCTION sales.list_invoices (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id,
      recipient.name,
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
    WHERE $1->'order_id' IS NOT NULL
      AND i.order_id = ($1->>'order_id')::integer

    UNION ALL

    SELECT
      i.*
    FROM sales.invoice i
    INNER JOIN sales.partial_invoice par
      USING (invoice_id)
    WHERE $1->'invoice_id' IS NOT NULL
      AND par.parent_id = ($1->>'invoice_id')::integer
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id,
      i.issued_at,
      p.name AS recipient_name
    FROM invoice i
    LEFT JOIN party_v p
      ON p.party_id = i.recipient_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
