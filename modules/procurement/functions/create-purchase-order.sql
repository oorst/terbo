/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.create_purchase_order (OUT result json) AS
$$
BEGIN
  WITH purchase_order AS (
    INSERT INTO pcm.purchase_order DEFAULT VALUES
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId"
    FROM purchase_order po
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
