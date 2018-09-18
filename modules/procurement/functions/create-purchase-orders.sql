/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.create_purchase_orders (integer) RETURNS VOID AS
$$
BEGIN
  WITH payload (order_id) AS (
    VALUES (10)
  ),
  -- Select Items from the sales order
  item AS (
    SELECT
      li.item_uuid
    FROM sales.line_item_v li
    INNER JOIN payload p
      USING (order_id)
    WHERE li.item_uuid IS NOT NULL
  ),
  -- Select products that are not inventory items and have a supplier_id or
  -- manufacturer_id
  boq AS (
    SELECT
      b.product_id,
      sum(b.quantity) AS quantity,
      coalesce(p.supplier_id, p.manufacturer_id) AS seller_id
    FROM item
    LEFT JOIN scm.item_boq(item.item_uuid) b
      USING (item_uuid)
    LEFT JOIN prd.product p
      ON p.product_id = b.product_id
    WHERE p.tracked IS FALSE
    GROUP BY b.product_id, p.supplier_id, p.manufacturer_id
  ), purchase_order AS (
    INSERT INTO pcm.purchase_order (
      issued_to
    )
    SELECT
      boq.seller_id
    FROM boq
    INNER JOIN prd.product p
      USING (product_id)
    GROUP BY boq.seller_id
    RETURNING *
  )
  INSERT INTO pcm.line_item (
    purchase_order_id,
    product_id,
    quantity
  )
  SELECT
    po.issued_to,
    boq.product_id,
    boq.quantity
  FROM purchase_order po
  INNER JOIN boq
    ON boq.seller_id = po.issued_to;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
