/*
Return a list of all Routes in alphabetical order
*/

CREATE OR REPLACE FUNCTION scm.list_routes (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      r.route_id AS "routeId",
      p.name,
      p.code
    FROM scm.route r
    INNER JOIN prd.product_list_v p
      USING (product_id)
    ORDER BY p.name
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
