/**
A partial invoice contains a single line item which is the payment amount.
*/
CREATE OR REPLACE FUNCTION sales.create_partial_invoice (json, OUT result json) AS
$$
DECLARE
  _invoice_id integer;
BEGIN
  WITH payload AS (
    SELECT
      p."invoiceId" AS invoice_id,
      p.name,
      p."shortDesc" AS short_desc,
      p."totalGross" AS total_gross,
      p."totalPrice" AS total_price,
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "invoiceId"  integer, -- The parent invoice for which a partial invoice is created
      name         text,
      "shortDesc"  text,
      "totalGross" numeric(10,2),
      "totalPrice" numeric(10,2),
      "userId"     integer
    )
  ),
  -- Gt the parent invoice
  parent_invoice AS (
    SELECT
      i.*
    FROM sales.invoice i
    INNER JOIN payload p
      ON p.invoice_id = i.invoice_id
  ),
  -- Create a line item record
  line_item AS (
    SELECT
      p.name,
      p.short_desc,
      -- Gross line total
      CASE
        WHEN p.total_gross IS NOT NULL THEN
          p.total_gross
        ELSE (p.total_price * 0.90909)::numeric(10,2) -- TODO get rid of this!
      END AS total_gross,
      -- Net line total
      CASE
        WHEN p.total_price IS NOT NULL THEN
          p.total_price
        ELSE (p.total_gross * 1.1)::numeric(10,2)
      END AS total_price
    FROM payload p
  ),
  -- Create the child invoice
  child_invoice AS (
    INSERT INTO sales.invoice (
      order_id,
      recipient_id,
      data,
      created_by
    )
    SELECT
      (SELECT order_id FROM parent_invoice),
      (SELECT recipient_id FROM parent_invoice),
      json_build_object(
        'line_items',
        jsonb_build_array(
          jsonb_build_object(
            'name', li.name,
            'short_desc', li.short_desc,
            'total_gross', li.total_gross,
            'total_price', li.total_price
          )
        )
      ),
      (SELECT created_by FROM payload)
    FROM line_item li
    RETURNING invoice_id
  ),
  -- Create the partial invoice record
  partial_invoice AS (
    INSERT INTO sales.partial_invoice (
      parent_id,
      invoice_id
    ) VALUES (
      (SELECT invoice_id FROM parent_invoice),
      (SELECT invoice_id FROM child_invoice)
    )
  )
  SELECT invoice_id INTO _invoice_id
  FROM child_invoice;

  SELECT sales.invoice(id => _invoice_id) INTO result;
END
$$
LANGUAGE 'plpgsql';
