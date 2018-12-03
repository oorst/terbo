CREATE OR REPLACE FUNCTION sales.confirm_order (json, OUT result  json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
     "orderId" AS order_id,
     "userId" AS user_id
    FROM json_to_record($1) AS j (
      "orderId" integer,
      "userId"  integer
    )
  ), invoice AS (
    INSERT INTO sales.invoice (
      order_id,
      created_by,
      data
    )
    SELECT
      p.order_id,
      p.user_id,
      jsonb_build_object(
        'lineItems',
        (SELECT jsonb_agg(r) FROM sales.line_item(p.order_id) r)
      )
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
