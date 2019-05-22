CREATE OR REPLACE FUNCTION ar.create_invoice (json, OUT result json) AS
$$
DECLARE
  new_invoice_uuid uuid;
BEGIN
  INSERT INTO ar.invoice (
    payor_uuid,
    due_date
  )
  SELECT
    p.payor,
    COALESCE(p.due_date, CURRENT_TIMESTAMP + interval '30 days')
  FROM json_to_record($1) AS p (
    payor_uuid uuid,
    due_date   timestamptz
  )
  RETURNING invoice_uuid INTO new_invoice_uuid;

  result = ar.invoice(new_invoice_uuid);
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;