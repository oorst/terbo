/*
List projects based on a user's relationship to the projects.

Return projects for owners and creators.
*/

CREATE OR REPLACE FUNCTION prj.list_projects (json, OUT result json) AS
$$
DECLARE
  userId integer;
BEGIN
  userId = ($1->>'userId');

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      p.name,
      p.description,
      p.created
    FROM massey.project p
    WHERE p.owner_id = userId OR p.created_by = userId
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
