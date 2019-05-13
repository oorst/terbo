CREATE SCHEMA prj;

CREATE TYPE prj.job_status_t AS ENUM ('WIP', 'COMPLETE');

CREATE TABLE prj.state (
  state_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name       text
);

CREATE TABLE prj.job (
  job_uuid        uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  dependant_uuid  uuid REFERENCES prj.job (job_uuid) ON DELETE CASCADE,
  state           uuid REFERENCES prj.state (state_uuid) ON DELETE RESTRICT,
  name            text,
  short_desc      text,
  description     text,
  seq_num         integer,
  duration        interval,
  lag             interval,
  lead            interval,
  created_by      uuid REFERENCES core.person (party_uuid) ON DELETE SET NULL,
  created         timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified        timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE prj.project (
  project_uuid uuid REFERENCES prj.job (job_uuid) ON DELETE CASCADE,
  address_uuid uuid REFERENCES core.full_address (address_uuid) ON DELETE CASCADE,
  owner_uuid   uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
  nickname     text,
  PRIMARY KEY (project_uuid)
);

CREATE TABLE prj.job_invoice (
  job_uuid     uuid REFERENCES prj.job (job_uuid) ON DELETE RESTRICT,
  invoice_uuid uuid REFERENCES sales.invoice (invoice_uuid) ON DELETE RESTRICT,
  PRIMARY KEY (job_uuid, invoice_uuid)
);

-- CREATE TABLE project_order (
--   project_id integer REFERENCES project (project_id),
--   order_id   integer REFERENCES sales.order (order_id),
--   PRIMARY KEY (project_id, order_id)
-- );

  -- CREATE TABLE project_role (
  --   project_id integer REFERENCES project (project_id),
  --   party_id   integer REFERENCES person (party_id)
  -- )

  -- CREATE TABLE boq_line_item (
  --   boq_line_item_id serial PRIMARY KEY,
  --   job_id           integer REFERENCES job (job_id) ON DELETE CASCADE,
  --   product_id       integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
  --   uom_id           integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
  --   quantity         numeric(10,3),
  --   created_by       integer REFERENCES person (party_id) ON DELETE SET NULL,
  --   created          timestamp DEFAULT CURRENT_TIMESTAMP,
  --   modified         timestamp DEFAULT CURRENT_TIMESTAMP
  -- )

CREATE TABLE prj.deliverable (
  deliverable_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  job_uuid         uuid REFERENCES prj.job (job_uuid) ON DELETE CASCADE,
  seq_num          integer,
  data             jsonb,
  created          timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Create default states
INSERT INTO prj.state ( name ) VALUES
  ('unstarted'),
  ('inprogress'),
  ('finished');
