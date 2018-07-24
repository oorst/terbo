CREATE OR REPLACE FUNCTION sales.issue_quote (json, OUT result json) AS
$$
BEGIN
  IF $1->>'documentId' IS NULL THEN
    RAISE EXCEPTION 'must provide documentId to issue quote';
  END IF;

  UPDATE sales.quote_v q SET (
    issued_at,
    status,
    expiry_date
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * q.period)::date
  )
  WHERE q.document_id = ($1->>'documentId')::integer;

  SELECT sales.get_quote(($1->>'documentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
