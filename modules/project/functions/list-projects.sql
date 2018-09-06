/*
List projects based on a user's relationship to the projects.

Return projects for owners and creators.
*/

CREATE OR REPLACE FUNCTION prj.list_projects (json, OUT result json) AS
$$
DECLARE
  _user_id integer := ($1->>'userId')::integer;
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      p.nickname,
      j.name,
      j.short_desc AS "shortDescription",
      j.created,
      j.created_by AS "createdBy"
    FROM prj.project p
    INNER JOIN prj.job j
      USING (job_id)
    WHERE p.owner_id = _user_id OR p.created_by = _user_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
