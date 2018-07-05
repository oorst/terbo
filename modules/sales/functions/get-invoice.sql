CREATE OR REPLACE FUNCTION sales.get_invoice (integer, OUT result json) AS
$$
BEGIN
  WITH line_items AS (
    SELECT *
    FROM sales.line_item
    WHERE invoice_id = $1
  ), _totals AS (
    SELECT
      CASE
        WHEN net_price IS NOT NULL THEN
          (net_price * 0.909091)::numeric(10,2)
        ELSE gross_price
      END AS gross_price,
      CASE
        WHEN tax IS FALSE THEN
          gross_price
        WHEN net_price IS NOT NULL THEN
          net_price
        ELSE
          gross_price * 1.1
      END AS net_price
    FROM line_items
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      invoice_num AS "invoiceNumber",
      get_party(issued_to) AS "issuedTo",
      issued_at AS "issuedAt",
      due_date AS "dueDate",
      data,
      (SELECT json_agg(sales.get_line_item(line_item_id)) FROM line_items) AS "lineItems",
      (
        SELECT to_json(r)
        FROM (
          SELECT
            (SUM(gross_price))::text AS "grossPrice",
            (SUM(net_price))::text AS "netPrice",
            (SUM(net_price) - SUM(gross_price))::text AS "gst"
          FROM _totals
        ) r
      ) AS totals
    FROM sales.invoice
    WHERE invoice_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.get_invoice (json, OUT result json) AS
$$
BEGIN
  SELECT
    sales.get_invoice(invoice_id) INTO result
  FROM sales.invoice
  WHERE invoice_num = $1->>'invoiceNumber';
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
