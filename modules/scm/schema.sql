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
    parent_uuid    uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    item_uuid      uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    product_id     integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    uom_id         integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity       numeric(10,3),
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
    product_id     integer REFERENCES prd.product (product_id) ON DELETE CASCADE,
    name           text,
    description    text,
    concurrency    scm_task_concurrency_t DEFAULT 'SAME',
    data           jsonb,
    boq_id         integer REFERENCES boq (boq_id) ON DELETE SET NULL,
    work_center_id integer REFERENCES work_center (work_center_id) ON DELETE SET NULL,
    modified       timestamp DEFAULT current_timestamp
  )

  CREATE TABLE route_task (
    route_id      integer REFERENCES route (route_id) ON DELETE CASCADE,
    task_id       integer REFERENCES task (task_id) ON DELETE CASCADE,
    seq_num       integer,
    PRIMARY KEY (route_id, task_id)
  )

  /**
  Task instances are used for items that are parametric in nature.

  ### Triggers
  - task_instance_tg: On insert, a new boq is also inserted with
  task_instance.boqId = boq.boqId
  */
  CREATE TABLE task_instance (
    task_inst_id serial PRIMARY KEY,
    task_id      integer REFERENCES task (task_id) ON DELETE RESTRICT,
    item_uuid    uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    quantity     numeric(10,2),
    bom_id       integer REFERENCES bom (bom_id) ON DELETE RESTRICT,
    boq_id       integer REFERENCES boq (boq_id) ON DELETE RESTRICT, -- TODO this should probably be removed
    duration     interval,
    data         jsonb,
    status       smallint
  )

  CREATE TABLE delivery (
    delivery_id     serial PRIMARY KEY,
    address_id      integer REFERENCES full_address (address_id) ON DELETE SET NULL,
    dispatch        timestamp,
    actual_dispatch timestamp
    created         timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE OR REPLACE VIEW item_list_v AS
    SELECT
      i.item_uuid,
      i.type,
      p.product_id,
      p.type AS product_type,
      p.sku,
      COALESCE(p.sku, p.code, p.supplier_code, p.manufacturer_code, fam.code) AS code,
      COALESCE(i.name, p.name, fam.name) AS name,
      COALESCE(i.short_desc, p.short_desc, fam.short_desc) AS short_desc,
      i.created,
      i.modified
    FROM scm.item i
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE i.end_at IS NULL OR i.end_at > CURRENT_TIMESTAMP;

-- Replace the native sales.line_item_v to include Items
CREATE OR REPLACE VIEW sales.line_item_v AS
  SELECT
    li.line_item_id,
    li.order_id,
    li.product_id,
    sli.item_uuid,
    li.line_position,
    li.quantity,
    coalesce(pv.name, iv.name) AS name,
    coalesce(pv.short_desc, iv.short_desc) AS short_desc,
    coalesce(pv.code, iv.code) AS code,
    coalesce(i.gross, ip.gross, pp.gross) AS gross,
    coalesce(ip.cost, pp.cost) AS cost,
    (coalesce(ip.gross, pp.gross) * li.quantity)::numeric(10,2) AS line_total,
    li.data
  FROM sales.line_item li
  LEFT JOIN prd.product_list_v pv
    ON pv.product_id = li.product_id
  LEFT JOIN prd.price_v pp
    ON pp.product_id = li.product_id
  LEFT JOIN scm.line_item sli
    USING (line_item_id)
  LEFT JOIN scm.item_list_v iv
    ON iv.item_uuid = sli.item_uuid
  LEFT JOIN scm.item i
    ON i.item_uuid = sli.item_uuid
  LEFT JOIN scm.price(sli.item_uuid) ip
    ON ip IS NOT NULL
  WHERE li.end_at IS NULL OR li.end_at > CURRENT_TIMESTAMP;
