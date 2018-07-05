CREATE TABLE hucx.proj_user_rel (
  rel_id     serial PRIMARY KEY,
  project_id integer REFERENCES hucx.project (project_id),
  user_id    integer REFERENCES application.user (user_id),
  role_id    integer REFERENCES hucx.role (role_id)
)
