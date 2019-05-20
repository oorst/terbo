CREATE OR REPLACE FUNCTION core.organisation (uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.party_uuid,
      p.name,
      o.trading_name,
      o.url,
      p.data,
      'ORGANISATION'::core.party_kind_t AS kind
    FROM core.party p
    INNER JOIN core.organisation o
      USING (party_uuid)
    WHERE p.party_uuid = $1
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
