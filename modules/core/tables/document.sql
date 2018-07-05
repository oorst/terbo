CREATE TABLE source_document (
  document_id serial PRIMARY KEY,
  data jsonb,
  created_by integer REFERENCES person (person_id) ON DELETE RESTRICT,
  created    timestamp(0) DEFAULT CURRENT_TIMESTAMP
)
