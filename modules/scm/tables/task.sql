CREATE TABLE scm.task (
  task_id    serial PRIMARY KEY,
  name       text,
  work_cntr  integer REFERENCES scm.work_cntr (work_cntr_id)
);

CREATE TABLE scm.task_product (
  task_prd_id serial PRIMARY KEY,
  task_id     integer REFERENCES scm.task (task_id),
  product_id  integer REFERENCES prd.product (product_id) -- Link task to a chargeable product
);

CREATE TABLE scm.route_task (
  route_task_id serial PRIMARY KEY,
  route_id      integer REFERENCES scm.route (route_id) ON DELETE RESTRICT,
  task_id       integer REFERENCES scm.task (task_id) ON DELETE CASCADE,
  seq_num       integer
);

-- Instance of a task
CREATE TABLE scm.task_inst (
  task_inst_id serial PRIMARY KEY,
  task_id      integer REFERENCES scm.task (task_id), -- The task
  item_id      integer REFERENCES scm.item (item_id), -- Item to which this task is applied
  duration     integer,                               -- Task duration
  data         jsonb,                                 -- Task data
  status       smallint                               -- Status (bit mask)
);
