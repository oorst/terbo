-- Create types
CREATE TYPE work_order_status_t AS ENUM ('PENDING', 'AUTHORISED', 'IN_PROGRESS', 'PAUSED', 'ABORTED', 'FINISHED', 'COMPLETED');

CREATE SCHEMA works
  CREATE TABLE work_center (
    work_center_id       serial PRIMARY KEY,
    name                 text,
    short_desc           text,
    description          text,
    default_instructions text,
    created              timestamp DEFAULT CURRENT_TIMESTAMP,
    modified             timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE work_order (
    work_order_id  serial PRIMARY KEY,
    parent_id      integer REFERENCES work_order (work_order_id),
    product_id     integer REFERENCES prd.product (product_id) ON DELETE SET NULL,
    order_id       integer REFERENCES sales.order (order_id) ON DELETE SET NULL,
    status         work_order_status_t DEFAULT 'PENDING',
    quantity       numeric(10,3),
    instructions   text,
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    modified       timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE service (
    work_center_id integer REFERENCES work_center (work_center_id) ON DELETE CASCADE,
    product_id     integer REFERENCES prd.product (product_id) ON DELETE CASCADE,
    PRIMARY KEY (work_center_id, product_id)
  )

  CREATE TABLE asset (
    asset_uuid uuid PRIMARY KEY,
    url        text,
    name       text,
    short_desc text,
    created    timestamp
  )

  CREATE OR REPLACE VIEW work_order_list_v AS
    SELECT
      w.work_order_id,
      w.parent_id,
      w.product_id,
      coalesce(parent.order_id, w.order_id) AS order_id,
      w.status,
      w.quantity,
      w.instructions,
      w.created,
      w.modified
    FROM work_order w
    LEFT JOIN work_order parent
      ON parent.work_order_id = w.parent_id;
