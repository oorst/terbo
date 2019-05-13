CREATE OR REPLACE FUNCTION core.list_parties (json, OUT result json) AS
$$
BEGIN
  WITH parties AS (
    SELECT
      party_uuid,
      name,
      email,
      NULL AS url
    FROM core.person p
    WHERE to_tsvector(concat_ws(' ', p.name, p.email)) @@ plainto_tsquery($1->>'search')

    UNION ALL

    SELECT
      party_uuid,
      coalesce(trading_name, name) AS name,
      NULL AS email,
      url
    FROM core.organisation o
    WHERE to_tsvector(concat_ws(' ', o.name, o.trading_name)) @@ plainto_tsquery($1->>'search')
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      party_uuid,
      name,
      email,
      url
    FROM parties
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
