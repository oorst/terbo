CREATE OR REPLACE FUNCTION scm.search_items (json, OUT result json) AS
$$
-- This function uses regular expressions to match code and names.
-- Probably not very efficient
DECLARE
  regex text;
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  regex = '.*' || ($1->>'search')::text || '.*';

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.product_id AS "productId",
      i.name,
      i.code,
      i.sku,
      i.manufacturer_code AS "manufacturerCode",
      i.supplier_code AS "supplierCode",
      root_i.item_uuid AS "rootUuid",
      parent_i.item_uuid AS "parentUuid",
      root_i.name AS "rootName",
      parent_i.name AS "parentName",
      CONCAT(
        i.name,
        i.code,
        i.sku,
        i.manufacturer_code,
        i.supplier_code,
        i.name
      ) AS search
    FROM scm.item_v i
    LEFT JOIN scm.sub_assembly sub
      ON sub.item_uuid = i.item_uuid
    LEFT JOIN scm.item_v root_i
      ON root_i.item_uuid = sub.root_uuid
    LEFT JOIN scm.item_v parent_i
      ON parent_i.item_uuid = sub.parent_uuid
    WHERE CONCAT(
      i.name,
      i.code,
      i.sku,
      i.manufacturer_code,
      i.supplier_code,
      i.name
    )  ~* '.*bibian.*'
    ORDER BY name ASC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
