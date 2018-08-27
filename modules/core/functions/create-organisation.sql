CREATE OR REPLACE FUNCTION create_organisation (json, OUT result json) AS
$$
BEGIN
  WITH payload_organisation AS (
    SELECT
      o.name,
      o."tradingName" AS trading_name,
      o.data,
      o.url
    FROM json_to_record($1) AS o (
      name          text,
      "tradingName" text,
      data          jsonb,
      url           text
    )
  ), payload_address AS (
    INSERT INTO address (
      addr1,
      addr2,
      town,
      state,
      code,
      type
    )
    SELECT
      addr1,
      addr2,
      town,
      state,
      code,
      ("addressType")::smallint AS type
    FROM json_to_record($1) AS a (
      addr1 text,
      addr2 text,
      town  text,
      state text,
      code  text,
      "addressType" text
    )
    WHERE NOT (a is NULL)
    RETURNING *
  ), billing_address AS (
    INSERT INTO address (
      addr1,
      addr2,
      town,
      state,
      code,
      type
    )
    SELECT
      "billingAddr1" AS addr1,
      "billingAddr2" AS addr2,
      "billingTown" AS town,
      "billingState" AS state,
      "billingCode" AS code,
      ("billingAddressType")::smallint AS type
    FROM json_to_record($1) AS a (
      "billingAddr1" text,
      "billingAddr2" text,
      "billingTown"  text,
      "billingState" text,
      "billingCode"  text,
      "billingAddressType" text
    )
    WHERE NOT (a is NULL)
    RETURNING *
  ), new_organisation AS (
    INSERT INTO organisation (
      name,
      trading_name,
      data,
      url,
      address_id,
      billing_address_id
    )
    SELECT
      o.name,
      o.trading_name,
      o.data,
      o.url,
      (SELECT address_id FROM payload_address),
      CASE
        WHEN ($1->>'noBilling')::boolean IS TRUE THEN
          (SELECT address_id FROM payload_address)
        ELSE (SELECT address_id FROM billing_address)
      END
    FROM payload_organisation o
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      party_id AS "partyId",
      name,
      trading_name AS "tradingName",
      'ORGANISATION' AS type,
      created
    FROM new_organisation
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
