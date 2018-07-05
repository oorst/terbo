CREATE OR REPLACE FUNCTION scm.search_tasks (json, OUT result json) AS
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
      t.task_id AS id,
      COALESCE(t.name, p.name) AS name
    FROM scm.task t
    INNER JOIN prd.product p
      USING (product_id)
    WHERE concat(t.name, p.name) ~* regex
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
