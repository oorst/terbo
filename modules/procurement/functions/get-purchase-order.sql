CREATE OR REPLACE FUNCTION pcm.get_purchase_order (json, OUT result json) AS
$$
BEGIN
  WITH purchase_order AS (
    SELECT
      po.*
    FROM pcm.purchase_order po
    WHERE po.purchase_order_id = ($1->>'purchaseOrderId')::integer
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.quantity,
      li.product_id AS "productId",
      pv.name,
      pv.code,
      pv.short_desc AS "shortDescription"
    FROM pcm.line_item li
    INNER JOIN purchase_order
      USING (purchase_order_id)
    INNER JOIN prd.product_list_v pv
      USING (product_id)
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      po.purchase_order_num AS "purchaseOrderNumber",
      po.order_id AS "orderId",
      po.supplier_id AS "supplierId",
      po.status,
      po.data,
      po.created,
      po.modified,
      (SELECT json_agg(li) FROM line_item li) AS "lineItems",
      pvs.name AS "supplierName",
      pvc.name AS "createdByName"
    FROM purchase_order po
    LEFT JOIN party_v pvs
      ON pvs.party_id = po.supplier_id
    LEFT JOIN party_v pvc
      ON pvc.party_id = po.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql';
