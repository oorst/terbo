CREATE OR REPLACE FUNCTION core.party (uuid, OUT result json) AS
$$
BEGIN
  SELECT
    CASE
      WHEN p.kind = 'PERSON' THEN
        core.person(p.party_uuid)
      WHEN p.kind = 'ORGANISATION' THEN
        core.organisation(p.party_uuid)
      ELSE NULL
    END INTO result
  FROM core.party p
  WHERE p.party_uuid = $1;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION core.party (json, OUT result json) AS
$$
BEGIN
  SELECT core.party(($1->>'party_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
