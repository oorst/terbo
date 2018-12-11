/**
Insert all the tasks from an item's route into the item task queue
*/
CREATE OR REPLACE FUNCTION scm.enqueue_item (uuid) RETURNS VOID AS
$$
BEGIN
  INSERT INTO scm.task_item (
    item_uuid,
    task_id
  )
  SELECT
    fi.item_uuid,
    rt.task_id
  FROM scm.flatten_item($1) fi
  INNER JOIN scm.item i
    ON i.item_uuid = fi.item_uuid
  INNER JOIN scm.route r
    ON r.product_id = i.product_id
  INNER JOIN scm.route_task rt
    ON rt.route_id = r.route_id
  ORDER BY fi.level DESC, rt.seq_num
  ON CONFLICT DO NOTHING;
END
$$
LANGUAGE 'plpgsql';
