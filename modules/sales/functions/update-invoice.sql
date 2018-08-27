CREATE OR REPLACE FUNCTION sales.update_invoice (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE sales.invoice SET (%s) = (%s) WHERE invoice_id = ''%s''', c.column, c.value, c.invoice_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'invoiceId')::integer AS invoice_id
      FROM (
        SELECT
          p.key AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'invoiceId'
      ) q
    ) c
  );

  SELECT format('{ "invoiceId": %s, "ok": true }', $1->>'invoiceId')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
