CREATE OR REPLACE FUNCTION pcm.update_purchase_order (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE pcm.purchase_order SET (%s) = (%s) WHERE purchase_order_id = ''%s''', c.column, c.value, c.purchase_order_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'purchaseOrderId')::integer AS purchase_order_id
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
        WHERE p.key != 'purchaseOrderId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "purchaseOrderId": %s }', ($1->>'purchaseOrderId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
