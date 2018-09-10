CREATE OR REPLACE FUNCTION prj.create_project (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "userId" integer
    )
  ), job AS (
    INSERT INTO prj.job (
      created_by
    )
    SELECT
      p.created_by
    FROM payload p
    RETURNING job_id
  ), project AS (
    INSERT INTO prj.project (
      job_id
    )
    SELECT
      job.job_id
    FROM job
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId"
    FROM project p
  ) r;
END
$$
LANGUAGE 'plpgsql';
