CREATE OR REPLACE FUNCTION sales.create_order (json, OUT result json) AS
$$
DECLARE
  new_order_uuid uuid;
BEGIN
  INSERT INTO sales.order (
    customer_uuid
  )
  SELECT
    p.customer_uuid
  FROM json_to_record($1) AS p (
    customer_uuid uuid
  )
  RETURNING order_uuid INTO new_order_uuid;
  
  SELECT sales.order(new_order_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
