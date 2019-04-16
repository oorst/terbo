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
CREATE OR REPLACE FUNCTION prd.update_attribute (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prd.product_attribute SET (%s) = (%s) WHERE attribute_id = ''%s''', c.column, c.value, c.attribute_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'attributeId')::integer AS attribute_id
      FROM (
        SELECT
          p.key AS column,
          CASE
            WHEN p.value IS NULL THEN
              'NULL'
            ELSE quote_literal(p.value)
          END AS value
        FROM json_each_text($1) p
        WHERE p.key != 'attributeId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "attributeId": %s }', ($1->>'attributeId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
