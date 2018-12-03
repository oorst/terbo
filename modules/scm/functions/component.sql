CREATE OR REPLACE FUNCTION scm.component (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      c.item_uuid AS "itemUuid",
      c.parent_uuid AS "parentUuid",
      c.product_id AS "productId",
      c.quantity,
      i.name,
      pv.name AS "productName"
    FROM scm.component c
    LEFT JOIN scm.item_list_v i
      USING (item_uuid)
    LEFT JOIN prd.product_list_v pv
      ON pv.product_id = c.product_id
    WHERE c.component_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
