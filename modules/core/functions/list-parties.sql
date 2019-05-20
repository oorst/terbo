CREATE OR REPLACE FUNCTION core.list_parties (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.party_uuid,
      p.name,
      prsn.email,
      o.trading_name,
      o.url
    FROM core.party p
    LEFT JOIN core.person prsn
      ON prsn.party_uuid = p.party_uuid
    LEFT JOIN core.organisation o
      ON o.party_uuid = p.party_uuid
    WHERE p.tsv @@ to_tsquery($1->>'search' || ':*')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
