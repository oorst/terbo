CREATE OR REPLACE FUNCTION core.search_party (json, OUT result json) AS
$$
BEGIN
  WITH parties AS (
    SELECT
      party_uuid,
      name,
      NULL AS trading_name,
      email,
      NULL AS url
    FROM core.person
    WHERE to_tsvector(concat_ws(' ', name, email)) @@ to_tsquery(($1->>'search') || ':*')

    UNION ALL

    SELECT
      party_uuid,
      name,
      trading_name,
      NULL AS email,
      url
    FROM core.organisation
    WHERE to_tsvector(concat_ws(' ', name, trading_name)) @@ to_tsquery(($1->>'search') || ':*')
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      party_uuid,
      name,
      trading_name,
      email,
      url
    FROM parties
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
