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
      coalesce(r.name, p.name) AS name,
      p.code
    FROM scm.route r
    INNER JOIN prd.product_list_v p
      USING (product_id)
    ORDER BY p.name
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
