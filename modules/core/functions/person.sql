CREATE OR REPLACE FUNCTION core.person (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_uuid,
      p.name,
      prsn.email,
      prsn.mobile,
      prsn.phone,
      p.address_uuid,
      p.billing_address_uuid,
      'PERSON'::core.party_kind_t AS kind
    FROM core.party p
    INNER JOIN core.person prsn
      USING (party_uuid)
    WHERE p.party_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION core.person (json, OUT result json) AS
$$
BEGIN
  IF $1->>'party_uuid' IS NOT NULL THEN
    SELECT core.person(($1->>'party_uuid')::uuid) INTO result;
  ELSIF $1->>'email' IS NOT NULL THEN
    SELECT core.person((
      SELECT p.party_uuid
      FROM core.person p
      WHERE p.email = $1->>'email'
    )) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
