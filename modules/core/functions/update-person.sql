CREATE OR REPLACE FUNCTION update_person (json, OUT result json) AS
$$
BEGIN
  EXECUTE (
    SELECT
      format('UPDATE person SET (%s) = (%s) WHERE party_id = ''%s''', c.column, c.value, c.party_id)
    FROM (
      SELECT
        string_agg(q.column, ', ') AS column,
        string_agg(q.value, ', ') AS value,
        ($1->>'partyId')::integer AS party_id
      FROM (
        SELECT
          CASE p.key
            WHEN 'addressId' THEN 'address_id'
            WHEN 'billingAddressId' THEN 'billing_address_id'
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
        WHERE p.key != 'partyId'
      ) q
    ) c
  );

  SELECT format('{ "ok": true, "partyId": %s }', ($1->>'partyId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
