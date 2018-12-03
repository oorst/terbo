/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION scm.update_component (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE scm.component SET (%s) = (%s) WHERE component_id = %s', c.column, c.value, c.component_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'componentId')::integer AS component_id
      FROM (
        SELECT
        CASE p.key
          WHEN 'uomId' THEN 'uom_id'
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
        -- Can't update product_id directly on component.  Need to update on item
        WHERE p.key != 'componentId' AND p.key != 'productId' AND p.key != 'userId'
      ) q
    ) c
  );

  -- IF $1->>'productId' IS NOT NULL THEN
  --   WITH component AS (
  --     SELECT
  --       *
  --     FROM scm.component
  --     WHERE component_id = ($1->>'componentId')::integer
  --   )
  --   UPDATE scm.item i SET product_id = ($1->>'productId')::integer
  --   FROM component c
  --   WHERE i.item_uuid = c.item_uuid;
  -- END IF;

  SELECT format('{ "componentId": %s, "ok": true }', ($1->>'componentId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
