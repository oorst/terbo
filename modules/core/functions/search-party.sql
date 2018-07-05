CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE OR REPLACE FUNCTION search_party (json, OUT result json) AS
$$
BEGIN
  WITH parties AS (
    SELECT
      party_id,
      name,
      email,
      NULL AS url
    FROM person
    WHERE name % ($1->>'search')

    UNION ALL

    SELECT
      party_id,
      name,
      NULL AS email,
      url
    FROM organisation
    WHERE name % ($1->>'search')
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
