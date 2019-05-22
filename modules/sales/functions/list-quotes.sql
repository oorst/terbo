CREATE OR REPLACE FUNCTION sales.list_quotes (json, OUT result json) AS
$$
BEGIN
  WITH quotes AS (
    SELECT
      qv.*,
      to_char(qv.created, core.setting('default_date_format')) AS created
    FROM sales.quote_v qv
    ORDER BY qv.created DESC
    LIMIT 20
  )
  SELECT INTO result
    json_strip_nulls(json_agg(q))
  FROM quotes q;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
