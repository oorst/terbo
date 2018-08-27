CREATE OR REPLACE FUNCTION sales.get_invoices (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."orderId" AS order_id
    FROM json_to_record($1) AS j (
      "orderId" integer
    )
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.order_id AS "orderId",
      i.invoice_id AS "invoiceId",
      i.invoice_num AS "invoiceNumber",
      i.status,
      i.issued_at AS "issuedAt"
    FROM payload p
    INNER JOIN sales.invoice i
      USING (order_id)
  ) r;
END
$$
LANGUAGE 'plpgsql';
