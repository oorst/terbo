CREATE OR REPLACE FUNCTION scm.route (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      route.route_id AS "routeId",
      route.name,
      route.product_id AS "productId",
      p.name AS "productName",
      p.code AS "productCode"
    FROM scm.route route
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE route.route_id = ($1->>'routeId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
