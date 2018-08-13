CREATE OR REPLACE FUNCTION prj.get_project (json, OUT result json) AS
$$
BEGIN
  IF $1->>'projectId' IS NULL THEN
    RAISE EXCEPTION 'must provide projectId';
  END IF;

  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      p.job_id AS "jobId",
      p.name,
      p.nickname,
      p.created_by AS "createdBy"
    FROM prj.project p
    WHERE p.project_id = ($1->>'projectId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
