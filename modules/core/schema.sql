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
  party_uuid uuid      DEFAULT uuid_generate_v4() PRIMARY KEY,
  kind                 core.party_kind_t,
  name                 text NOT NULL,
  data                 jsonb,
  address_uuid         uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL,
  billing_address_uuid uuid REFERENCES core.address (address_uuid) ON DELETE SET NULL,
  tsv                  tsvector,
  created              timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified             timestamptz
);

CREATE TABLE core.person (
  party_uuid           uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  email                text UNIQUE,
  mobile               text,
  phone                text,
  PRIMARY KEY (party_uuid)
);

CREATE TABLE core.organisation (
  party_uuid           uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  trading_name         text,
  url                  text,
  industry_code        text,
  PRIMARY KEY (party_uuid)
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

CREATE TABLE core.document (
  document_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  document_num  bigserial,
  data          jsonb,
  created       timestamptz DEFAULT CURRENT_TIMESTAMP
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
