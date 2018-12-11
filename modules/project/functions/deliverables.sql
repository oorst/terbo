/**
Return the deliverables for the given jobId
*/
CREATE OR REPLACE FUNCTION prj.deliverables (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      d.deliverable_id AS "deliverableId",
      i.item_uuid AS "itemUuid",
      i.name,
      d.seq_num AS "sequenceNumber",
      prc.percent_complete AS "percentComplete"
    FROM prj.deliverable d
    INNER JOIN scm.item i
      USING (item_uuid)
    -- Calculate percent completion
    LEFT JOIN LATERAL (
      SELECT
        d.item_uuid,
        floor(r.finished::numeric / r.total::numeric * 100) AS percent_complete
      FROM (
        SELECT
          count(q.finished_at) AS finished,
          count(*) AS total
        FROM scm.flatten_item(d.item_uuid)
        INNER JOIN scm.task_queue_v q
          USING (item_uuid)
      ) r
      WHERE r.total > 0
    ) prc ON prc.item_uuid = d.item_uuid
    WHERE d.job_id = ($1->>'jobId')::integer
    ORDER BY d.seq_num
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
