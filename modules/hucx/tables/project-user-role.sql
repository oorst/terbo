CREATE TABLE hucx.proj_user_role (
  proj_user_role_id serial PRIMARY KEY,
  hucx_project_id   integer REFERENCES hucx.project (hucx_project_id) ON DELETE CASCADE,
  user_id           integer REFERENCES application.user (user_id) ON DELETE CASCADE,
  role_id           integer REFERENCES hucx.role (role_id) ON DELETE CASCADE
)
