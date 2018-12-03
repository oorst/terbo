CREATE OR REPLACE FUNCTION prd.units (integer, OUT result json) AS
$$
BEGIN
  SELECT
    json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      pu.product_uom_id AS "productUomId",
      CASE
        WHEN pu.primary_uom IS TRUE THEN TRUE
        ELSE NULL
      END AS "primaryUom",
      uom.uom_id AS "uomId",
      uom.name,
      uom.type,
      uom.abbr
    FROM prd.product_uom pu
    LEFT JOIN prd.uom uom
      USING (uom_id)
    WHERE pu.product_id = $1
    ORDER BY pu.primary_uom IS TRUE, pu.product_uom_id
  ) r;
END
$$
LANGUAGE 'plpgsql';
