CREATE OR REPLACE FUNCTION works.list_work_orders (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      w.work_order_id AS "workOrderId",
      w.order_id AS "orderId",
      w.product_id AS "productId",
      p.name AS "serviceName",
      s.nickname
    FROM works.work_order_list_v w
    INNER JOIN sales.order s
      ON s.order_id = w.order_id
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE w.status = 'AUTHORISED'
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION works.list_work_orders (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      w.work_order_id AS "workOrderId",
      w.order_id AS "orderId",
      w.product_id AS "productId",
      w.status,
      p.name AS "serviceName",
      s.nickname
    FROM works.work_order_list_v w
    INNER JOIN sales.order s
      ON s.order_id = w.order_id
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE
      (($1->>'pending')::boolean IS TRUE AND w.status = 'PENDING')
    OR
      ($1->>'orderId' IS NOT NULL AND w.order_id = ($1->>'orderId')::integer)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
