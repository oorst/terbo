CREATE OR REPLACE FUNCTION hucx.get_projects (json, OUT result json) AS
$$
BEGIN
  -- Check for userId
  IF $1->>'userId' IS NULL THEN
    RAISE EXCEPTION 'userId is required';
  END IF;

  WITH projects AS (
    SELECT DISTINCT ON (proj.hucx_project_id) proj.*
    FROM hucx.proj_user_role pur
    INNER JOIN hucx.project_v proj
      USING(hucx_project_id)
    WHERE pur.user_id = ($1->>'userId')::integer
  )
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      hucx_project_id AS "projectId",
      _get_address_full(address_id) AS "address",
      _get_party(owner_id) AS "owner",
      data,
      root_folder_id AS "rootFolderNodeId",
      array(
        SELECT role.name
        FROM hucx.proj_user_role pur
        INNER JOIN hucx.role role USING (role_id)
        WHERE pur.hucx_project_id = projects.hucx_project_id
          AND pur.user_id = ($1->>'userId')::integer
      ) AS roles,
      created_by AS "createdBy",
      created
    FROM projects
  ) r;

  SELECT json_strip_nulls(result) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
