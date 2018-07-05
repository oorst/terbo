CREATE TABLE hucx.setting (
  setting_id serial PRIMARY KEY,
  data       jsonb,
  created    timestamp(0) DEFAULT CURRENT_TIMESTAMP,
  modified   timestamp(0) DEFAULT CURRENT_TIMESTAMP
)
