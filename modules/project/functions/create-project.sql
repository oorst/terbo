CREATE OR REPLACE FUNCTION prj.create_project (json, OUT result json) AS
$$
BEGIN
  IF $1->>'userId' IS NULL THEN
    RAISE EXCEPTION 'must provide a userId';
  END IF;

  WITH payload AS (
    SELECT
      j."userId" AS party_id
    FROM json_to_record($1) AS j (
      "userId" integer
    )
  ), job AS (
    INSERT INTO prj.job (
      created_by
    )
    SELECT
      p.party_id
    FROM payload p
    RETURNING *
  ), project AS (
    INSERT INTO prj.project (
      job_id,
      created_by
    ) VALUES (
      (SELECT job_id FROM job),
      (SELECT party_id FROM payload)
    )
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
