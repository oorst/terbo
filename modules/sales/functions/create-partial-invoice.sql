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
      p."shortDescription",
      p."grossLineTotal",
      p."netLineTotal",
      p."userId" AS created_by
    FROM json_to_record($1) AS p (
      "invoiceId"        integer, -- The parent invoice for which a partial invoice is created
      name               text,
      "shortDescription" text,
      "grossLineTotal"   numeric(10,2),
      "netLineTotal"     numeric(10,2),
      "userId"           integer
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
      p."shortDescription",
      -- Gross line total
      CASE
        WHEN p."grossLineTotal" IS NOT NULL THEN
          p."grossLineTotal"
        ELSE (p."netLineTotal" * 0.90909)::numeric(10,2) -- TODO get rid of this!
      END AS "grossLineTotal",
      -- Net line total
      CASE
        WHEN p."netLineTotal" IS NOT NULL THEN
          p."netLineTotal"
        ELSE (p."grossLineTotal" * 1.1)::numeric(10,2)
      END AS "netLineTotal"
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
        'lineItems',
        jsonb_build_array(
          jsonb_build_object(
            'name', li.name,
            'shortDescription', li."shortDescription",
            'grossLineTotal', li."grossLineTotal",
            'netLineTotal', li."netLineTotal"
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
