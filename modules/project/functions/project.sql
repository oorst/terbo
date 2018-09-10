CREATE OR REPLACE FUNCTION prj.project (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      p.job_id AS "jobId",
      p.owner_id AS "ownerId",
      owner.name AS "ownerName",
      p.nickname,
      j.dependant_id AS "dependantId",
      j.name,
      j.short_desc AS "shortDescription",
      j.description AS "description",
      j.created_by AS "createdBy",
      j.created
    FROM prj.project p
    INNER JOIN prj.job j
      USING (job_id)
    LEFT JOIN party_v owner
      ON owner.party_id = p.owner_id
    WHERE p.project_id = ($1->>'projectId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
