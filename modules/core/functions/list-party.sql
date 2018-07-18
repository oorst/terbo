CREATE OR REPLACE FUNCTION list_party (json, OUT result json) AS
$$
BEGIN
  WITH parties AS (
    SELECT
      party_id,
      name,
      email,
      NULL AS url
    FROM person
    WHERE to_tsvector(concat_ws(' ', name, email)) @@ plainto_tsquery($1->>'search')

    UNION ALL

    SELECT
      party_id,
      coalesce(trading_name, name) AS name,
      NULL AS email,
      url
    FROM organisation
    WHERE to_tsvector(concat_ws(' ', name, trading_name)) @@ plainto_tsquery($1->>'search')
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      party_id AS id,
      name,
      email,
      url
    FROM parties
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
