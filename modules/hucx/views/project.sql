CREATE VIEW hucx.project_v AS
  SELECT
    hucx_project_id,
    project_id,
    proj.address_id AS address_id,
    proj.owner_id AS owner_id,
    hucx_proj.data AS data,
    hucx_proj.root_folder AS root_folder_id,
    hucx_proj.created_by AS created_by,
    proj.created AS created
  FROM hucx.project hucx_proj
  INNER JOIN prj.project proj USING (project_id);
