CREATE OR REPLACE FUNCTION core.person (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_uuid,
      p.name,
      p.email,
      p.mobile,
      p.phone,
      p.address_uuid,
      p.billing_address_uuid,
      'PERSON'::core.party_kind_t AS kind
    FROM core.person p
    WHERE p.party_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION core.person (json, OUT result json) AS
$$
BEGIN
  IF $1->>'partyId' IS NOT NULL THEN
    SELECT get_person(($1->>'partyId')::integer) INTO result;
    RETURN;
  ELSIF $1->>'email' IS NOT NULL THEN
    SELECT get_person((
      SELECT party_id
      FROM person
      WHERE email = $1->>'email'
    )) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
