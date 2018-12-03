CREATE OR REPLACE FUNCTION sales.approve_invoice (json, OUT result json) AS
$$
BEGIN
  WITH invoice AS (
    UPDATE sales.invoice i SET (
      issued_at,
      status,
      due_date
    ) = (
      (CURRENT_TIMESTAMP)::timestamp(0),
      'ISSUED',
      (CURRENT_TIMESTAMP + (INTERVAL '1 day') * i.period)::date
    )
    WHERE i.invoice_id = ($1->>'invoiceId')::integer
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      invoice_id AS "invoiceId",
      status,
      due_date AS "dueDate"
    FROM invoice
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
