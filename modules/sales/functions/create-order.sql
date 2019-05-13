CREATE OR REPLACE FUNCTION sales.create_order (json, OUT result json) AS
$$
BEGIN
  INSERT INTO sales.order (
    customer_uuid
  )
  SELECT
    p.buyer_uuid
  FROM json_to_record($1) AS p (
    customer_uuid uuid
  );
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
