CREATE OR REPLACE FUNCTION sales.create_invoice (json, OUT result json) AS
$$
DECLARE
  new_invoice_uuid uuid;
  the_order sales.order;
BEGIN
  -- Select the order from which to create the invoice
  SELECT INTO the_order
    *
  FROM sales.order o
  WHERE o.order_uuid = ($1->>'order_uuid')::uuid;

  -- Create a new invoice
  INSERT INTO ar.invoice (
    payor_uuid,
    contact_uuid,
    due_date
  ) VALUES (
    the_order.customer_uuid,
    the_order.contact_uuid,
    CURRENT_TIMESTAMP + ('30 days')::interval
  )
  RETURNING invoice_uuid INTO new_invoice_uuid;
  
  -- Set the document origin and approval_status
  UPDATE core.document d SET (
    origin,
    approval_status
  ) = ('sales', 'DRAFT')
  WHERE d.document_uuid = new_invoice_uuid;
  
  -- Update the order with the new invoice_uuid
  UPDATE sales.order o SET invoice_uuid = new_invoice_uuid
  WHERE o.order_uuid = the_order.order_uuid;

  UPDATE ar.invoice_detail id SET (
    invoice_uuid,
    name,
    short_desc,
    amount_payable
  ) = (
    new_invoice_uuid,
    li.name,
    li.short_desc,
    (li.total * 1.1)::numeric(10,2) -- Todo taxes properly
  )
  FROM sales.line_items(the_order.order_uuid) li
  WHERE id.detail_uuid = li.line_item_uuid;

  SELECT sales.order(($1->>'order_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
