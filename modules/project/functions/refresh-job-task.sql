/**
Insert or update task info into scm.task_item

This function will also delete tasks from the queue if the item they correspond
to does not have an entry in the job.
*/

CREATE OR REPLACE FUNCTION prj.refresh_job_task (json, OUT result json) AS
$$
BEGIN
  WITH new_job_item_task AS (
    INSERT INTO scm.task_item (
      batch_uuid,
      item_uuid,
      task_id,
      sorting_num
    )
    SELECT
      j.job_uuid AS batch_uuid,
      fi.item_uuid,
      rt.task_id,
      ROW_NUMBER() OVER (ORDER BY d.seq_num, fi.level DESC, rt.seq_num) AS sorting_num
    FROM prj.flatten_job(9) j
    INNER JOIN prj.deliverable d
      USING (job_id)
    INNER JOIN scm.flatten_item(d.item_uuid) fi
      ON fi.root_uuid = d.item_uuid
    INNER JOIN scm.item i
      ON i.item_uuid = fi.item_uuid
    INNER JOIN scm.route r
      ON r.product_id = i.product_id
    INNER JOIN scm.route_task rt
      ON rt.route_id = r.route_id
    ON CONFLICT (item_uuid, task_id) DO UPDATE SET sorting_num = EXCLUDED.sorting_num
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      count(*) AS tasks
    FROM new_job_item_task
  ) r;
END
$$
LANGUAGE 'plpgsql';
