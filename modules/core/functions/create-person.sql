CREATE OR REPLACE FUNCTION create_person (json, OUT result json) AS
$$
BEGIN
  WITH person AS (
    SELECT
      *
    FROM json_to_record($1) AS p (
      name   text,
      email  text,
      mobile text,
      phone  text
    )
  ), address AS (
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
  ), new_person AS (
    INSERT INTO person (
      name,
      email,
      mobile,
      phone,
      address_id,
      billing_address_id
    )
    SELECT
      p.name,
      p.email,
      p.mobile,
      p.phone,
      (SELECT address_id FROM address),
      CASE
        WHEN ($1->>'noBilling')::boolean IS TRUE THEN
          (SELECT address_id FROM address)
        ELSE (SELECT address_id FROM billing_address)
      END
    FROM person p
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      party_id AS id,
      name,
      email,
      mobile,
      phone
    FROM new_person
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
