CREATE TABLE phone (
  phone_id serial PRIMARY KEY,
  party_id integer REFERENCES party (party_id),
  num      text,
  name     text,
  created  timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
