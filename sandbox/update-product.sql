SELECT
  format('UPDATE scm.item SET (%s) = (%s) WHERE item_uuid = ''%s''', c.column, c.value, c.uuid)
FROM (
  SELECT
    string_agg(q.column, ', ') AS column,
    string_agg(q.value, ', ') AS value,
    '2e538894-27c3-4e21-909e-fc3ef59610c6'::uuid AS uuid
  FROM (
    SELECT
      CASE p.key
        WHEN 'productId' THEN 'product_id'
        ELSE p.key
      END AS column,
      CASE
        -- check if it's a number
        WHEN p.value ~ '^\d+(.\d+)?$' THEN
          p.value
        WHEN p.value IS NULL THEN
          NULL
        ELSE quote_literal(p.value)
      END AS value
    FROM json_each_text('{"uuid": "2e538894-27c3-4e21-909e-fc3ef59610c6", "productId": 45, "name": "nooch", "foo": null }'::json) p
    WHERE p.key != 'uuid'
  ) q
) c;
