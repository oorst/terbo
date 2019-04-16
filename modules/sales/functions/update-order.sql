CREATE OR REPLACE FUNCTION sales.update_order (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE sales.order SET (%s) = (%s) WHERE order_id = ''%s''', c.column, c.value, c.order_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'order_id')::integer AS order_id
      FROM (
        SELECT
          p.key AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'order_id'
      ) q
    ) c
  );

  SELECT format('{ "order_id": %s, "ok": true }', $1->>'order_id')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

-- CREATE OR REPLACE FUNCTION sales.update_order_tg () RETURN TRIGGER AS
-- $$
-- BEGIN
--   -- When status changes from `PENDING` to 'IN_PROGRESS', the order has been
--   -- submitted.  Create all necessary work_orders, purchase_orders and
--   -- inventory requisitions for order boq
--   IF (OLD.status = 'PENDING') AND (NEW.status = 'IN_PROGESS') THEN
--     works.create_work_orders(OLD.order_id);
--     -- TODO prc.create_purchase_orders(OLD.order_id);
--     -- TODO prc.create_purchase_orders(OLD.order_id);
--   END IF;
-- END
-- $$
-- LANGUAGE 'plpgsql';
