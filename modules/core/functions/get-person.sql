CREATE OR REPLACE FUNCTION get_person (id integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
     'person' AS type,
      party_id AS id,
      name,
      email,
      mobile,
      phone,
      CASE
        WHEN address IS NOT NULL THEN
          get_address(address)
        ELSE NULL
      END
    FROM person
    WHERE party_id = id
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_person (json, OUT result json) AS
$$
BEGIN
  IF $1->>'id' IS NOT NULL THEN
    SELECT get_person(($1->>'id')::integer) INTO result;
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
