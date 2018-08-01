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
