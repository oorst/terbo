CREATE OR REPLACE FUNCTION get_person (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_id AS "partyId",
      p.name,
      p.email,
      p.mobile,
      p.phone,
      p.address_id AS "addressId",
      p.billing_address_id AS "billingAddressId",
      party.type
    FROM person p
    INNER JOIN party
      USING (party_id)
    WHERE party_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_person (json, OUT result json) AS
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
