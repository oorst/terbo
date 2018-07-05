/**
@function _get_address
  Private function
*/
CREATE OR REPLACE FUNCTION get_address (integer, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT addr1, addr2, town, state, code
    FROM address
    WHERE address_id = $1
  ) r;

  result = json_strip_nulls(result);
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_address (json, OUT result json) AS
$$
BEGIN
  SELECT _get_address(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
