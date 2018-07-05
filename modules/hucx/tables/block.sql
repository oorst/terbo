CREATE TABLE hucx.block (
  block_id   serial PRIMARY KEY,
  element_id integer REFERENCES hucx.element(element_id) ON DELETE CASCADE,
  data       jsonb,
  created    timestamp(0) DEFAULT CURRENT_TIMESTAMP,
  modified   timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
