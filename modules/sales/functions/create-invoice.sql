CREATE OR REPLACE FUNCTION sales.create_invoice (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."userId" AS created_by,
      j."orderId" AS order_id
    FROM json_to_record($1) AS j (
      "userId"  integer,
      "orderId" integer
    )
  ), invoice AS (
    INSERT INTO sales.invoice (
      order_id,
      created_by
    )
    SELECT
      p.order_id,
      p.created_by
    FROM payload p
    INNER JOIN sales.order o
      USING (order_id)
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId",
      i.order_id AS "orderId",
      i.status,
      i.created,
      p.party_id AS "creatorId",
      p.name AS "creatorName"
    FROM invoice i
    INNER JOIN person p
      ON p.party_id = i.created_by
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
