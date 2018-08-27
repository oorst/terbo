CREATE OR REPLACE FUNCTION prd.get_uoms (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      uom_id AS "uomId",
      name,
      type,
      abbr
    FROM prd.uom
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
