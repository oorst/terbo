/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.create_line_item (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."purchaseOrderId" AS purchase_order_id,
      j."productId" AS product_id
    FROM json_to_record($1) AS j (
      "purchaseOrderId" integer,
      "productId"       integer
    )
  ),
  -- Insert into line_item
  line_item AS (
    INSERT INTO pcm.line_item (
      purchase_order_id,
      product_id
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
