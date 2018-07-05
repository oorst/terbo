CREATE OR REPLACE FUNCTION scm.create_item (json, OUT result json) AS
$$
BEGIN
  IF UPPER($1->>'type') = ANY(enum_range(null::scm_item_t)::text[]) IS NOT TRUE THEN
    RAISE EXCEPTION 'a valid type must be provided'
      USING HINT = 'valid item types are ''ITEM'', ''SUBASSEMBLY'',''PART'' or ''PRODUCT''';
  END IF;

  IF $1->'parentUuid' IS NULL AND UPPER($1->>'type') != 'ITEM' THEN
    RAISE EXCEPTION 'cannot create sub-assembly, part or product without a parent uuid';
  END IF;

  WITH payload AS (
    SELECT
      p."productId" AS product_id,
      UPPER(p.type)::scm_item_t AS type,
      p.name,
      p."parentUuid" AS parent_uuid
    FROM json_to_record($1) AS p (
      "productId"  integer,
      type         text,
      name         text,
      "parentUuid" uuid
    )
  ), new_item AS (
    INSERT INTO scm.item (
      product_id,
      type,
      name
    )
    SELECT
      product_id,
      type,
      name
    FROM payload
    RETURNING *
  ), sub_assembly AS (
    INSERT INTO scm.sub_assembly (
      root_uuid,
      parent_uuid,
      item_uuid
    )
    SELECT
      CASE
        WHEN parent.type = 'ITEM' THEN
          parent.item_uuid
        WHEN parent_sub.root_uuid IS NOT NULL THEN
          parent_sub.root_uuid
        ELSE NULL
      END,
      p.parent_uuid,
      (SELECT item_uuid FROM new_item)
    FROM payload p
    LEFT JOIN scm.item parent
      ON parent.item_uuid = p.parent_uuid
    LEFT JOIN scm.sub_assembly parent_sub
      ON parent_sub.item_uuid = p.parent_uuid
    WHERE p.parent_uuid IS NOT NULL
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.type,
      i.name,
      p.product_id AS "productId",
      p.name AS "productName",
      s.parent_uuid AS "parentUuid",
      s.root_uuid AS "rootId"
    FROM new_item i
    LEFT JOIN prd.product_abbr_v p
      USING (product_id)
    LEFT JOIN sub_assembly s
      USING (item_uuid)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
