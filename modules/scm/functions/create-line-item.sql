CREATE OR REPLACE FUNCTION sales.create_line_item (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1->'itemUuid') = 'null' THEN
    WITH payload AS (
      SELECT
        j.name,
        j."orderId" AS order_id,
        j."userId" AS created_by
      FROM json_to_record($1) AS j (
        name      text,
        "orderId" integer,
        "userId"  integer
      )
    ), item AS (
      INSERT INTO scm.item (
        name
      )
      SELECT name
      FROM payload
      RETURNING *
    ), sales_line_item AS (
      INSERT INTO sales.line_item (
        order_id
      ) VALUES (
        ($1->>'orderId')::integer
      )
      RETURNING line_item_id
    ), scm_line_item AS (
      INSERT INTO scm.line_item (
        item_uuid,
        line_item_id,
        created_by
      ) VALUES (
        (SELECT item_uuid FROM item),
        (SELECT line_item_id FROM sales_line_item),
        (SELECT created_by FROM payload)
      )
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        item_uuid AS "itemUuid",
        name
      FROM item
    ) r;
  ELSIF $1->>'itemUuid' IS NOT NULL THEN -- Clone the given item
    WITH payload AS (
      SELECT
        j."orderId" AS order_id,
        j."itemUuid" AS item_uuid,
        j."userId" AS created_by
      FROM json_to_record($1) AS j (
        "orderId"  integer,
        "itemUuid" uuid,
        "userId"   integer
      )
    ), sales_line_item AS (
      INSERT INTO sales.line_item (
        order_id
      )
      SELECT
        order_id
      FROM payload
      RETURNING line_item_id, created
    ), scm_line_item AS (
      INSERT INTO scm.line_item (
        item_uuid,
        line_item_id,
        created_by
      ) VALUES (
        (SELECT item_uuid FROM payload),
        (SELECT line_item_id FROM sales_line_item),
        (SELECT created_by FROM payload)
      )
      RETURNING line_item_id
    )
    SELECT json_strip_nulls(to_json(r)) INTO result
    FROM (
      SELECT
        li.line_item_id AS "lineItemId",
        li.created
      FROM scm_line_item
      INNER JOIN sales_line_item li
        USING (line_item_id)
    ) r;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
