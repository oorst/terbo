CREATE OR REPLACE FUNCTION sales.issue_document (json, OUT result json) AS
$$
BEGIN
  WITH document AS (
    UPDATE sales.source_document d SET (
      issued_at,
      status
    ) = (
      CURRENT_TIMESTAMP,
      'ISSUED'
    )
    WHERE d.document_id = ($1->>'id')::integer
  )
  SELECT format('{ "id": %s, "ok": true }', ($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
