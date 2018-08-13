CREATE OR REPLACE FUNCTION sales.create_order (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."buyerId" AS buyer_id,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "buyerId"   integer,
      "userId" integer
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
  ), document AS (
    SELECT
      o.order_id AS "orderId",
      buyer.name AS "buyerName",
      buyer.email
    FROM sales_order o
    INNER JOIN party_v buyer
      USING (buyer_id)
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      *
    FROM document
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
