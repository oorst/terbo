CREATE OR REPLACE FUNCTION sales.create_quote (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."orderId" AS order_id,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "orderId"   integer,
      "userId" integer
    )
  ), quote AS (
    INSERT INTO sales.quote (
      order_id,
      data,
      created_by
    )
    SELECT
      order_id,
      (SELECT jsonb_strip_nulls(jsonb_agg(r)) FROM sales.line_items(($1->>'orderId')::integer) r),
      created_by
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      quote_id AS "quoteId"
    FROM quote
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
