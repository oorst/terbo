CREATE OR REPLACE FUNCTION pcm.line_item (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      li.line_item_id AS "lineItemId",
      li.product_id AS "productId",
      li.quantity,
      pv.name AS "productName",
      pv.code AS "productCode"
    FROM pcm.line_item li
    INNER JOIN prd.product_list_v pv
      USING (product_id)
    WHERE li.purchase_order_id = ($1->>'purchaseOrderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
