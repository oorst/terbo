CREATE TYPE purchase_order_status_t AS ENUM ('DRAFT', 'RFQ', 'ISSUED', 'VOID');

CREATE SCHEMA pcm
  CREATE TABLE purchase_order (
    purchase_order_id  serial PRIMARY KEY,
    purchase_order_num text,
    order_id           integer REFERENCES sales.order (order_id) ON DELETE SET NULL,
    supplier_id        integer REFERENCES party (party_id) ON DELETE SET NULL,
    status             purchase_order_status_t DEFAULT 'DRAFT',
    data               jsonb,
    approved_by        integer REFERENCES person (party_id) ON DELETE SET NULL,
    created_by         integer REFERENCES person (party_id) ON DELETE SET NULL,
    created            timestamp DEFAULT CURRENT_TIMESTAMP,
    modified           timestamp DEFAULT CURRENT_TIMESTAMP
  )

  -- Partys who receive an RFQ
  CREATE TABLE recipient (
    purchase_order_id integer REFERENCES purchase_order (purchase_order_id),
    party_id          integer REFERENCES party (party_id) ON DELETE SET NULL,
    PRIMARY KEY (purchase_order_id, party_id)
  )

  CREATE TABLE line_item (
    line_item_id      serial PRIMARY KEY,
    purchase_order_id integer REFERENCES purchase_order (purchase_order_id) ON DELETE CASCADE,
    product_id        integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    quantity          numeric(10,3),
    created_by        integer REFERENCES person (party_id) ON DELETE SET NULL,
    created           timestamptz DEFAULT CURRENT_TIMESTAMP,
    modified          timestamptz DEFAULT CURRENT_TIMESTAMP
  );
