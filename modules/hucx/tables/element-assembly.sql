CREATE TABLE hucx.el_assm (
  el_assm_id serial PRIMARY KEY,
  element_id integer REFERENCES hucx.element (element_id),
  item_id    integer REFERENCES scm.item (item_id),        -- SCM item is the assembly
  created    timestamp(0) DEFAULT current_timestamp
)
