CREATE OR REPLACE FUNCTION prj.get_projects (json, OUT result json) AS
$$
DECLARE
  _user_id integer;
BEGIN
  IF $1->>'userId' IS NULL THEN
    RAISE EXCEPTION 'must provide userId';
  END IF;

  _user_id = ($1->>'userId')::integer;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.project_id AS "projectId",
      p.name,
      p.nickname
    FROM prj.project p
    LEFT JOIN prj.project_role r
      USING (project_id)
    WHERE r.party_id = _user_id OR p.created_by = _user_id
  ) r;
END
$$
LANGUAGE 'plpgsql';
