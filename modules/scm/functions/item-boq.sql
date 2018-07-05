CREATE OR REPLACE FUNCTION scm.item_boq (uuid)
RETURNS TABLE (
  product_id integer,
  quantity   numeric(10,2)
  -- uom_id     integer TODO
) AS
$$
BEGIN
  RETURN QUERY
  -- Flatten the item to get any nested items
  WITH item AS (
    SELECT
      i.*,
      r.route_id
    FROM scm.flatten_item($1) i
    INNER JOIN scm.product_route r
      USING (product_id)
  ),
  -- Get tasks for any static BOQ
  task_boq AS (
    SELECT t.*
    FROM item
    INNER JOIN scm.route_task
      USING (route_id)
    INNER JOIN scm.task t
      USING (task_id)
  ),
  -- Get task instance BOQs
  task_instance_boq AS (
    SELECT ti.*
    FROM item
    INNER JOIN scm.task_instance ti
      USING (item_uuid)
  ),
  -- Union BOQs
  boq AS (
    SELECT boq_id
    FROM task_boq

    UNION ALL

    SELECT boq_id
    FROM task_instance_boq
  )
  SELECT
    l.product_id,
    l.quantity
  FROM boq
  INNER JOIN scm.boq_line l
    USING (boq_id);
END
$$
LANGUAGE 'plpgsql';
