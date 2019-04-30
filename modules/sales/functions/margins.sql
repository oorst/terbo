CREATE OR REPLACE FUNCTION sales.margins (OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      margin_id,
      amount,
      name
    FROM sales.margin
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;