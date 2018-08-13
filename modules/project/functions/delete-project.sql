CREATE OR REPLACE FUNCTION prj.delete_project (json, OUT result json) AS
$$
BEGIN
  IF $1->>'projectId' IS NULL THEN
    RAISE EXCEPTION 'must provide a projectId';
  END IF;

  WITH project AS (
    SELECT
      *
    FROM prj.project
    WHERE project_id = ($1->>'projectId')::integer
  ), job AS (
    SELECT
      *
    FROM prj.get_jobs((SELECT job_id FROM project))
  )
  DELETE FROM prj.job j
  USING job
  WHERE j.job_id = job.job_id;

  SELECT '{ "ok": true }' INTO result;
END
$$
LANGUAGE 'plpgsql';
