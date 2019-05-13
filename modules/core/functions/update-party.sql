CREATE OR REPLACE FUNCTION core.update_party (json, OUT result json) AS
$$
DECLARE
  party_kind core.party_kind_t;
BEGIN
  SELECT
    p.kind
  INTO
    party_kind
  FROM core.party p
  WHERE p.party_uuid = ($1->>'party_uuid')::uuid;

  IF party_kind = 'PERSON' THEN
    SELECT core.update_person($1) INTO result;
  ELSIF party_kind = 'ORGANISATION' THEN
    SELECT core.update_organisation($1) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
