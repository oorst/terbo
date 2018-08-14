CREATE OR REPLACE FUNCTION sales.create_quote (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."orderId" AS buyer_id,
      j."createdBy" AS created_by
    FROM json_to_record($1) AS j (
      "orderId"   integer,
      "userId" integer
    )
  ), quote AS (
    INSERT INTO sales.quote (
      order_id,
      created_by
    )
    SELECT
      order_id,
      created_by
    FROM quote
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
