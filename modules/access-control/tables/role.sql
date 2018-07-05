CREATE TABLE access_control.role (
  role_id    SERIAL PRIMARY KEY,
  name       text,
  created_by integer REFERENCES access_control.identity (identity_id),
  created    timestamp(0) DEFAULT CURRENT_TIMESTAMP
)
