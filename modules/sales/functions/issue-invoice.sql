CREATE OR REPLACE FUNCTION sales.issue_invoice (json, OUT result json) AS
$$
BEGIN
  IF $1->>'documentId' IS NULL THEN
    RAISE EXCEPTION 'must provide invoiceId to issue an issue';
  END IF;

  UPDATE sales.invoice_v i SET (
    issued_at,
    status,
    due_date
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * i.period)::date
  )
  WHERE i.document_id = ($1->>'documentId')::integer;

  SELECT sales.get_invoice(($1->>'documentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
