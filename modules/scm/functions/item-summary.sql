CREATE OR REPLACE FUNCTION scm.item_summary(uuid)
RETURNS TABLE (
  gross numeric(10,2)
) AS
$$
BEGIN
  RETURN QUERY
  WITH item AS (
    SELECT *
    FROM scm.flatten_item($1)
  ), static_boq_line AS (
    SELECT
      bl.*
    FROM item
    INNER JOIN scm.product_route
      USING (product_id)
    INNER JOIN scm.route_task
      USING (route_id)
    INNER JOIN scm.task
      USING (task_id)
    INNER JOIN scm.boq_line bl
      USING (boq_id)
  ), task_instance_boq_line AS (
    SELECT
      bl.*
    FROM item
    INNER JOIN scm.task_instance ti
      USING (item_uuid)
    INNER JOIN scm.boq_line bl
      USING (boq_id)
  ), boq AS (
    SELECT * FROM static_boq_line
    UNION ALL
    SELECT * FROM task_instance_boq_line
  ), q AS (
    SELECT
      boq.quantity * COALESCE(pr.gross, pr.cost * (100 + COALESCE(pr.markup, pr.markup_amount, 0)) / 100) AS total
    FROM boq
    INNER JOIN prd.product_v pr -- Use product_v here to get pricing
      USING (product_id)
  )
  SELECT
    SUM(total) AS gross
  FROM q;
END
$$
LANGUAGE 'plpgsql';
