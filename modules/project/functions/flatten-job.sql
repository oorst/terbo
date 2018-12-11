CREATE OR REPLACE FUNCTION prj.flatten_job (integer) RETURNS TABLE (
  root_id      integer,
  job_id       integer,
  job_uuid     uuid,
  dependant_id integer,
  level        integer
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE job AS (
    -- Select the top level job
    SELECT
      j.job_id,
      j.job_uuid,
      j.dependant_id,
      0 AS level
    FROM prj.job j
    WHERE j.job_id = $1

    UNION ALL

    SELECT
      j.job_id,
      j.job_uuid,
      j.dependant_id,
      job.level + 1 AS level
    FROM job
    INNER JOIN prj.job j
      ON j.dependant_id = job.job_id
  )
  SELECT
    $1 AS root_uuid,
    j.*
  FROM job j;
END
$$
LANGUAGE 'plpgsql';
