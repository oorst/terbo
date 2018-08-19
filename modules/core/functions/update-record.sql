/*
This is a convenience function that updates a record based on table name
and assumes using an integer as primary key.
*/

CREATE OR REPLACE FUNCTION updateRecord (_table text, _key text, json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format(
        'UPDATE %s SET (%s) = (%s) WHERE %s = %s',
        _table,
        c.column,
        c.value,
        _key,
        ($3->>_key)::integer
      )
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value
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
        WHERE p.key != _key
      ) q
    ) c
  );

  SELECT format('{ "ok": true }') INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
