/*
List Orders related to a Project
*/

CREATE OR REPLACE FUNCTION prj.list_orders (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      o.order_id AS "orderId",
      o.nickname
    FROM sales.order o
    INNER JOIN prj.project_order p
      USING (order_id)
    WHERE p.project_id = ($1->>'projectId')::integer
    ORDER BY o.order_id DESC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
