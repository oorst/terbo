CREATE OR REPLACE FUNCTION scm.get_components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      i.item_uuid AS "itemUuid",
      i.type,
      i.name,
      i.product_id AS "productId",
      p.name,
      p.code,
      c.quantity
    FROM scm.component c
    INNER JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.product p
      USING (product_id)
    WHERE c.parent_uuid = ($1->>'itemUuid')::uuid
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
