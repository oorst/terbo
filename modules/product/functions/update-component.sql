CREATE OR REPLACE FUNCTION prd.update_component (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prd.component SET (%s) = (%s) WHERE component_id = ''%s''', c.column, c.value, c.component_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'component_id')::integer AS component_id
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
        WHERE p.key != 'component_id' -- Don't include the id
      ) q
    ) c
  );

  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT * FROM prd.components(component_id => ($1->>'component_id')::integer)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
