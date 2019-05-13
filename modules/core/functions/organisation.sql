CREATE OR REPLACE FUNCTION core.organisation (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      o.party_uuid,
      o.name,
      o.trading_name,
      o.url,
      o.data,
      'ORGANISATION' AS kind
    FROM core.organisation o
    WHERE o.party_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION core.organisation (json, OUT result json) AS
$$
BEGIN
  SELECT core.organisation(($1->>'party_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
