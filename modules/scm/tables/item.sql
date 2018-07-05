CREATE TABLE scm.item (
  item_id serial PRIMARY KEY,
  super   integer REFERENCES man.item (item_id),
  bom     integer REFERENCES man.bom (bom_id) ON DELETE RESTRICT,     -- An item can be part of a bill of materials
  route   integer REFERENCES man.route (route_id) ON DELETE RESTRICT,
  data    jsonb,
  created timestamp(0) DEFAULT current_timestamp
)
