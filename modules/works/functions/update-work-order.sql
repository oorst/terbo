CREATE OR REPLACE FUNCTION works.update_work_order (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE works.work_order SET (%s) = (%s) WHERE work_order_id = ''%s''', c.column, c.value, c.work_order_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'workOrderId')::integer AS work_order_id
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
        WHERE p.key != 'workOrderId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "workOrderId": %s }', ($1->>'workOrderId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
