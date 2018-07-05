CREATE OR REPLACE FUNCTION get_party (id integer, OUT result json) AS
$$
BEGIN
  WITH party AS (
    SELECT *
    FROM party
    WHERE party_id = id
  )
  SELECT
    CASE
      WHEN p.type = 'PERSON' THEN
        get_person(p.party_id)
      WHEN p.type = 'ORGANISATION' THEN
        get_organisation(p.party_id)
      ELSE NULL
    END INTO result
  FROM party p;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_party (json, OUT result json) AS
$$
BEGIN
  SELECT get_party(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
