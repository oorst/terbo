/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.approve_purchase_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."purchaseOrderId" AS purchase_order_id,
      p."userId" AS approved_by
    FROM json_to_record($1) AS p (
      "purchaseOrderId" integer,
      "userId"          integer
    )
  ), purchase_order AS (
    UPDATE pcm.purchase_order po SET (
      status,
      approved_by
    ) = (
      'ISSUED'::purchase_order_status_t,
      p.approved_by
    )
    FROM payload p
    WHERE po.purchase_order_id = p.purchase_order_id
    RETURNING po.*
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      po.status
    FROM purchase_order po
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
