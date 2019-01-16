CREATE OR REPLACE FUNCTION prj.create_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."projectId" AS project_id,
      p."buyerId" AS buyer_id,
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "projectId" integer,
      "buyerId"   integer,
      "userId"    integer
    )
  ), sales_order AS (
    INSERT INTO sales.order (
      buyer_id,
      created_by
    )
    SELECT
      p.buyer_id,
      p.created_by
    FROM payload p
    RETURNING *
  ), project_order AS (
    INSERT INTO prj.project_order (
      project_id,
      order_id
    ) VALUES (
      (SELECT project_id FROM payload),
      (SELECT order_id FROM sales_order)
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      order_id AS "orderId"
    FROM sales_order
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
