CREATE TABLE invoice (
  invoice_id     serial PRIMARY KEY,
  invoice_num    text,
  source         integer,
  source_type    integer,
  customer       integer REFERENCES entity (entity_id),
  balance        numeric(10,2),
  total          numeric(10,2),
  payment_status payment_status_t DEFAULT 'OWING',
  due_date       timestamp(0),  -- Local timestamp
  issued_at      timestamp(0),  -- Local timestamp
  flags          integer, -- 1 = sent, 2 = cancelled
  data           jsonb,
  created        timestamp(0) DEFAULT CURRENT_TIMESTAMP,
  created_by     integer REFERENCES person (person_id)
);
