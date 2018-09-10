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
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
