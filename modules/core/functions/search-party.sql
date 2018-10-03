CREATE OR REPLACE FUNCTION search_party (json, OUT result json) AS
$$
BEGIN
  WITH parties AS (
    SELECT
      party_id,
      name,
      NULL AS trading_name,
      email,
      NULL AS url
    FROM person
    WHERE to_tsvector(concat_ws(' ', name, email)) @@ plainto_tsquery(($1->>'search') || ':*')

    UNION ALL

    SELECT
      party_id,
      name,
      trading_name,
      NULL AS email,
      url
    FROM organisation
    WHERE to_tsvector(concat_ws(' ', name, trading_name)) @@ plainto_tsquery(($1->>'search') || ':*')
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      party_id AS "partyId",
      name,
      trading_name AS "tradingName",
      email,
      url
    FROM parties
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
