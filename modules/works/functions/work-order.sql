CREATE OR REPLACE FUNCTION works.work_order (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      w.work_order_id AS "workOrderId",
      w.parent_id AS "parentId",
      w.product_id AS "serviceId",
      w.order_id AS "orderId",
      w.status,
      w.instructions AS "instructions",
      w.created,
      w.modified
    FROM works.work_order w
    WHERE w.work_order_id = ($1->>'workOrderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
