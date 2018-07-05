CREATE TABLE hucx.element (
  element_id      serial PRIMARY KEY,
  hucx_project_id integer REFERENCES hucx.project (hucx_project_id) ON DELETE CASCADE,
  data            jsonb,
  item_id         integer REFERENCES scm.item (item_id),
  created         timestamp(0) DEFAULT CURRENT_TIMESTAMP,
  modified        timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
