CREATE TABLE access_control.resource_permission (
  resource_id   integer REFERENCES access_control.resource (resource_id),
  permission_id integer REFERENCES access_control.permission (permission_id),
  created_by    integer REFERENCES access_control.identity (identity_id)
);
