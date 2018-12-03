CREATE OR REPLACE FUNCTION scm.components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      i.item_uuid AS "itemUuid",
      i.type,
      i.name,
      c.product_id AS "productId",
      CASE
        WHEN c.item_uuid IS NOT NULL THEN ipv.name
        ELSE pv.name
      END AS "productName",
      pv.code AS "productCode",
      prd.units(c.product_id) AS units,
      c.quantity,
      c.uom_id AS "uomId"
    FROM scm.component c
    LEFT JOIN prd.product_list_v pv
      ON pv.product_id = c.product_id
    LEFT JOIN scm.item i
      ON i.item_uuid = c.item_uuid
    LEFT JOIN prd.product_list_v ipv
      ON ipv.product_id = i.product_id
    WHERE c.parent_uuid = ($1->>'itemUuid')::uuid
    ORDER BY c.component_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
