-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Insert SCM related settings
INSERT INTO core.settings VALUES ('rgx.uuid', '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$');

CREATE SCHEMA scm;

CREATE TYPE scm.item_kind_t AS ENUM ('ITEM', 'ASSEMBLY', 'PART', 'PRODUCT');
CREATE TYPE scm.task_concurrency_t AS ENUM ('SAME', 'ALL');
CREATE TYPE scm.item_t AS (
  item_uuid          uuid,
  product_uuid       uuid,
  kind               scm.item_kind_t,
  name               text,
  short_desc         text,
  data               jsonb,
  product_name       text,
  product_short_desc text,
  product_code       text,
  sku                text,
  route_uuid         uuid,
  weight             numeric(10,3),
  created            timestamptz,
  end_at             timestamptz,
  modified           timestamptz
);

CREATE TABLE scm.route (
  route_uuid   uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name         text,
  short_desc   text,
  data         jsonb,
  created_by   uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
  modified     timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.item (
  item_uuid      uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_uuid   uuid REFERENCES prd.product (product_uuid) ON DELETE RESTRICT,
  kind           scm.item_kind_t,
  name           text,
  short_desc     text,
  data           jsonb,
  route_uuid     uuid REFERENCES scm.route (route_uuid) ON DELETE SET NULL,
  weight         numeric(10,3),
  created        timestamptz DEFAULT CURRENT_TIMESTAMP,
  end_at         timestamptz,
  modified       timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.attribute (
  attribute_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  item_uuid      uuid REFERENCES scm.item (item_uuid) ON DELETE CASCADE,
  name           text,
  value          text,
  created        timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified       timestamptz
);

CREATE TABLE scm.part (
  part_uuid   uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  root_uuid   uuid REFERENCES scm.item (item_uuid) ON DELETE CASCADE,
  parent_uuid uuid REFERENCES scm.item (item_uuid) ON DELETE CASCADE,
  item_uuid   uuid REFERENCES scm.item (item_uuid) ON DELETE RESTRICT -- Can't delete an Item if it's part of another Item
);

CREATE TABLE scm.work_center (
  work_center_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name             text
);

CREATE TABLE scm.bom (
  bom_uuid   uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  created    timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.bom_line (
  bom_uuid     uuid REFERENCES scm.bom (bom_uuid) ON DELETE CASCADE,
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE SET NULL,
  quantity     numeric(10,2),
  modified     timestamptz DEFAULT CURRENT_TIMESTAMP,
  created      timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.boq (
  boq_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  created  timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.boq_line (
  boq_uuid     uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE SET NULL,
  quantity     numeric(10,2),
  modified     timestamptz DEFAULT CURRENT_TIMESTAMP,
  created      timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.task (
  task_uuid        uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  product_uuid     uuid REFERENCES prd.product (product_uuid) ON DELETE SET NULL,
  name             text,
  description      text,
  data             jsonb,
  boq_uuid         uuid REFERENCES scm.boq (boq_uuid) ON DELETE SET NULL,
  work_center_uuid uuid REFERENCES scm.work_center (work_center_uuid) ON DELETE SET NULL,
  finished_at      timestamptz,
  created          timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified         timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scm.task_item (
  task_uuid      uuid REFERENCES scm.task (task_uuid) ON DELETE CASCADE,
  item_uuid      uuid REFERENCES scm.item (item_uuid) ON DELETE CASCADE,
  batch_uuid     uuid,
  batch_priority integer,
  -- Sorting number is an arbitrary number for sorting tasks within a batch
  -- or other grouping
  sorting_num    integer,
  finished_at    timestamp,
  queue_number   serial,
  PRIMARY KEY (task_uuid, item_uuid)
);

CREATE TABLE scm.route_task (
  route_uuid uuid REFERENCES scm.route (route_uuid) ON DELETE CASCADE,
  task_uuid  uuid REFERENCES scm.task (task_uuid) ON DELETE CASCADE,
  seq_num    integer,
  PRIMARY KEY (route_uuid, task_uuid)
);

  -- CREATE TABLE delivery (
  --   delivery_id     serial PRIMARY KEY,
  --   address_id      integer REFERENCES full_address (address_id) ON DELETE SET NULL,
  --   dispatch        timestamp,
  --   actual_dispatch timestamp
  --   created         timestamp DEFAULT CURRENT_TIMESTAMP
  -- )

CREATE OR REPLACE VIEW scm.task_queue_v AS
  SELECT
    ti.task_uuid,
    ti.item_uuid,
    ti.queue_number,
    ti.finished_at,
    ti.batch_uuid,
    ti.batch_priority,
    ti.sorting_num,
    t.work_center_uuid,
    r.route_uuid,
    rt.seq_num
  FROM scm.task_item ti
  INNER JOIN scm.task t
    USING (task_uuid)
  INNER JOIN scm.item i
    USING (item_uuid)
  INNER JOIN scm.route r
    ON r.route_uuid = i.route_uuid
  INNER JOIN scm.route_task rt
    ON rt.route_uuid = r.route_uuid AND rt.task_uuid = ti.task_uuid;

CREATE OR REPLACE VIEW scm.item_list_v AS
  SELECT
    i.item_uuid,
    i.product_uuid,
    p.code,
    COALESCE(i.name, p.name) AS name,
    COALESCE(i.short_desc, p.short_desc) AS short_desc,
    i.created,
    i.modified
  FROM scm.item i
  LEFT JOIN prd.product_list_v p
    USING (product_uuid)
  WHERE i.end_at IS NULL OR i.end_at > CURRENT_TIMESTAMP;
