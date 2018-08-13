CREATE OR REPLACE FUNCTION prj.get_jobs_level (json, OUT result json) AS
$$
BEGIN
  IF $1->>'jobId' IS NULL THEN
    RAISE EXCEPTION 'must provide projectId';
  END IF;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      j.job_id,
      j.name
    FROM prj.job j
    WHERE j.prerequisite_id = ($1->>'jobId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
