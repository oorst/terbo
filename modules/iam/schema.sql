-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA iam
  CREATE TABLE identity (
    identity_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    hash          text,
    party_id      integer REFERENCES party (party_id) ON DELETE CASCADE,
    oid           oid REFERENCES pg_roles (oid),
    created       timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by    integer REFERENCES party (party_id) ON DELETE SET NULL
  )

  CREATE TABLE role (
    role_id    serial PRIMARY KEY,
    name       text,
    created    timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by integer REFERENCES party (party_id)
  )

  CREATE TABLE identity_role (
    identity_uuid uuid REFERENCES identity (identity_uuid) ON DELETE CASCADE,
    role_id       integer REFERENCES role (role_id) ON DELETE CASCADE,
    flags         integer DEFAULT 1,
    created       timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by    integer REFERENCES party (party_id) ON DELETE SET NULL
  );
