/**
@function
  This function only updates fields that have an existant corresponding key/value
  in the JSON payload.

  If you want to set a field to NULL then set the corresponding field to `null`
  in the JSON payload.

  @def prd.update_product (json)
  @returns {json}
  @api
*/
CREATE OR REPLACE FUNCTION prd.update_product (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prd.product SET (%s) = (%s) WHERE product_uuid = ''%s''', c.column, c.value, c.product_uuid)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'product_uuid')::uuid AS product_uuid
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
        WHERE p.key != 'product_id'
      ) q
    ) c
  );

  SELECT prd.product(($1->>'product_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
