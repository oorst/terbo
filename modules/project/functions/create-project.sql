CREATE OR REPLACE FUNCTION prj.create_project (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p.owner_uuid,
      p.name,
      p.template,
      p.user_uuid AS created_by
    FROM json_to_record($1) AS p (
      owner_uuid uuid,
      user_uuid  uuid,
      name       text,
      template   boolean
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
    RETURNING job_uuid, name
  ), project AS (
    INSERT INTO prj.project (
      owner_uuid,
      job_uuid
    ) VALUES (
      (SELECT owner_uuid FROM payload),
      (SELECT job_uuid FROM job)
    )
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      p.project_uuid,
      (SELECT name FROM job)
    FROM project p
  ) r;
END
$$
LANGUAGE 'plpgsql';
