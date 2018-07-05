CREATE TABLE hucx.project (
  hucx_project_id serial PRIMARY KEY,
  project_id      integer REFERENCES prj.project (project_id),
  data            jsonb,
  root_folder     integer REFERENCES folder.node (node_id),
  created_by      integer REFERENCES person (person_id)
)
