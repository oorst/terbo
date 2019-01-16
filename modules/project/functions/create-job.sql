CREATE OR REPLACE FUNCTION prj.create_job (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."userId" AS created_by,
      p."jobId" AS job_id,
      p.name,
      p."jobUuid" AS job_uuid
    FROM json_to_record($1) AS p (
      "userId"    integer,
      "jobId"     integer,
      name        text,
      "jobUuid"   uuid
    )
  ), job AS (
    INSERT INTO prj.job (
      job_uuid,
      dependant_id,
      name,
      created_by
    )
    SELECT
      coalesce(p.job_uuid, uuid_generate_v4()),
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
