CREATE OR REPLACE FUNCTION works.update_work_center (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE works.work_center SET (%s) = (%s) WHERE work_center_id = ''%s''', c.column, c.value, c.work_center_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'workCenterId')::integer AS work_center_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'productId' THEN 'product_id'
            WHEN 'shortDescription' THEN 'short_desc'
            WHEN 'defaultInstructions' THEN 'default_instructions'
            ELSE p.key
          END AS column,
          CASE
            -- check if it's a number
            WHEN p.value ~ '^\d+(.\d+)?$' THEN
              p.value
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'workCenterId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "workCenterId": %s }', ($1->>'workCenterId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
