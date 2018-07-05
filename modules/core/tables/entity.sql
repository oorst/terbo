CREATE TYPE entity_t AS ENUM ('PERSON', 'ORGANISATION');

CREATE TABLE entity (
  entity_id serial PRIMARY KEY,
  type      entity_t,
  id        integer -- References either Person table or the Organisation table
);
