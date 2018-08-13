-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Insert SCM related settings
INSERT INTO core_settings VALUES ('rgx.uuid', '^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$');

-- Create types
CREATE TYPE scm_item_t AS ENUM ('ITEM', 'SUBASSEMBLY', 'PART', 'PRODUCT');
CREATE TYPE scm_task_concurrency_t AS ENUM ('SAME', 'ALL');

CREATE SCHEMA scm
  CREATE TABLE route (
    route_id serial PRIMARY KEY,
    name     text,
    data     jsonb,
    modified timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE sub_route (
    route_id  integer REFERENCES route (route_id) PRIMARY KEY,
    parent_id integer REFERENCES route (route_id),
    seq_num   integer
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
    product_id     integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    -- Identifier, should be unique amongst sub items
    type           scm_item_t,
    prototype_uuid uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    name           text,
    data           jsonb,
    attributes     jsonb,
    -- Explode composite products when generating bill of quanitities etc
    explode        integer DEFAULT 1,
    route_id       integer REFERENCES route (route_id) ON DELETE SET NULL,
    -- A set price takes precedence over a calculated price
    gross          numeric(10,2),
    net            numeric(10,2),
    weight         numeric(10,3),
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at         timestamp,
    modified       timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE sub_assembly (
    sub_assembly_id serial PRIMARY KEY,
    root_uuid       uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    parent_uuid     uuid REFERENCES item (item_uuid) ON DELETE RESTRICT,
    item_uuid       uuid REFERENCES item (item_uuid) ON DELETE CASCADE,
    quantity        numeric(10,3)
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
    concurrency    scm_task_concurrency_t DEFAULT 'SAME',
    data           jsonb,
    boq_id         integer REFERENCES boq (boq_id) ON DELETE SET NULL,
    work_center_id integer REFERENCES work_center (work_center_id) ON DELETE SET NULL,
    modified       timestamp DEFAULT current_timestamp
  )

  CREATE TABLE route_task (
    route_task_id serial PRIMARY KEY,
    route_id      integer REFERENCES route (route_id) ON DELETE CASCADE,
    task_id       integer REFERENCES task (task_id) ON DELETE CASCADE,
    seq_num       integer
  )

  /**
  Task instances are used for items that are parametric in nature.

  ### Triggers
  - task_instance_tg: On insert, a new boq is also inserted with
  task_instance.boq_id = boq.boq_id
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

  CREATE OR REPLACE VIEW item_v AS
    SELECT
      i.item_uuid,
      i.type,
      p.product_id,
      COALESCE(i.name, p.name, fam.name) AS _name,
      p.code,
      p.sku,
      p.manufacturer_code,
      p.supplier_code
    FROM scm.item i
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE i.end_at IS NULL OR i.end_at > CURRENT_TIMESTAMP

  CREATE OR REPLACE VIEW item_list_v AS
    SELECT
      i.item_uuid,
      i.type,
      i.name,
      p.product_id,
      p.type AS product_type,
      p.sku,
      COALESCE(p.sku, p.code, p.supplier_code, p.manufacturer_code, fam.code) AS "$code",
      COALESCE(i.name, p.name, fam.name) AS "$name",
      COALESCE(p.description, fam.description) AS "$description",
      p.created,
      p.modified
    FROM item i
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    WHERE i.end_at IS NULL OR i.end_at > CURRENT_TIMESTAMP;

--
-- Triggers
--

CREATE OR REPLACE FUNCTION scm.task_instance_tg () RETURNS TRIGGER AS
$$
BEGIN
  IF TG_OP = 'DELETE' THEN
    DELETE FROM scm.boq WHERE boq_id = OLD.boq_id;

    RETURN OLD;
  ELSIF TG_OP = 'INSERT' THEN
    -- Insert a new BoQ for the task instance and provide its boq_id to the new
    -- task_instance
    WITH new_boq AS (
      INSERT INTO scm.boq DEFAULT VALUES RETURNING boq_id
    )
    SELECT boq_id INTO NEW.boq_id
    FROM new_boq;

    RETURN NEW;
  END IF;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER task_instance_tg BEFORE INSERT ON scm.task_instance
  FOR EACH ROW EXECUTE PROCEDURE scm.task_instance_tg();

CREATE TRIGGER task_instance_delete_tg AFTER DELETE ON scm.task_instance
  FOR EACH ROW EXECUTE PROCEDURE scm.task_instance_tg();
