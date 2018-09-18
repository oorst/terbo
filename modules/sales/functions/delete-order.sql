CREATE OR REPLACE FUNCTION sales.delete_order (json, OUT result json) AS
$$
BEGIN
  DELETE FROM sales.order o
  USING json_to_record($1) AS j (
    "orderId" integer
  )
  WHERE o.order_id = j."orderId";

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

-- Do not allow deletion of orders where the order status is anything other
-- than `PENDING`
CREATE OR REPLACE FUNCTION sales.delete_order_tg () RETURNS TRIGGER AS
$$
BEGIN
  IF OLD.status != 'PENDING' THEN
    RAISE EXCEPTION 'cannot delete order';
  END IF;

  RETURN OLD;
END
$$
LANGUAGE 'plpgsql';
