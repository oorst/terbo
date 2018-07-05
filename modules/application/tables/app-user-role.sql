/**
Status bitmask
1 = active
2 = revoked
4 = reinstated
*/

CREATE TABLE application.app_user_role (
  app_user_role_id serial PRIMARY KEY,
  user_id integer REFERENCES application.user (user_id) ON DELETE CASCADE,
  role_id integer REFERENCES application.role (role_id) ON DELETE CASCADE,
  status  integer DEFAULT 1, -- bit mask
  created timestamp DEFAULT CURRENT_TIMESTAMP
)
