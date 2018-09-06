CREATE OR REPLACE FUNCTION scm.create_route (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j.name,
      j."productId" AS product_id,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      name        text,
      "productId" integer,
      "userId"    integer
    )
  ), new_route AS (
    INSERT INTO scm.route (
      name,
      product_id,
      created_by
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      rt.route_id AS "routeId",
      rt.name
    FROM new_route rt
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
