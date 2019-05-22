CREATE OR REPLACE FUNCTION sales.create_quote (json, OUT result json) AS
$$
DECLARE
  the_order      sales.order;
  customer       sales.customer;
  new_quote_uuid uuid; 
BEGIN
  SELECT INTO the_order
    *
  FROM sales.order o
  WHERE o.order_uuid = ($1->>'order_uuid')::uuid;

  IF the_order IS NULL THEN
    RAISE EXCEPTION 'Order with order_uuid %s not found', $1->>'order_uuid';
    RETURN;
  END IF;

  SELECT INTO customer
    *
  FROM sales.customer c
  WHERE c.customer_uuid = the_order.customer_uuid;

  INSERT INTO sales.quote (
    order_uuid,
    expiry_date
  ) VALUES (
    the_order.order_uuid,
    CURRENT_TIMESTAMP + (customer.quote_period || ' days')::interval
  )
  RETURNING quote_uuid INTO new_quote_uuid;
  
  result = sales.quote(new_quote_uuid);
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
