CREATE OR REPLACE FUNCTION prj.create_job (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."userId" AS created_by,
      j."jobId" AS job_id,
      j.name
    FROM json_to_record($1) AS j (
      "userId"    integer,
      "jobId"     integer,
      name        text
    )
  ), job AS (
    INSERT INTO prj.job (
      dependant_id,
      name,
      created_by
    )
    SELECT
      p.job_id,
      p.name,
      p.created_by
    FROM payload p
    RETURNING job_id
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      j.job_id AS "jobId"
    FROM job j
  ) r;
END
$$
LANGUAGE 'plpgsql';
