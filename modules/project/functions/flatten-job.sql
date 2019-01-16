DROP FUNCTION prj.flatten_job(integer, integer);
CREATE OR REPLACE FUNCTION prj.flatten_job (
  _job_id      integer,
  _depth       integer DEFAULT NULL
) RETURNS TABLE (
  root_id      integer,
  job_id       integer,
  job_uuid     uuid,
  dependant_id integer,
  level        integer,
  path         integer[]
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
      0 AS level,
      '{}'::integer[] AS path
    FROM prj.job j
    WHERE j.job_id = _job_id

    UNION ALL

    SELECT
      j.job_id,
      j.job_uuid,
      j.dependant_id,
      job.level + 1 AS level,
      job.path || job.job_id
    FROM job
    INNER JOIN prj.job j
      ON j.dependant_id = job.job_id
    WHERE _depth IS NULL OR job.level < _depth
  )
  SELECT
    $1 AS root_id,
    j.*
  FROM job j;
END
$$
LANGUAGE 'plpgsql';
