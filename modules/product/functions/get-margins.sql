CREATE OR REPLACE FUNCTION prd.get_margins (OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      margin_id AS "marginId",
      amount,
      name
    FROM prd.margin
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
