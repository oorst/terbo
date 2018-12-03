CREATE OR REPLACE FUNCTION full_address (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      address_id AS "addressId",
      lot_number AS "lotNumber",
      road_number1 AS "number1",
      road_number2 AS "number2",
      road_name AS "roadName",
      road_type AS "roadType",
      road_suffix AS "suffix",
      locality_name AS "locality",
      state,
      country,
      code,
      type
    FROM full_address
    WHERE address_id = ($1->>'addressId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
