/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION scm.update_attribute (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE scm.attribute SET (%s) = (%s) WHERE attribute_id = ''%s''', c.column, c.value, c.attribute_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'attributeId')::integer AS attribute_id
      FROM (
        SELECT
          p.key AS column,
          CASE
            -- check if it's a number
            -- WHEN p.value ~ '^\d+(.\d+)?$' THEN
            --   p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'attributeId'
      ) q
    ) c
  );

  SELECT format('{ "attributeId": "%s", "ok": true }', $1->>'attributeId')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
