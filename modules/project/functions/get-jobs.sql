CREATE OR REPLACE FUNCTION prj.get_jobs (json, OUT result json) AS
$$
BEGIN
  IF $1->>'projectId' IS NULL THEN
    RAISE EXCEPTION 'must provide projectId';
  END IF;

  WITH RECURSIVE job AS (
    SELECT
      j.job_id,
      j.name
    FROM prj.project p
    INNER JOIN prj.job j
      ON j.prerequisite_id = p.job_id
    WHERE p.project_id = ($1->>'projectId')::integer

    UNION ALL

    SELECT
      j.job_id,
      j.name
    FROM job
    INNER JOIN prj.job j
      ON j.prerequisite_id = job.job_id
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId",
      j.name
    FROM job j
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prj.get_jobs (integer)
RETURNS TABLE (
  job_id integer
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE job AS (
    SELECT
      j.job_id
    FROM prj.job j
    WHERE j.job_id = $1

    UNION ALL

    SELECT
      j.job_id
    FROM job
    INNER JOIN prj.job j
      ON j.prerequisite_id = job.job_id
  )
  SELECT * FROM job;
END
$$
LANGUAGE 'plpgsql';
