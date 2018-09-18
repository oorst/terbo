CREATE OR REPLACE FUNCTION pcm.purchase_order (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      po.order_id AS "orderId",
      po.issued_to AS "issuedToId",
      po.status,
      po.data,
      po.created_by AS "createdBy",
      po.created,
      po.modified,
      pv.name
    FROM pcm.purchase_order po
    LEFT JOIN party_v pv
      ON pv.party_id = po.issued_to
    WHERE po.purchase_order_id = ($1->>'purchaseOrderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
