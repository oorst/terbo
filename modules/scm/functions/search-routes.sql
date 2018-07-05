CREATE OR REPLACE FUNCTION scm.search_routes (json, OUT result json) AS
$$
-- This function uses regular expressions to match code and names.
-- Probably not very efficient
DECLARE
  regex text;
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  regex = '.*' || ($1->>'search')::text || '.*';

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      rt.route_id AS id,
      rt.name
    FROM scm.route rt
    WHERE rt.name ~* regex
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
