/**
@function hucx.create_owner (options json, OUT result json)

Create an owner for a project where the owner does not previously exist.

Owners are a _Party_.

@params
  @options
    See createParty

@returns The newly created owner.
*/

CREATE OR REPLACE FUNCTION hucx._create_owner (json, OUT result integer) AS
$$
BEGIN
  INSERT INTO hucx.owner (
    project_id,
    party_id
  ) values (
    ($1->>'projectId')::integer,
    _create_party($1)
  ) RETURNING owner_id INTO result;

  UPDATE hucx.project
  SET owner_id = result
  WHERE project_id = ($1->>'projectId')::integer;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION hucx.create_owner (json, OUT result json) AS
$$
BEGIN
  SELECT hucx._get_owner(hucx._create_owner($1)) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
