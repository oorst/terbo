CREATE OR REPLACE FUNCTION hucx._get_project (
  _project_id integer,
  _user_id integer,
  OUT result json
) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      hucx_project_id AS "projectId",
      _get_address_full(address_id) AS "address",
      _get_party(owner_id) AS "owner",
      data,
      array(
        SELECT role.name
        FROM hucx.proj_user_role hpr
        INNER JOIN hucx.role role USING (role_id)
        WHERE hpr.hucx_project_id = _project_id
          AND hpr.user_id = _user_id
      ) AS roles,
      created_by AS "createdBy",
      created
    FROM hucx.project_v
  ) r;
END
$$
LANGUAGE 'plpgsql';
