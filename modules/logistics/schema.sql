CREATE SCHEMA lgs
  CREATE TABLE delivery (
    delivery_id serial PRIMARY KEY,
    provider_id integer REFERENCES party (party_id),
    tracking    text,
    origin      integer REFERENCES address (address_id),
    destination integer REFERENCES address (address_id)
  )
