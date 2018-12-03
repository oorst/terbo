CREATE OR REPLACE FUNCTION prj.job (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId",
      j.name,
      j.short_desc AS "shortDescription"
    FROM prj.job j
    WHERE j.job_id = ($1->>'jobId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
