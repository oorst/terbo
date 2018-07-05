CREATE OR REPLACE FUNCTION hucx.create_project(json, OUT result json) RETURNS json AS
$$
BEGIN
  IF $1->>'userId' IS NULL THEN
    RAISE EXCEPTION 'userId is required';
  END IF;

  -- Create a root folder
  WITH root_folder AS (
    INSERT INTO folder.node DEFAULT VALUES
    RETURNING node_id
  ),
  -- Create the project record
  hucx_project AS (
    INSERT INTO hucx.project (
      created_by,
      data,
      root_folder,
      project_id -- prj.project_id
    ) VALUES (
      ($1->>'userId')::integer,
      ($1->'data')::jsonb,
      (SELECT node_id FROM root_folder),
      prj._create_project($1)
    )
    RETURNING hucx_project_id, project_id
  ),
  -- If the creator is a staff member, then add them as a Project Manager
  project_user_role AS (
    INSERT INTO hucx.proj_user_role (
      hucx_project_id,
      user_id,
      role_id
    ) VALUES (
      (SELECT hucx_project_id FROM hucx_project),
      ($1->>'userId')::integer,
      CASE
        WHEN
          (
            SELECT 'staff' = any(roles::text[])
            FROM hucx.user_v
            WHERE user_id = ($1->>'userId')::integer
          )
        THEN
          (
            SELECT role_id
            FROM hucx.role
            WHERE name = 'project manager'
          )
        ELSE NULL
      END
    )
  )
  SELECT hucx._get_project(hucx_project_id, ($1->>'userId')::integer) INTO result
  FROM hucx_project;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
