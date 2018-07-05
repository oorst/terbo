/**
A Party can be a Person or Organisation
*/

CREATE TABLE party (
  party_id serial PRIMARY KEY,
  person_id integer REFERENCES person (person_id),
  organisation_id integer REFERENCES organisation (organisation_id)
);
