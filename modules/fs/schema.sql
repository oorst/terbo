-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA fs
  CREATE TABLE node (
    node_uuid   uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    parent_uuid uuid REFERENCES node (node_uuid) ON DELETE CASCADE,
    owner_id    integer REFERENCES party (party_id) ON DELETE SET NULL,
    data        jsonb,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by  integer REFERENCES person (party_id)
  );
