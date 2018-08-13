CREATE OR REPLACE FUNCTION sales.issue_quote (json, OUT result json) AS
$$
BEGIN
  IF $1->>'quoteId' IS NULL THEN
    RAISE EXCEPTION 'must provide quoteId to issue quote';
  END IF;

  UPDATE sales.quote q SET (
    issued_at,
    status,
    expiry_date
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * q.period)::date
  )
  WHERE q.quote_id = ($1->>'quoteId')::integer;

  SELECT sales.get_quote(($1->>'quoteId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
