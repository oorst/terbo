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
    WHERE i.invoice_id = coalesce(($1->>'invoiceId')::integer, id)
  ), totals AS (
    SELECT
      (SELECT invoice_id FROM invoice) AS invoice_id,
      sum(r."grossLineTotal") AS "grossTotal",
      sum(r."netLineTotal") AS "netTotal"
    FROM jsonb_to_recordset(
      (SELECT data->'lineItems' FROM invoice)
    ) AS r (
      "grossLineTotal" numeric(10,2),
      "netLineTotal"   numeric(10,2)
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      invoice.invoice_id AS "invoiceId",
      invoice.recipient_id AS "recipientId",
      rec.name AS "recipientName",
      rec.type AS "recipientType",
      invoice.status,
      invoice.short_desc AS "shortDescription",
      invoice.data->'lineItems' AS "lineItems",
      timezone('Australia/Melbourne', invoice.created)::date AS "createdDate",
      invoice.issued_at::date AS "issueDate",
      invoice.due_date AS "dueDate",
      NULLIF(
        (invoice.due_date < CURRENT_TIMESTAMP) AND invoice.payment_status = 'OWING',
        FALSE
      ) AS overdue,
      invoice.payment_status AS "paymentStatus",
      invoice.period,
      invoice.notes,
      p.name AS "createdByName",
      p.email AS "createdByEmail",
      p.mobile AS "createdByMobile",
      p.phone AS "createdByPhone",
      par.parent_id AS "parentId",
      t."grossTotal",
      t."netTotal",
      (t."netTotal" - t."grossTotal") AS "taxTotal"
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
