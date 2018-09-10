CREATE OR REPLACE FUNCTION sales.order (json, OUT result json) AS
$$
BEGIN
SELECT json_strip_nulls(to_json(r)) INTO result
FROM (
  SELECT
    o.order_id AS "orderId",
    o.buyer_id AS "buyerId",
    p.name AS "buyerName",
    o.status,
    o.data,
    o.notes,
    o.purchase_order_num AS "purchaseOrderNumber",
    o.short_desc AS "shortDescription",
    o.created
  FROM sales.order o
  LEFT JOIN party_v p
    ON p.party_id = o.buyer_id
  WHERE o.order_id = ($1->>'orderId')::integer
) r;
END
$$
LANGUAGE 'plpgsql';
