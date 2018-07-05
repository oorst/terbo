\set test_json `cat insert-item.json`
\i ../functions/insert-item.sql


WITH item AS (
  SELECT
    i.item_uuid,
    i.parent_uuid,
    i.code,
    i.id,
    i.data,
    i.boq,
    i.attributes,
    pr.product_id
  FROM scm.flatten_item(:'test_json') i
  INNER JOIN prd.product pr
    USING (code)
),
-- Insert new items
new_item AS (
  INSERT INTO scm.item (
    item_uuid,
    parent_uuid,
    product_id,
    id,
    data
  ) (
    SELECT
      item_uuid,
      parent_uuid,
      product_id,
      id,
      data
    FROM item
  ) RETURNING *
),
-- Collect tasks and join item.item_id, item.uuid and route_id
task AS (
  SELECT
    item.item_uuid,
    route.route_id,
    t.*
  FROM new_item item
  INNER JOIN scm.product_route route
    USING (product_id)
  INNER JOIN scm.route_task
    USING (route_id)
  INNER JOIN scm.task t
    USING (task_id)
),
-- Insert task instances and BoQs where an item has a boq or attributes
task_instance AS (
  INSERT INTO scm.task_instance (
    task_id,
    item_uuid
  ) (
    SELECT
      task.task_id,
      task.item_uuid
    FROM task
    INNER JOIN item
      USING (item_uuid)
    WHERE item.boq IS NOT NULL OR item.attributes IS NOT NULL
  ) RETURNING *
),
-- Select boq line data from items that have provided a boq
item_boq_line AS (
  SELECT
    ti.boq_id,
    pr.product_id,
    quantity
  FROM task_instance ti
  -- Need the item for it's boq and product_id
  INNER JOIN item
    USING (item_uuid)
  -- Need route_task for seq_num
  INNER JOIN scm.route_task rt
    USING (task_id)
  INNER JOIN json_each(item.boq) item_boq
    ON rt.seq_num = (item_boq.key)::text::integer
  CROSS JOIN json_to_recordset(item_boq.value) AS
    boq(code text, quantity numeric(10,3))
  INNER JOIN prd.product pr
    ON boq.code = pr.code
  WHERE item.boq IS NOT NULL
),
-- Select boq line data from items that have provided attributes
item_attr_boq_line AS (
  SELECT
    ti.boq_id,
    pr.product_id,
    (attr.value)::numeric(10,3)
  FROM task_instance ti
  INNER JOIN scm.task_inst_attr_map map
    USING (task_id)
  INNER JOIN prd.product pr
    ON map.code = pr.code
  INNER JOIN item
    USING (item_uuid)
  INNER JOIN json_each_text(item.attributes) attr
    ON map.attribute = attr.key
), boq_line AS (
  INSERT INTO scm.boq_line (
    boq_id,
    product_id,
    quantity
  )
  SELECT * FROM item_boq_line
  UNION ALL
  SELECT * FROM item_attr_boq_line
  RETURNING *
)
SELECT *
FROM item
WHERE item.parent_uuid IS NULL;

SELECT * FROM scm.item;
