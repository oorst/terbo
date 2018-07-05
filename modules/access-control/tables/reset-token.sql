CREATE TABLE access_control.reset_token (
  token_id  SERIAL PRIMARY KEY,
  key       uuid,
  person_id integer REFERENCES person(person_id),
  created   timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
