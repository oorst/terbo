CREATE OR REPLACE FUNCTION pcm.update_line_item (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE pcm.line_item SET (%s) = (%s) WHERE line_item_id = ''%s''', c.column, c.value, c.line_item_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'lineItemId')::integer AS line_item_id
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
        WHERE p.key != 'lineItemId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "lineItemId": %s }', ($1->>'lineItemId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
