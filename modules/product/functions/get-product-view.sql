CREATE OR REPLACE FUNCTION prd.get_product_view (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      pr.product_id AS id,
      pr.uuid,
      pr.code,
      pr.sku,
      pr.name,
      pr.description,
      pr.data,
      pr.type,
      COALESCE(pr.gross, pr.cost * (1+(pr.markup/100)))::numeric(10,2) AS gross,
      pr.net,
      -- Units
      (
        SELECT json_agg(r)
        FROM (
          SELECT
            pu.product_uom_id AS "productUomId",
            pu.multiply,
            pu.divide,
            uom.name,
            uom.abbr
          FROM prd.product_uom pu
          INNER JOIN prd.uom uom
            ON uom.uom_id = pu.uom_id
          WHERE pu.product_id = pr.product_id
        ) r
      ) AS units,
      -- Tags
      (
        SELECT json_agg(tag.name)
        FROM prd.product_tag pt
        INNER JOIN prd.tag tag
          USING (tag_id)
        WHERE pt.product_id = pr.product_id
      ) AS tags,
      -- Refs
      (
        SELECT json_agg(ref.name)
        FROM prd.product_ref pref
        INNER JOIN prd.ref ref
          USING (ref_id)
        WHERE pref.product_id = pr.product_id
      ) AS refs,
      pr.uom_id AS "uomId",
      pr.created,
      pr.modified
    FROM prd.product_v pr
    WHERE pr.product_id = ($1->>'id')::integer OR pr.code = ($1->>'code') OR pr.sku = ($1->>'code')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
