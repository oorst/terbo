-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA core;

CREATE TYPE core.party_kind_t AS ENUM ('PERSON', 'ORGANISATION');

--
-- Tables
--
CREATE TABLE core.address (
  address_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  addr1        text,
  addr2        text,
  town         text,
  state        text,
  code         text,
  country      text,
  type         smallint, -- 0: residential, 1: business
  created      timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.full_address (
  address_uuid  uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  lot_number    text,
  road_number1  text,
  road_number2  text,
  road_name     text,
  road_type     text,
  road_suffix   text,
  locality_name text,
  state         text,
  code          text,
  country       text,
  type          smallint, -- 0: residential, 1: business
  created timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.party (
  party_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  kind       core.party_kind_t
);

CREATE TABLE core.person (
  party_uuid           uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  name                 text,
  email                text UNIQUE,
  mobile               text,
  phone                text,
  address_uuid         uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL, -- Residential address
  billing_address_uuid uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL, -- Postal address
  created              timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified             timestamptz,
  PRIMARY KEY (party_uuid)
);

CREATE TABLE core.organisation (
  party_uuid           uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  name                 text,
  trading_name         text,
  address_uuid         uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL,
  billing_address_uuid uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL,
  url                  text,
  industry_code        text,
  data                 jsonb,
  created              timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified             timestamptz,
  PRIMARY KEY (party_uuid),
  CONSTRAINT valid_name CHECK(name IS NOT NULL OR trading_name IS NOT NULL)
);

CREATE TABLE core.role (
  role_id serial PRIMARY KEY,
  name    text
);

CREATE TABLE core.relationship (
  relationship_id serial PRIMARY KEY,
  name            text,
  description     text,
  -- The parties involved in the relationship, the first role should be the
  -- more superior
  first_role      integer REFERENCES core.role (role_id) ON DELETE CASCADE,
  second_role     integer REFERENCES core.role (role_id) ON DELETE CASCADE,
  created         timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.party_relationship (
  relationship_id integer REFERENCES core.relationship (relationship_id) ON DELETE CASCADE,
  first_party     uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  second_party    uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  ended           timestamptz,
  created         timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- A place to put DB related settings
CREATE TABLE core.settings (
  name  text,
  value text
);

CREATE TABLE core.note (
  note_uuid  uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  body       text,
  public     boolean DEFAULT FALSE,
  created    timestamptz DEFAULT CURRENT_TIMESTAMP,
  created_by uuid REFERENCES core.party (party_uuid)
);

CREATE TABLE core.tag (
  tag_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name     text UNIQUE
);

CREATE OR REPLACE VIEW core.party_v AS
  SELECT
    prsn.party_uuid,
    p.kind,
    prsn.name
  FROM core.person prsn
  INNER JOIN core.party p
    USING (party_uuid)

  UNION ALL

  SELECT
    o.party_uuid,
    p.kind,
    coalesce(o.trading_name, o.name) AS name
  FROM core.organisation o
  INNER JOIN core.party p
    USING (party_uuid);

--
-- Triggers
--
CREATE OR REPLACE FUNCTION party_tg () RETURNS TRIGGER AS
$$
BEGIN
RAISE NOTICE '%', TG_TABLE_NAME;
  -- Insert new a party when a person or organisation is created
  INSERT INTO core.party (kind) VALUES (
    CASE
      WHEN TG_TABLE_NAME = 'person' THEN
        ('PERSON')::core.party_kind_t
      ELSE
        ('ORGANISATION')::core.party_kind_t
    END
  )
  RETURNING party_uuid INTO NEW.party_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER person_tg BEFORE INSERT ON core.person
  FOR EACH ROW EXECUTE PROCEDURE party_tg();

CREATE TRIGGER organisation_tg BEFORE INSERT ON core.organisation
  FOR EACH ROW EXECUTE PROCEDURE party_tg();
