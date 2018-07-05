CREATE TABLE hucx.owner (
  owner_id   serial PRIMARY KEY,
  project_id integer REFERENCES hucx.project (project_id),
  party_id   integer REFERENCES party (party_id)
);
