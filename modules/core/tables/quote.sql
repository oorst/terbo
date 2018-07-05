CREATE TABLE quote (
  quote_id  serial PRIMARY KEY,
  quote_num text,
  source    integer,
  recipient integer REFERENCES entity (entity_id),
  data      jsonb,
  created   timestamp(0) DEFAULT LOCALTIMESTAMP
);
