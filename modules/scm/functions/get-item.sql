CREATE OR REPLACE FUNCTION scm.get_item(_uuid uuid, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.type,
      i.data,
      i.name,
      -- Product
      (
        SELECT json_strip_nulls(to_json(r))
        FROM (
          SELECT
            p.product_id AS id,
            p.name,
            p.code,
            p.manufacturer_code,
            p.supplier_code,
            p.sku
          WHERE NOT (p IS NULL)
        ) r
      ) AS product,
      (
        SELECT json_strip_nulls(json_agg(r))
        FROM (
          SELECT
            s.sub_assembly_id AS "subAssemblyId",
            s.quantity,
            iv.item_uuid AS uuid,
            iv.type,
            iv.name,
            iv.code,
            iv.sku,
            iv.manufacturer_code AS "manufacturerCode",
            iv.supplier_code AS "supplierCode"
          FROM scm.sub_assembly s
          INNER JOIN scm.item_v iv
            ON iv.item_uuid = s.item_uuid
          WHERE s.parent_uuid = i.item_uuid
          ORDER BY s.sub_assembly_id
        ) r
      ) AS "subAssemblies",
      -- Route
      (
        SELECT json_strip_nulls(to_json(r))
        FROM (
          SELECT
            route.route_id AS id,
            route.name
          FROM scm.route route
          WHERE route.route_id = i.route_id
        ) r
      ) AS route
    FROM scm.item i
    LEFT JOIN prd.product_v p
      USING (product_id)
    WHERE i.item_uuid = _uuid
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.get_item(json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p.uuid AS item_uuid,
      p."productId" AS product_id,
      code,
      sku
    FROM json_to_record($1) AS p (
      uuid        uuid,
      "productId" integer,
      code        text,
      sku         text
    )
  )
  SELECT scm.get_item(i.item_uuid) INTO result
  FROM scm.item_v i
  INNER JOIN payload p
    ON i.item_uuid = p.item_uuid
      OR i.product_id = p.product_id
      OR i.code = p.code
      OR i.sku = p.sku;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
