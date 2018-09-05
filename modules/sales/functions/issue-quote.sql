/*
Convert a `DRAFT` quote to `ISSUED`.

Save the current state of the corresponding order line items into a JSON
document and save to the quote data.

Data from an `ISSUED` quote will be taken from the quote data and not the
corresponding order.
*/

CREATE OR REPLACE FUNCTION sales.issue_quote (json, OUT result json) AS
$$
DECLARE
  _quote_id integer := ($1->>'quoteId')::integer;
BEGIN
  UPDATE sales.quote q SET (
    issued_at,
    status,
    expiry_date,
    data
  ) = (
    CURRENT_TIMESTAMP,
    'ISSUED',
    (CURRENT_TIMESTAMP + (INTERVAL '1 day') * q.period)::date,
    (
      SELECT json_strip_nulls(json_agg(r))
      FROM (
        SELECT
          li.line_item_id AS "lineItemId",
          li.product_id AS "productId",
          li.position,
          li.name,
          li.code,
          li.short_desc AS "shortDescription",
          li.gross,
          li.line_total AS "lineTotal",
          li.quantity,
          li.data
        FROM sales.quote q
        INNER JOIN sales.line_item_v li
          ON li.order_id = q.order_id
        WHERE q.quote_id = _quote_id
        ORDER BY li.position, li.line_item_id ASC
      ) r
    )
  )
  WHERE q.quote_id = _quote_id;

  SELECT format('{ "quoteId": %s, "ok": true }', _quote_id)::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
