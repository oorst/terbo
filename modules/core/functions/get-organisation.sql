CREATE OR REPLACE FUNCTION get_organisation (id integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      'organisation' AS type,
      party_id AS id,
      name,
      url,
      data
    FROM organisation
    WHERE party_id = id
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_organisation (json, OUT result json) AS
$$
BEGIN
  SELECT get_organisation(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
