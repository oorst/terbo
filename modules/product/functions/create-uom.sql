CREATE OR REPLACE FUNCTION prd.create_uom (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j.name,
      j.abbr,
      j.type
    FROM json_to_record($1) AS j (
      name text,
      abbr text,
      type text
    )
  ), uom AS (
    INSERT INTO prd.uom (
      name,
      abbr,
      type
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      uom_id AS "uomId",
      name,
      abbr,
      type
    FROM product_uom
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
