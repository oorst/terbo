CREATE OR REPLACE FUNCTION prd.list_products (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      p.product_uuid,
      p.short_desc,
      p.name,
      p.code,
      p.sku,
      p.manufacturer_code,
      p.supplier_code,
      fam.product_uuid AS family_uuid,
      fam.name AS family_name,
      fam.code AS family_code,
      u.name AS uom_name
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_uuid = p.family_uuid
    LEFT JOIN prd.uom u
      ON u.uom_id = p.uom_id
    WHERE p.tsv @@ to_tsquery($1->>'search' || '.*')
    AND ($1->'type' IS NULL OR p.type = ($1->>'type')::prd.product_t)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
