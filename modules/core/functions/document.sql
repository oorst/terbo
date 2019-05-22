CREATE OR REPLACE FUNCTION core.document (json, OUT result json) AS
$$
BEGIN
  WITH doc AS (
    SELECT
      d.*
    FROM core.document_v d
    WHERE d.document_uuid = ($1->>'document_uuid')::uuid
  )
  SELECT INTO result
    json_strip_nulls(to_json(d))
  FROM doc d;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;