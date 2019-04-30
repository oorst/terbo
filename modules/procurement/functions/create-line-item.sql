/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.create_line_item (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p.purchase_order_id,
      p.product_id,
      p.quantity
    FROM json_to_record($1) AS p (
      purchase_order_id integer,
      product_id        integer,
      quantity          numeric(10,3)
    )
  ),
  -- Insert into line_item
  line_item AS (
    INSERT INTO pcm.line_item (
      purchase_order_id,
      product_id,
      quanity
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      line_item_id AS "lineItemId",
      purchase_order_id AS "purchaseOrderId",
      product_id AS "productId",
      uom_id AS "uomId",
      created,
      modified
    FROM line_item
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
