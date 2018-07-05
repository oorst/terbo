/**
Items can be hirarchical so they should be flattened first.

The strategy here is to construct a set of records representing boq_lines then
insert.

This returns every newly created item.  If you need the root item, then select
record which has a null parent from the record set.
*/

CREATE OR REPLACE FUNCTION scm.insert_item (json) RETURNS SETOF scm.item AS
$$
BEGIN
  -- Flatten the item and sub items into a set of items
  RETURN QUERY
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
    FROM scm.flatten_item($1, TRUE) i  -- Create new uuids here, hence TRUE
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
  -- Insert task instances and BoQs where an item has a boq
  task_instance AS (
    INSERT INTO scm.task_instance (
      task_id,
      item_uuid
    )
    SELECT
      task.task_id,
      task.item_uuid
    FROM task
    INNER JOIN item
      USING (item_uuid)
    WHERE item.boq IS NOT NULL
    RETURNING *
  ),
  -- Select boq line data from items that have provided a boq
  item_boq_line AS (
    SELECT
      ti.boq_id,
      p.product_id,
      li.quantity
    FROM task_instance ti
    -- Need the item for it's boq and product_id
    INNER JOIN item
      USING (item_uuid)
    -- Get the route
    INNER JOIN scm.product_route productRoute
      USING (product_id)
    -- Need route_task for seq_num
    INNER JOIN scm.route_task rt
      ON ti.task_id = rt.task_id AND productRoute.route_id = rt.route_id
    INNER JOIN json_each(item.boq) item_boq
      ON rt.seq_num = (item_boq.key)::text::integer
    CROSS JOIN json_to_recordset(item_boq.value) AS
      li(code text, ref text, quantity numeric(10,3))
    LEFT JOIN prd.ref ref
      ON ref.name = li.ref
    LEFT JOIN prd.product_ref pref
      USING (ref_id)
    INNER JOIN prd.product p
      ON pref.product_id = p.product_id OR li.code = p.code
    WHERE item.boq IS NOT NULL
  ),
  boq_line AS (
    INSERT INTO scm.boq_line (
      boq_id,
      product_id,
      quantity
    )
    SELECT * FROM item_boq_line
  )
  SELECT *
  FROM new_item;

END
$$
LANGUAGE 'plpgsql';
