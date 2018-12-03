/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION scm.update_route_task (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format(
        'UPDATE scm.route_task SET (%s) = (%s) WHERE route_id = ''%s'' AND task_id = ''%s''',
        c.column,
        c.value,
        c.route_id,
        c.task_id
      )
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'routeId')::integer AS route_id,
        ($1->>'taskId')::integer AS task_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'sequenceNumber' THEN 'seq_num'
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
        WHERE p.key != 'routeId' AND p.key != 'taskId'
      ) q
    ) c
  );

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
