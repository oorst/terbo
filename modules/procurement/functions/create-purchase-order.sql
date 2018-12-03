/*
Create the necessary purchase orders for a sales.order.
*/

CREATE OR REPLACE FUNCTION pcm.create_purchase_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."supplierId" AS supplier_id,
      p."purchaseOrderNumber" AS purchase_order_num,
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "supplierId"          integer,
      "purchaseOrderNumber" text,
      "userId"              integer
    )
  ), purchase_order AS (
    INSERT INTO pcm.purchase_order (
      supplier_id,
      purchase_order_num,
      created_by
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      po.purchase_order_id AS "purchaseOrderId",
      pv.name AS "supplierName"
    FROM purchase_order po
    INNER JOIN party_v pv
      ON pv.party_id = po.supplier_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
