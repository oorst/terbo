CREATE TABLE organisation (
  organisation_id     serial PRIMARY KEY,
  party_id            integer DEFAULT nextval('party_id_seq'),
  name                text,
  data                jsonb,
  created             timestamp(0) DEFAULT LOCALTIMESTAMP
);
