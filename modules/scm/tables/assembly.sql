CREATE TABLE scm.assembly (
  assm_id serial PRIMARY KEY,
  parent  integer REFERENCES man.assembly (assm_id),
  bom     integer REFERENCES man.bom (bom_id) ON DELETE RESTRICT,
  route   integer REFERENCES man.route (route_id) ON DELETE RESTRICT,
  data    jsonb,
  created timestamp(0) DEFAULT current_timestamp
)
