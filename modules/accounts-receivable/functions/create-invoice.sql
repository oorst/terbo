CREATE OR REPLACE FUNCTION ar.create_invoice (json, OUT result json) AS
$$
DECLARE
  new_invoice_uuid uuid;
BEGIN
  WITH document AS (
    INSERT INTO core.document (
      data
    ) VALUES (
      ($1->>'data')::jsonb
    )
    RETURNING *
  )
  INSERT INTO ar.invoice (
    invoice_uuid,
    payor,
    due_date
  )
  SELECT
    (SELECT document_uuid FROM document),
    p.payor,
    COALESCE(p.due_date, )
  FROM json_to_record($1) AS p (
    payor    uuid,
    due_date timestamptz
  )
  RETURNING invoice_uuid INTO new_invoice_uuid;

  SELECT ar.invoice(new_invoice_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;