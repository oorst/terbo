CREATE OR REPLACE FUNCTION prd.components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id AS "componentId",
      c.product_id AS "productId",
      c.quantity,
      pv.name,
      pv.code,
      pv.short_desc AS "shortDescription"
    FROM prd.component c
    INNER JOIN prd.product_list_v pv
      USING (product_id)
    WHERE c.parent_id = ($1->>'productId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
