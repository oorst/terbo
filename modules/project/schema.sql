CREATE SCHEMA prj
  CREATE TABLE job (
    job_id          serial PRIMARY KEY,
    prototype_id    integer REFERENCES job (job_id) ON DELETE RESTRICT,
    dependant_id    integer REFERENCES job (job_id) ON DELETE CASCADE,
    name            text,
    short_desc      text,
    description      text,
    lag             interval,
    lead            interval,
    created_by      integer REFERENCES person (party_id) ON DELETE SET NULL,
    created         timestamp DEFAULT CURRENT_TIMESTAMP,
    modified        timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE project (
    project_id  serial PRIMARY KEY,
    job_id      integer REFERENCES job (job_id) ON DELETE CASCADE,
    address_id  integer REFERENCES full_address (address_id) ON DELETE SET NULL,
    owner_id    integer REFERENCES party (party_id) ON DELETE SET NULL,
    nickname    text
  )

  CREATE TABLE project_job (
    project_id integer REFERENCES project (project_id),
    job_id     integer REFERENCES job (job_id),
    PRIMARY KEY (project_id)
  )

  CREATE TABLE project_role (
    project_id integer REFERENCES project (project_id),
    party_id   integer REFERENCES person (party_id)
  )

  CREATE TABLE boq_line_item (
    boq_line_item_id serial PRIMARY KEY,
    job_id           integer REFERENCES job (job_id) ON DELETE CASCADE,
    product_id       integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
    uom_id           integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity         numeric(10,3),
    created_by       integer REFERENCES person (party_id) ON DELETE SET NULL,
    created          timestamp DEFAULT CURRENT_TIMESTAMP,
    modified         timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE deliverable (
    deliverable_id serial PRIMARY KEY,
    project_id     integer REFERENCES project (project_id) ON DELETE CASCADE,
    name           text,
    dependency     integer REFERENCES deliverable (deliverable_id),
    lag            interval,
    lead           interval,
    data           jsonb,
    created        timestamp DEFAULT CURRENT_TIMESTAMP
  );
