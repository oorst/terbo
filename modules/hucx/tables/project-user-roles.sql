CREATE TABLE hucx.proj_user_roles (
  rel_id  integer REFERENCES hucx.proj_user_rel (rel_id),
  role_id integer REFERENCES hucx.role (role_id)
)
