CREATE OR REPLACE FUNCTION sales.create_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."buyerId" AS buyer_id,
      j."createdBy" AS created_by
    FROM json_to_record($1) AS j (
      "buyerId"   integer,
      "createdBy" integer
    )
  ), sales_order AS (
    INSERT INTO sales.order (
      buyer_id,
      created_by
    )
    SELECT
      buyer_id,
      created_by
    FROM payload
    RETURNING *
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
