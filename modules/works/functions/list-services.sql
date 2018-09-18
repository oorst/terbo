CREATE OR REPLACE FUNCTION works.list_services (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      s.work_center_id AS "workCenterId",
      s.product_id AS "productId",
      p.name
    FROM works.service s
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE s.work_center_id = ($1->>'workCenterId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
