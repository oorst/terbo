CREATE TABLE class (
  class_id serial PRIMARY KEY,
  name     text,
  children integer REFERENCES class (class_id),
  created  timestamp(0) DEFAULT LOCALTIMESTAMP
);
