CREATE OR REPLACE FUNCTION sales.create_order (json, OUT result json) AS
$$
DECLARE
  _customer_uuid uuid := ($1->>'customer_uuid')::uuid;
  new_order_uuid uuid;
BEGIN
  IF NOT EXISTS(SELECT FROM sales.customer WHERE customer_uuid = _customer_uuid) THEN
    INSERT INTO sales.customer (customer_uuid) VALUES (_customer_uuid);
  END IF;

  INSERT INTO sales.order (
    customer_uuid
  ) VALUES (
    _customer_uuid
  )
  RETURNING order_uuid INTO new_order_uuid;
  
  SELECT sales.order(new_order_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
