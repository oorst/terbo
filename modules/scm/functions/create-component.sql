CREATE OR REPLACE FUNCTION scm.create_component (json, OUT result json) AS
$$
DECLARE
  payload RECORD;
BEGIN
  SELECT * INTO payload
  FROM (
    SELECT
      j."userId" AS user_id,
      j."itemUuid" AS item_uuid,
      j.type,
      j."productId" AS product_id
    FROM json_to_record($1) AS j (
      "userId"    integer,
      "itemUuid"  uuid,
      type        scm_item_t,
      "productId" integer
    )
  ) r;

  IF payload.type = 'PRODUCT' THEN
    WITH parent AS (
      SELECT
        *
      FROM scm.component c
      WHERE c.item_uuid = payload.item_uuid
    ), new_item AS (
      INSERT INTO scm.item (
        product_id,
        type
      )
      SELECT
        payload.product_id,
        payload.type::scm_item_t
      RETURNING *
    ), component AS (
      INSERT INTO scm.component (
        root_uuid,
        parent_uuid,
        item_uuid
      )
      SELECT
        coalesce((SELECT root_uuid FROM parent), payload.item_uuid),
        payload.item_uuid,
        new_item.item_uuid
      FROM new_item
      RETURNING *
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        c.component_id AS "componentId",
        c.root_uuid AS "rootUuid",
        c.parent_uuid AS "parentUuid",
        c.item_uuid AS "itemUuid",
        coalesce(p.name, f.name) AS name,
        coalesce(p.sku, p.code, p.supplier_code, p.manufacturer_code, f.code, f.supplier_code, f.manufacturer_code) AS code
      FROM component c
      INNER JOIN new_item i
        USING (item_uuid)
      INNER JOIN prd.product p
        USING (product_id)
      LEFT JOIN prd.product f
        ON f.product_id = p.family_id
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
