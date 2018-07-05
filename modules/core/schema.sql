CREATE TYPE party_t AS ENUM ('PERSON', 'ORGANISATION');

--
-- Tables
--
CREATE TABLE address (
  address_id serial PRIMARY KEY,
  addr1 text,
  addr2 text,
  town text,
  state text,
  code text,
  country text,
  type smallint, -- 0: residential, 1: business
  created timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE full_address (
  address_id    serial PRIMARY KEY,
  lot_number    text,
  road_number_1 text,
  road_number_2 text,
  road_name     text,
  road_type     text,
  road_suffix   text,
  locality_name text,
  state         text,
  code          text,
  country       text,
  type smallint, -- 0: residential, 1: business
  created timestamp(0) DEFAULT LOCALTIMESTAMP
);

CREATE TABLE party (
  party_id serial PRIMARY KEY,
  type     party_t
);

CREATE TABLE person (
  party_id       integer REFERENCES party (party_id) PRIMARY KEY,
  name           text,
  email          text UNIQUE,
  mobile         text,
  phone          text,
  address        integer REFERENCES address (address_id) ON DELETE SET NULL, -- Residential address
  postal_address integer REFERENCES address (address_id) ON DELETE SET NULL, -- Postal address
  created        timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE organisation (
  party_id        integer REFERENCES party (party_id) PRIMARY KEY,
  name            text,
  trading_name    text,
  address         integer REFERENCES address (address_id) ON DELETE SET NULL,
  url             text,
  data            jsonb,
  created         timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role (
  role_id serial PRIMARY KEY,
  name    text
);

CREATE TABLE relationship (
  relationship_id serial PRIMARY KEY,
  name            text,
  description     text,
  -- The parties involved in the relationship, the first role should be the
  -- more superior
  first_role      integer REFERENCES role (role_id) ON DELETE CASCADE,
  second_role     integer REFERENCES role (role_id) ON DELETE CASCADE,
  created         timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE party_relationship (
  relationship_id integer REFERENCES relationship (relationship_id) ON DELETE CASCADE,
  first_party     integer REFERENCES party (party_id) ON DELETE CASCADE,
  second_party    integer REFERENCES party (party_id) ON DELETE CASCADE,
  ended           timestamp,
  created         timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE VIEW party_v AS
  SELECT
    party_id,
    type,
    name
  FROM person
  INNER JOIN party
    USING (party_id)

  UNION ALL

  SELECT
    party_id,
    type,
    name
  FROM organisation
  INNER JOIN party
    USING (party_id);

--
-- Triggers
--

/**
@triggerFunction
  @def party_tg()
  @description
    insert a new party and assign to party_id of person or organisation
  @private
*/
CREATE OR REPLACE FUNCTION party_tg () RETURNS TRIGGER AS
$$
BEGIN
  -- Insert new a party when a person or organisation is created
  WITH new_party AS (
    INSERT INTO party (type) VALUES (
      CASE
        WHEN TG_TABLE_NAME = 'person' THEN
          ('PERSON')::party_t
        ELSE
          ('ORGANISATION')::party_t
      END
    )
    RETURNING party_id
  )
  SELECT party_id INTO NEW.party_id
  FROM new_party;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER person_tg BEFORE INSERT ON person
  FOR EACH ROW EXECUTE PROCEDURE party_tg();

CREATE TRIGGER organisation_tg BEFORE INSERT ON organisation
  FOR EACH ROW EXECUTE PROCEDURE party_tg();

  /**
  @triggerFunction
    @def delete_party_tg()
    @description
      delete party records when a person or organisation is deleted
    @private
  */
  CREATE OR REPLACE FUNCTION delete_party_tg () RETURNS TRIGGER AS
  $$
  BEGIN
    DELETE FROM party WHERE party_id = OLD.party_id;

    RETURN OLD;
  END
  $$
  LANGUAGE 'plpgsql';

  CREATE TRIGGER delete_person AFTER DELETE ON person
    FOR EACH ROW EXECUTE PROCEDURE delete_party_tg();

  CREATE TRIGGER delete_organisation AFTER DELETE ON organisation
    FOR EACH ROW EXECUTE PROCEDURE delete_party_tg();
