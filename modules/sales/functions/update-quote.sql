CREATE OR REPLACE FUNCTION sales.update_quote (json, OUT result json) AS
$$
BEGIN
  IF $1->'documentId' IS NULL THEN
    RAISE EXCEPTION 'documentId must be provided to update quote';
  END IF;

  EXECUTE (
    SELECT
      format('UPDATE sales.quote_v SET (%s) = (%s) WHERE document_id = ''%s''', c.column, c.value, c.document_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'documentId')::integer AS document_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'contactId' THEN 'contact_id'
            ELSE p.key
          END AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'documentId' AND p.key IN (
          'contactId',
          'period',
          'notes',
          'data'
        )
      ) q
    ) c
  );

  SELECT format('{ "documentId": %s, "ok": true }', $1->>'documentId')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
