CREATE OR REPLACE FUNCTION sales.invoice (
  json DEFAULT NULL,
  id integer DEFAULT NULL,
  OUT result json
) AS
$$
BEGIN
  WITH invoice AS (
    SELECT
      i.invoice_id,
      i.recipient_id,
      i.short_desc,
      i.status,
      i.payment_status,
      i.data,
      i.issued_at,
      i.due_date,
      i.period,
      i.notes,
      i.created,
      i.created_by
    FROM sales.invoice i
    WHERE i.invoice_id = coalesce(($1->>'invoice_id')::integer, id)
  ), totals AS (
    SELECT
      (SELECT invoice_id FROM invoice) AS invoice_id,
      sum(r.total_gross) AS total_gross,
      sum(r.total_price) AS total_price
    FROM jsonb_to_recordset(
      (SELECT data->'line_items' FROM invoice)
    ) AS r (
      total_gross numeric(10,2),
      total_price numeric(10,2)
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      invoice.invoice_id,
      invoice.recipient_id,
      rec.name AS recipient_name,
      rec.type AS recipient_type,
      invoice.status,
      invoice.short_desc ,
      invoice.data->'line_items' AS line_items,
      timezone('Australia/Melbourne', invoice.created)::date AS created_date,
      invoice.issued_at::date AS issue_date,
      invoice.due_date,
      NULLIF(
        (invoice.due_date < CURRENT_TIMESTAMP) AND invoice.payment_status = 'OWING',
        FALSE
      ) AS overdue,
      invoice.payment_status,
      invoice.period,
      invoice.notes,
      p.name AS created_by_name,
      p.email AS created_by_email,
      p.mobile AS creator_mobile,
      p.phone AS creator_phone,
      par.parent_id,
      t.total_gross::numeric(10,2),
      t.total_price::numeric(10,2),
      (t.total_price - t.total_gross)::numeric(10,2) AS total_tax_amount
    FROM invoice
    LEFT JOIN sales.partial_invoice par
      USING (invoice_id)
    LEFT JOIN totals t
      ON t.invoice_id = invoice.invoice_id
    LEFT JOIN party_v rec
      ON rec.party_id = invoice.recipient_id
    LEFT JOIN person p
      ON p.party_id = invoice.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
