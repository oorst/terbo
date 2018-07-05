CREATE TABLE access_control.identity (
  identity_id SERIAL PRIMARY KEY,
  type        integer,
  id          integer,
  created     timestamp DEFAULT CURRENT_TIMESTAMP
)
