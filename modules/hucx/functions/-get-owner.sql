CREATE OR REPLACE FUNCTION hucx._get_owner (integer, OUT result json) AS
$$
BEGIN
  SELECT jsonb_set(_get_party(p.party_id)::jsonb, '{ownerId}', $1::text::jsonb) INTO result
  FROM hucx.owner o
  INNER JOIN party p USING (party_id)
  WHERE o.owner_id = $1;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION hucx.get_owner (json, OUT result json) AS
$$
BEGIN
  SELECT hucx._get_owner(($1->>'ownerId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
