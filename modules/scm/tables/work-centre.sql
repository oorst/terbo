CREATE TABLE scm.work_cntr (
  work_cntr_id serial PRIMARY KEY,
  name         text,
  uom_1        integer REFERENCES scm.uom (uom_id),
  uom_2        integer REFERENCES scm.uom (uom_id)
)
