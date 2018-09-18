CREATE OR REPLACE FUNCTION pcm.list_purchase_orders (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      po.order_id AS "salesOrderId",
      po.status,
      p.name
    FROM pcm.purchase_order po
    LEFT JOIN party_v p
      ON p.party_id = po.issued_to
    ORDER BY po.created DESC
    LIMIT 20
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION pcm.list_purchase_orders (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      po.order_id AS "salesOrderId",
      po.status,
      p.name
    FROM pcm.purchase_order po
    INNER JOIN party_v p
      ON p.party_id = po.issued_to
    WHERE
      ($1->>'orderId' IS NOT NULL AND po.order_id = ($1->>'orderId')::integer)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
