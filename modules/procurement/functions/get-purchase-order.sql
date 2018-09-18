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
      pv.code
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
      po.order_id AS "orderId",
      po.issued_to AS "issuedToId",
      po.status,
      po.data,
      po.created,
      po.modified,
      (SELECT json_agg(li) FROM line_item li) AS "lineItems",
      pvi.name AS "issuedToName",
      pvc.name AS "createdByName"
    FROM purchase_order po
    LEFT JOIN party_v pvi
      ON pvi.party_id = po.issued_to
    LEFT JOIN party_v pvc
      ON pvc.party_id = po.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql';
