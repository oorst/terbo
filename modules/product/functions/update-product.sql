/**
@function
  This function only updates fields that have an existant corresponding key/value
  in the JSON payload.

  If you want to set a field to NULL then set the corresponding field to `null`
  in the JSON payload.

  When cost or pricing is included a new cost and/or price record is created to
  maintain a history.

  @def prd.update_product (json)
  @returns {json}
  @api
*/
CREATE OR REPLACE FUNCTION prd.update_product (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE prd.product SET (%s) = (%s) WHERE product_id = ''%s''', c.column, c.value, c.product_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'productId')::integer AS product_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'familyId' THEN 'family_id'
            WHEN 'shortDescription' THEN 'short_desc'
            WHEN 'manufacturerId' THEN 'manufacturer_id'
            WHEN 'supplierId' THEN 'supplier_id'
            WHEN 'manufacturerCode' THEN 'manufacturer_code'
            WHEN 'supplierCode' THEN 'supplier_code'
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
        WHERE p.key != 'productId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "productId": %s }', ($1->>'productId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
