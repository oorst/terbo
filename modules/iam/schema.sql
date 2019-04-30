-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA iam;

CREATE TABLE iam.identity (
  identity_uuid uuid REFERENCES core.party (party_uuid),
  hash          text,
  created       timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by    uuid REFERENCES core.party (party_uuid),
  PRIMARY KEY (identity_uuid)
);

CREATE TABLE iam.role (
  role_id    serial PRIMARY KEY,
  name       text,
  created    timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by uuid REFERENCES core.party (party_uuid)
);

CREATE TABLE iam.identity_role (
  identity_uuid uuid REFERENCES iam.identity (identity_uuid) ON DELETE CASCADE,
  role_id       integer REFERENCES iam.role (role_id) ON DELETE CASCADE,
  flags         integer DEFAULT 1,
  created       timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by    uuid REFERENCES core.party (party_uuid)
);
