/**
@function Create an address entity.

@returns <Integer> The address_id.
*/

CREATE OR REPLACE FUNCTION insert_address (json) RETURNS SETOF address AS
$$
BEGIN
  RETURN QUERY
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
  ) RETURNING *;
END
$$
LANGUAGE 'plpgsql';
