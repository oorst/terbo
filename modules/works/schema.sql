CREATE SCHEMA works
  CREATE TABLE work_order (
    work_order_id serial PRIMARY KEY,
    prototype_id  integer REFERENCES work_order (work_order_id),
    job_id        integer REFERENCES prj.job (job_id),
    instructions  text
  )
