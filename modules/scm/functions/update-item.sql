/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION scm.update_item (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE scm.item SET (%s) = (%s) WHERE item_uuid = ''%s''', c.column, c.value, c.item_uuid)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'itemUuid')::uuid AS item_uuid
      FROM (
        SELECT
          CASE p.key
            WHEN 'productId' THEN 'product_id'
            WHEN 'shortDescription' THEN 'short_desc'
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
        WHERE p.key != 'itemUuid'
      ) q
    ) c
  );

  SELECT format('{ "itemUuid": "%s", "ok": true }', $1->>'itemUuid')::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
