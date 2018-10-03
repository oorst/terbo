/*
List projects based on a user's relationship to the projects.

Return projects for owners and creators.
*/

CREATE OR REPLACE FUNCTION prj.list_jobs (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      j.name,
      j.short_desc AS "shortDescription",
      j.created,
      j.created_by AS "createdBy"
    FROM prj.project p
    INNER JOIN prj.job j
      ON j.dependant_id = p.job_id
    WHERE p.project_id = ($1->>'projectId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
