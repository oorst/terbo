CREATE OR REPLACE FUNCTION prd.get_components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT DISTINCT ON (p.product_id)
      c.product_id AS "productId",
      c.quantity,
      coalesce(p.name, f.name) AS name,
      coalesce(p.sku, p.code, p.supplier_code, p.manufacturer_code, f.code) AS code
    FROM prd.component c
    INNER JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product f
      ON f.product_id = p.family_id
    WHERE c.parent_id = ($1->>'productId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
