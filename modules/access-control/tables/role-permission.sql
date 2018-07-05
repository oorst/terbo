CREATE TABLE access_control.role_permission (
  role_id       integer REFERENCES access_control.role (role_id),
  permission_id integer REFERENCES access_control.permission (permission_id),
  created_by    integer REFERENCES access_control.identity (identity_id)
);
