-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Insert SCM related settings
INSERT INTO core_settings VALUES ('rgx.uuid', '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$');

-- Create types
CREATE TYPE scm_item_t AS ENUM ('ITEM', 'SUBASSEMBLY', 'PART', 'PRODUCT');
CREATE TYPE scm_task_concurrency_t AS ENUM ('SAME', 'ALL');

CREATE SCHEMA scm
  CREATE TABLE route (
    route_id   serial PRIMARY KEY,
    product_id integer REFERENCES prd.product (product_id) ON DELETE CASCADE,
    name       text,
    created_by integer REFERENCES party (party_id) ON DELETE SET NULL,
    modified   timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE external_route (
    route_id  integer REFERENCES route (route_id) PRIMARY KEY,
    -- Party to which an Item is sent for processing
    consignee integer REFERENCES party (party_id) ON DELETE SET NULL,
    location  integer REFERENCES address (address_id) ON DELETE SET NULL
  )

  -- Item uses a UUID primary key so that functions can be used across the Item
  -- table and the item instance table
  CREATE TABLE item (
    item_uuid      uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    prototype_uuid uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    product_id     integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    type           scm_item_t,
    name           text,
    short_desc     text,
    description    text,
    data           jsonb,
    attributes     jsonb,
    route_id       integer REFERENCES route (route_id) ON DELETE SET NULL,
    -- A set price takes precedence over a calculated price
    gross          numeric(10,2),
    net            numeric(10,2),
    weight         numeric(10,3),
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at         timestamp,
    modified       timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE attribute (
    attribute_id serial PRIMARY KEY,
    item_uuid    uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    name         text,
    value        text,
    created      timestamp DEFAULT CURRENT_TIMESTAMP,
    modified     timestamp
  )

  CREATE TABLE component (
    component_id   serial PRIMARY KEY,
    root_uuid      uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    parent_uuid    uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    item_uuid      uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    product_id     integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    uom_id         integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity       numeric(10,3),
    type           scm_item_t,
    end_at         timestamp
  )

  /*
  Link an Item to a Sales Order Line Item
  */
  CREATE TABLE line_item (
    item_uuid    uuid REFERENCES item (item_uuid) ON DELETE SET NULL,
    line_item_id integer REFERENCES sales.line_item (line_item_id) ON DELETE CASCADE,
    quantity     numeric(10,3),
    prototype    boolean DEFAULT TRUE,
    created      timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by   integer REFERENCES party (party_id),
    PRIMARY KEY (item_uuid, line_item_id)
  )

  CREATE TABLE item_instance (
    item_instance_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    item_uuid          uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    data               jsonb,
    created            timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE item_instance_subassembly (
    hierarchy_id  serial PRIMARY KEY,
    item_uuid     uuid REFERENCES item_instance (item_instance_uuid) ON DELETE CASCADE,
    root_uuid     uuid REFERENCES item_instance (item_instance_uuid) ON DELETE CASCADE,
    parent_uuid   uuid REFERENCES item_instance (item_instance_uuid) ON DELETE CASCADE,
    quantity      numeric(10,3)
  )

  CREATE TABLE item_route (
    item_uuid uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    route_id  integer REFERENCES route (route_id) ON DELETE CASCADE,
    seq_num   integer,
    PRIMARY KEY (item_uuid, route_id)
  )

  CREATE TABLE work_center (
    work_center_id serial PRIMARY KEY,
    name           text
  )

  CREATE TABLE bom (
    bom_id     serial PRIMARY KEY,
    created    timestamp(0) DEFAULT current_timestamp
  )

  CREATE TABLE bom_line (
    bom_id     integer REFERENCES bom (bom_id) ON DELETE CASCADE,
    product_id integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
    quantity   numeric(10,2),
    uom_id     integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    modified   timestamp DEFAULT current_timestamp,
    created    timestamp DEFAULT current_timestamp
  )

  CREATE TABLE boq (
    boq_id serial PRIMARY KEY,
    created    timestamp(0) DEFAULT current_timestamp
  )

  CREATE TABLE boq_line (
    boq_id     integer REFERENCES boq (boq_id) ON DELETE CASCADE,
    product_id integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
    quantity   numeric(10,2),
    uom_id     integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    modified   timestamp DEFAULT current_timestamp,
    created    timestamp DEFAULT current_timestamp
  )

  CREATE TABLE task (
    task_id        serial PRIMARY KEY,
    product_id     integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
    name           text,
    description    text,
    data           jsonb,
    boq_id         integer REFERENCES boq (boq_id) ON DELETE SET NULL,
    work_center_id integer REFERENCES work_center (work_center_id) ON DELETE SET NULL,
    finished_at    timestamp,
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    modified       timestamp DEFAULT current_timestamp
  )

  CREATE TABLE task_item (
    task_id        integer REFERENCES task (task_id) ON DELETE RESTRICT,
    item_uuid      uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    batch_uuid     uuid,
    batch_priority integer,
    -- Sorting number is an arbitrary number for sorting tasks within a batch
    -- or other grouping
    sorting_num    integer,
    finished_at    timestamp,
    queue_number   serial,
    PRIMARY KEY (task_id, item_uuid)
  )

  CREATE TABLE route_task (
    route_id      integer REFERENCES route (route_id) ON DELETE CASCADE,
    task_id       integer REFERENCES task (task_id) ON DELETE CASCADE,
    seq_num       integer,
    PRIMARY KEY (route_id, task_id)
  )

  CREATE TABLE delivery (
    delivery_id     serial PRIMARY KEY,
    address_id      integer REFERENCES full_address (address_id) ON DELETE SET NULL,
    dispatch        timestamp,
    actual_dispatch timestamp
    created         timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE OR REPLACE VIEW task_queue_v AS
    SELECT
      ti.task_id,
      ti.item_uuid,
      ti.queue_number,
      ti.finished_at,
      ti.batch_uuid,
      ti.batch_priority,
      ti.sorting_num,
      t.work_center_id,
      r.route_id,
      rt.seq_num
    FROM task_item ti
    INNER JOIN task t
      USING (task_id)
    INNER JOIN item i
      USING (item_uuid)
    INNER JOIN route r
      ON r.product_id = i.product_id
    INNER JOIN route_task rt
      ON rt.route_id = r.route_id AND rt.task_id = ti.task_id

  CREATE OR REPLACE VIEW item_list_v AS
    SELECT
      i.item_uuid,
      i.prototype_uuid,
      coalesce(i.product_id, proto.product_id) AS product_id,
      p.code,
      COALESCE(i.name, proto.name, p.name) AS name,
      COALESCE(i.short_desc, proto.short_desc, p.short_desc) AS short_desc,
      i.created,
      i.modified
    FROM item i
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN item proto
      ON proto.item_uuid = i.prototype_uuid
    LEFT JOIN prd.product_list_v pp
      ON pp.product_id = proto.product_id
    WHERE i.end_at IS NULL OR i.end_at > CURRENT_TIMESTAMP;

  --
  -- Triggers
  --
CREATE TRIGGER scm_delete_component_tg AFTER DELETE ON scm.component
  FOR EACH ROW EXECUTE PROCEDURE scm.delete_component_tg();
