CREATE OR REPLACE FUNCTION prj.create_project (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."ownerId" AS owner_id,
      p.name,
      p.template,
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "ownerId" integer,
      "userId"  integer,
      name      text,
      template  boolean
    )
  ), job AS (
    INSERT INTO prj.job (
      job_uuid,
      name,
      created_by
    )
    SELECT
      CASE
        WHEN p.template IS TRUE THEN
          NULL
        ELSE uuid_generate_v4()
      END,
      p.name,
      p.created_by
    FROM payload p
    RETURNING job_id, name
  ), project AS (
    INSERT INTO prj.project (
      owner_id,
      job_id
    ) VALUES (
      (SELECT owner_id FROM payload),
      (SELECT job_id FROM job)
    )
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      (SELECT name FROM job)
    FROM project p
  ) r;
END
$$
LANGUAGE 'plpgsql';
