CREATE OR REPLACE FUNCTION works.create_work_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."orderId" AS order_id,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "orderId" integer,
      "userId"  integer
    )
  ),
  -- Create the parent Work Order
  parent_work_order AS (
    INSERT INTO works.work_order (
      order_id
    )
    SELECT
      p.order_id
    FROM payload p
    RETURNING work_order_id
  ), item AS (
    SELECT
      li.item_uuid
    FROM sales.line_item_v li
    INNER JOIN payload p
      USING (order_id)
    WHERE li.item_uuid IS NOT NULL
  ), boq AS (
    SELECT
      b.product_id,
      sum(b.quantity)
    FROM item
    LEFT JOIN scm.item_boq(item.item_uuid) b
      USING (item_uuid)
    LEFT JOIN prd.product p
      USING (product_id)
    WHERE p.type = 'SERVICE' AND p.supplier IS NULL
    GROUP BY b.product_id
  ), work_order AS (
    INSERT INTO works.work_order (
      parent_id,
      product_id,
      quantity,
      work_center_id
    )
    SELECT
      (SELECT work_order_id FROM parent_work_order),
      boq.product_id,
      quantity,
      wc.work_center_id
    FROM boq
    LEFT JOIN works.work_center wc
      USING (product_id)
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT

    FROM parent_work_order
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
