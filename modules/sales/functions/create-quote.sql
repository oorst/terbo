CREATE OR REPLACE FUNCTION sales.create_quote (json, OUT result json) AS
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
  ), quote AS (
    INSERT INTO sales.quote (
      order_id,
      created_by
    )
    SELECT
      order_id,
      created_by
    FROM sales_order
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      order_id AS "quoteId"
    FROM quote
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
