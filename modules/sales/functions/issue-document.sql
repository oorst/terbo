CREATE OR REPLACE FUNCTION sales.issue_document (json, OUT result json) AS
$$
BEGIN
  WITH document AS (
    UPDATE sales.source_document d SET (
      issued_at,
      status
    ) = (
      LOCALTIMESTAMP,
      'ISSUED'
    )
    WHERE d.document_id = ($1->>'id')::integer
  )
  SELECT '{ "ok": true }' INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
