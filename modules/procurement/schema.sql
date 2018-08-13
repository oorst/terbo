CREATE SCHEMA prc
  CREATE TABLE rfq (
    rfq_id   serial PRIMARY KEY,
    created  timestamp DEFAULT CURRENT_TIMESTAMP,
    modified timestamp
  )

  -- Partys who receive an RFQ
  CREATE TABLE rfq_recipient (
    rfq_id   integer REFERENCES rfq (rfq_id),
    party_id integer REFERENCES party (party_id) ON DELETE SET NULL
  )

  CREATE TABLE line_item (
    line_item_id serial PRIMARY KEY,
    product_id   integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    created_by integer REFERENCES person (party_id) ON DELETE SET NULL,
    created    timestamp DEFAULT CURRENT_TIMESTAMP,
    modified   timestamp DEFAULT CURRENT_TIMESTAMP
  )
