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
CREATE OR REPLACE FUNCTION update_organisation (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE organisation SET (%s) = (%s) WHERE party_id = ''%s''', c.column, c.value, c.party_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'partyId')::integer AS party_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'tradingName' THEN 'trading_name'
            WHEN 'addressId' THEN 'address_id'
            WHEN 'billingAddressId' THEN 'billing_address_id'
            WHEN 'industryCode' THEN 'industry_code'
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
        WHERE p.key != 'partyId' AND p.key != 'type'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "partyId": %s }', ($1->>'partyId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
