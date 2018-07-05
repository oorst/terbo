CREATE TABLE application.user (
  user_id   serial PRIMARY KEY,
  person_id integer REFERENCES person (person_id),
  hash      text,
  created   timestamp DEFAULT CURRENT_TIMESTAMP
);
