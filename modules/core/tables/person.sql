/**
### Flags

Flags is a bitmask that indicates a Person's role in the system as follows:

1 = Staff
2 = Regular user
4 = Sales lead
8 = Guest

A person can have one or more of these flags in addition to the roles data
which is related to RBAC.
*/

CREATE TABLE person (
  person_id      serial PRIMARY KEY,
  name           text,
  email          text UNIQUE,
  mobile         text,
  phone          text,
  address        integer REFERENCES address (address_id) ON DELETE CASCADE, -- Residential address
  postal_address integer REFERENCES address (address_id) ON DELETE CASCADE, -- Postal address
  created        timestamp DEFAULT CURRENT_TIMESTAMP
);
