CREATE OR REPLACE FUNCTION sales.confirm_order (json, OUT result  json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."orderId" AS order_id,
      p."buyerId" AS recipient_id,
      p."userId" AS user_id
    FROM json_to_record($1) AS p (
      "orderId" integer,
      "buyerId" integer,
      "userId"  integer
    )
  ), invoice AS (
    INSERT INTO sales.invoice (
      order_id,
      recipient_id,
      created_by,
      data
    )
    SELECT
      p.order_id,
      p.recipient_id,
      p.user_id,
      sales.create_document(p.order_id)
    FROM payload p
    RETURNING *
  ), updated_order AS (
    UPDATE sales.order SET (
      status
    ) = (
      'CONFIRMED'::order_status_t
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId"
    FROM invoice i
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
