CREATE OR REPLACE FUNCTION prd.components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      c.product_id AS "productId",
      c.uom_id AS "uomId",
      c.quantity,
      pv.name,
      pv.code,
      pv.short_desc AS "shortDescription",
      (
        SELECT
          array_agg(
            json_build_object(
              'uomId', pu.uom_id,
              'name', uom.name,
              'abbr', uom.abbr,
              'type', uom.type
            )
          )
        FROM prd.product_uom_v pu
        LEFT JOIN prd.uom uom
          USING (uom_id)
        WHERE pu.product_id = c.product_id
      ) AS units
    FROM prd.component c
    INNER JOIN prd.product_list_v pv
      USING (product_id)
    WHERE c.parent_id = ($1->>'productId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
