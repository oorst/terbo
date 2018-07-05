CREATE TABLE folder.node (
  node_id    serial PRIMARY KEY,
  parent     integer REFERENCES folder.node(node_id) ON DELETE CASCADE,
  data       jsonb,
  access     integer DEFAULT 0,
  created_by integer REFERENCES person(person_id),
  created    timestamp(0) DEFAULT LOCALTIMESTAMP,
  modified   timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
