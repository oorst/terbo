CREATE TABLE hucx.app_user_role (
  user_id    integer REFERENCES application.user (user_id),
  role_id    integer REFERENCES hucx.role (role_id)
)
