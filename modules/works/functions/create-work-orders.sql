/*
Create the necessary work orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION works.create_work_orders (integer) RETURNS VOID AS
$$
BEGIN
  WITH payload (order_id) AS (
    VALUES ($1)
  ),
  parent_work_order AS (
    INSERT INTO works.work_order (
      order_id,
      status
    ) VALUES (
      $1,
      NULL
    )
    RETURNING *
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
      sum(b.quantity) AS quantity
    FROM item
    LEFT JOIN scm.item_boq(item.item_uuid) b
      USING (item_uuid)
    LEFT JOIN prd.product p
      ON p.product_id = b.product_id
    WHERE p.type = 'SERVICE' AND p.supplier_id IS NULL
    GROUP BY b.product_id
  )
  INSERT INTO works.work_order (
    parent_id,
    product_id,
    quantity
  )
  SELECT
    (SELECT work_order_id FROM parent_work_order),
    boq.product_id,
    boq.quantity
  FROM boq;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
