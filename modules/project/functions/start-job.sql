/**
Start a job by inserting all deliverables' tasks into the scm.task_item queue
*/

CREATE OR REPLACE FUNCTION prj.start_job (json, OUT result json) AS
$$
BEGIN
  INSERT INTO scm.task_item (
    item_uuid,
    task_id
  )
  SELECT
    fi.item_uuid,
    rt.task_id
  FROM prj.flatten_job(($1->>'jobId')::integer)
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
  ORDER BY d.seq_num, fi.level DESC, rt.seq_num
  ON CONFLICT DO NOTHING;

  UPDATE prj.job j
  SET status = 'WIP'::job_status_t
  WHERE j.job_id = ($1->>'jobId')::integer;

  SELECT to_json(r) INTO result
  FROM (
    SELECT
      TRUE AS ok
  ) r;
END
$$
LANGUAGE 'plpgsql';
