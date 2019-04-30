CREATE OR REPLACE FUNCTION prd.parts (json DEFAULT NULL, parent_uuid uuid DEFAULT NULL, OUT result json) AS
$$
BEGIN
  IF $1 IS NOT NULL THEN
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        p.part_uuid,
        p.part_name,
        NULLIF(p.quantity, 1.000) AS quantity,
        pv.name,
        prd.parts(parent_uuid => p.part_uuid) AS children
      FROM prd.part p
      LEFT JOIN prd.product_v pv
        USING (product_uuid)
      WHERE p.product_uuid = ($1->>'product_uuid')::uuid
    ) r;
  ELSIF $2 IS NOT NULL THEN
    SELECT json_strip_nulls(json_agg(r)) INTO result
    FROM (
      SELECT
        p.part_uuid,
        p.part_name,
        NULLIF(p.quantity, 1.000) AS quantity,
        pv.name,
        prd.parts(parent_uuid => p.part_uuid) AS children
      FROM prd.part p
      LEFT JOIN prd.product_v pv
        USING (product_uuid)
      WHERE p.parent_uuid = $2
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql';