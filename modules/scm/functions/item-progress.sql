CREATE OR REPLACE FUNCTION scm.item_progress (uuid) RETURNS TABLE (
  item_uuid           uuid,
  percent_complete    integer,
  finished_task_count integer,
  total_task_count    integer
) AS
$$
BEGIN
  RETURN QUERY
  SELECT
    $1,
    floor(r.finished::numeric / r.total::numeric * 100)::integer AS percent_complete,
    r.finished AS finished_task_count,
    r.total AS total_task_count
  FROM (
    SELECT
      count(q.finished_at)::integer AS finished,
      count(*)::integer AS total
    FROM scm.flatten_item($1)
    INNER JOIN scm.task_queue_v q
      USING (item_uuid)
  ) r
  WHERE r.total > 0;
END
$$
LANGUAGE 'plpgsql';
