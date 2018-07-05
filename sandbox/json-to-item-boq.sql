WITH item AS (
  SELECT
    i.item_uuid,
    i.parent_uuid,
    i.code,
    pr.product_id,
    prt.route_id,
    task.name,
    task.task_id,
    map.attribute,
    map.code,
    attr.value AS quantity,
    rt.seq_num
  FROM scm.flatten_item((:'test_json')::json) i
  INNER JOIN prd.product pr
    USING (code)
  INNER JOIN scm.product_route prt
    USING (product_id)
  INNER JOIN scm.route_task rt
    USING (route_id)
  INNER JOIN scm.task task
    USING (task_id)
  INNER JOIN scm.task_inst_attr_map map
    USING (task_id)
  INNER JOIN json_each(i.attributes) attr
    ON attr.key = map.attribute
)
SELECT *
  -- q.code,
  -- q.quantity
FROM item;
-- CROSS JOIN json_each(item.boq) item_boq
-- CROSS JOIN json_to_recordset(item_boq.value) AS
--   q(code text, quantity numeric(10,3));
