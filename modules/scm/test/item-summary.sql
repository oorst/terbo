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
  SELECT *
  FROM boq
  INNER JOIN prd.product_v pr
    USING (product_id)
)
SELECT
  *
FROM q;
