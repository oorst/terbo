/*
List projects based on a user's relationship to the projects.

Return projects for owners and creators.
*/

CREATE OR REPLACE FUNCTION prj.list_projects (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.project_uuid,
      j.name,
      j.short_desc,
      j.created
    FROM prj.project p
    INNER JOIN prj.job j
      ON j.job_uuid = p.project_uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
