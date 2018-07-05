CREATE TABLE access_control.password_reset (
  reset_id  SERIAL PRIMARY KEY,
  key       uuid,
  person_id integer REFERENCES person(person_id),
  created   timestamp(0) DEFAULT CURRENT_TIMESTAMP
);
