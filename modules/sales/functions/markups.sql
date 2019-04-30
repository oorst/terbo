CREATE OR REPLACE FUNCTION sales.markups (OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      markup_id,
      amount,
      name
    FROM sales.markup
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;