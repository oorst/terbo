CREATE OR REPLACE FUNCTION prd.get_markups (OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT markup_id AS id, name
    FROM prd.markup
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
