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
      (pr.gross * c.quantity)::numeric(10,2) AS gross,
      (pr.cost * c.quantity)::numeric(10,2) AS cost,
      (pr.profit * c.quantity)::numeric(10,2) AS profit,
      pr.margin,
      c.quantity
    FROM scm.component c
    INNER JOIN scm.item i
      USING (item_uuid)
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN prd.price_v pr
      ON pr.product_id = i.product_id
    WHERE c.parent_uuid = ($1->>'itemUuid')::uuid
    ORDER BY c.component_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
