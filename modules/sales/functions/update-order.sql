CREATE OR REPLACE FUNCTION sales.update_order (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE sales.order SET (%s) = (%s) WHERE order_id = ''%s''', c.column, c.value, c.order_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'orderId')::integer AS order_id
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
        WHERE p.key != 'orderId' AND p.key IN (
          'notes',
          'data'
        )
      ) q
    ) c
  );

  SELECT format('{ "orderId": %s, "ok": true }', $1->>'orderId')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
