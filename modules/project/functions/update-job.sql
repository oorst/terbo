/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION prj.update_job (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prj.job SET (%s) = (%s) WHERE job_id = ''%s''', c.column, c.value, c.job_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'jobId')::integer AS job_id
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
        WHERE p.key != 'jobId' AND p.key != 'userId'
      ) q
    ) c
  );

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
