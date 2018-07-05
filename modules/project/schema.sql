CREATE SCHEMA prj
  CREATE TABLE project (
    project_id serial PRIMARY KEY,
    owner_id   integer REFERENCES party (party_id) ON DELETE SET NULL,
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE deliverable (
    deliverable_id serial PRIMARY KEY,
    project_id     integer REFERENCES project (project_id) ON DELETE CASCADE,
    name           text,
    dependency     integer REFERENCES deliverable (deliverable_id),
    lag            interval,
    lead           interval,
    data           jsonb,
    created        timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE work_package (
    work_pckg_id   serial PRIMARY KEY,
    name           text,
    deliverable_id integer REFERENCES deliverable (deliverable_id) ON DELETE CASCADE,
    status         integer,
    created        timestamp DEFAULT CURRENT_TIMESTAMP
  );

--
-- Functions
--

CREATE OR REPLACE FUNCTION prj._get_project (integer, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      project_id AS "projectId",
      get_full_address(project.address_id) AS "address",
      get_party(project.owner_id) AS "owner",
      created
    FROM prj.project project
    WHERE project.project_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prj.get_project (json, OUT result json) AS
$$
BEGIN
  SELECT prj._get_project(($1->>'projectId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION prj._create_project (json, OUT result integer) AS
$$
BEGIN
  INSERT INTO prj.project (
    address_id,
    owner_id
  ) VALUES (
    CASE
      WHEN $1->>'addressId' IS NOT NULL THEN
        ($1->>'addressId')::integer
      WHEN $1->'address' IS NOT NULL THEN
        _create_full_address($1->'address')
    END,
    CASE
      WHEN $1->>'ownerId' IS NOT NULL THEN
        ($1->>'ownerId')::integer
      WHEN $1->'owner' IS NOT NULL THEN
        _create_party($1->'owner')
    END
  ) RETURNING project_id INTO result;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prj.create_project (json, OUT result json) AS
$$
BEGIN
  SELECT prj.get_project(prj._create_project($1)) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
