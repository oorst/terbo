CREATE OR REPLACE FUNCTION works.list_work_centers (OUT result json) AS
$$
BEGIN
  -- Aggregate the services performed b the work center into a JSON array
  WITH services AS (
    SELECT
      s.work_center_id,
      json_agg(s.product_id) AS services
    FROM works.service s
    GROUP BY work_center_id
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      w.work_center_id AS "workCenterId",
      w.name,
      w.short_desc AS "shortDescription",
      s.services
    FROM works.work_center w
    LEFT JOIN services s
      USING (work_Center_id)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
