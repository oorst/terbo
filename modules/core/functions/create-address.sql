CREATE OR REPLACE FUNCTION create_address (address, OUT result integer) AS
$$
BEGIN
  INSERT INTO address (
    addr1,
    addr2,
    town,
    state,
    country,
    code,
    type
  )
  SELECT
    address.addr1,
    address.addr2,
    address.town,
    address.state,
    address.country,
    address.code,
    address.type
  RETURNING address_id INTO result;
END
$$
LANGUAGE 'plpgsql';

/**
@function Create an address entity.

@returns <Integer> The address_id.
*/
CREATE OR REPLACE FUNCTION create_address (json, OUT result integer) AS
$$
BEGIN
  INSERT INTO address (
    addr1,
    addr2,
    town,
    state,
    code
  ) values (
    $1->>'addr1',
    $1->>'addr2',
    $1->>'town',
    $1->>'state',
    $1->>'code'
  ) RETURNING address_id INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
