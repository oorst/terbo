CREATE OR REPLACE FUNCTION sales.invoice (json, OUT result json) AS
$$
BEGIN
  WITH invoice AS (
    SELECT
      i.invoice_id,
      i.recipient_id,
      i.short_desc,
      i.status,
      i.data,
      i.issued_at,
      i.due_date,
      i.period,
      i.notes,
      i.created,
      i.created_by
    FROM sales.invoice i
    WHERE i.invoice_id = ($1->>'invoiceId')::integer
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      invoice.invoice_id AS "invoiceId",
      rec.name AS "recipientName",
      rec.type AS "recipientType",
      invoice.status,
      invoice.short_desc AS "shortDescription",
      invoice.data,
      invoice.created::date AS "createdDate",
      invoice.issued_at::date AS "issueDate",
      invoice.due_date AS "dueDate",
      invoice.period,
      invoice.notes,
      p.name AS "createdByName",
      p.email AS "createdByEmail",
      p.mobile AS "createdByMobile",
      p.phone AS "createdByPhone"
    FROM invoice
    INNER JOIN party_v rec
      ON rec.party_id = invoice.recipient_id
    INNER JOIN person p
      ON p.party_id = invoice.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
