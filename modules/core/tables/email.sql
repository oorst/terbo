CREATE TABLE email (
  email_id serial PRIMARY KEY,
  party_id integer REFERENCES party (party_id),
  address  text,
  name     text,
  created  timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
