CREATE OR REPLACE FUNCTION prj.deliverables (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      d.deliverable_id AS "deliverableId",
      i.item_uuid AS "itemUuid",
      i.name
    FROM prj.deliverable d
    INNER JOIN scm.item i
      USING (item_uuid)
    WHERE d.job_id = ($1->>'jobId')::integer
    ORDER BY d.seq_num
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
