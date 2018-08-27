CREATE OR REPLACE FUNCTION sales.issue_invoice (json, OUT result json) AS
$$
BEGIN
  WITH line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.product_id AS "productId"
    FROM sales.invoice i
    INNER JOIN sales.order o
      USING (order_id)
    INNER JOIN sales.line_item li
      ON li.order_id = o.order_id
    INNER JOIN prd.product p
      USING (product_id)
    INNER JOIN prd.price_v price
      ON price.product_id = li.product_id
  ), invoice AS (
    UPDATE sales.invoice i SET (
      issued_at,
      status,
      due_date,
      data
    ) = (
      (CURRENT_TIMESTAMP)::timestamp(0),
      'ISSUED',
      (CURRENT_TIMESTAMP + (INTERVAL '1 day') * i.period)::date,
      json_build_object(
        'lineItems',
        (SELECT json_agg(li) FROM line_item li)
      )
    )
    WHERE i.invoice_id = ($1->>'invoiceId')::integer
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      order_id AS "orderId",
      invoice_id AS "invoiceId",
      status,
      due_date AS "dueDate",
      (SELECT json_agg(li) FROM line_item li) AS "lineItems"
    FROM invoice
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
