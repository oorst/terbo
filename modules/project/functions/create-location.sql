CREATE OR REPLACE FUNCTION prj.create_location (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      p."lotNumber" AS lot_number,
      p."number1" AS road_number1,
      p."number2" AS road_number2,
      p."roadName" AS road_name,
      p."roadType" AS road_type,
      p.suffix AS road_suffix,
      p.locality AS locality_name,
      p.state,
      p.code,
      p.country
    FROM json_to_record($1) AS p (
      "lotNumber" text,
      "number1"   text,
      "number2"   text,
      "roadName"  text,
      "roadType"  text,
      suffix      text,
      locality    text,
      state       text,
      code        text,
      country     text
    )
  ), address AS (
    INSERT INTO full_address (
      lot_number,
      road_number1,
      road_number2,
      road_name,
      road_type,
      road_suffix,
      locality_name,
      state,
      code,
      country
    )
    SELECT
      lot_number,
      road_number1,
      road_number2,
      road_name,
      road_type,
      road_suffix,
      locality_name,
      state,
      code,
      country
    FROM payload
    RETURNING address_id
  ), update_project AS (
    UPDATE prj.project
    SET address_id = (SELECT address_id FROM address)
    WHERE project_id = ($1->>'projectId')::integer
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      address_id AS "addressId"
    FROM address
  ) r;
END
$$
LANGUAGE  'plpgsql' SECURITY DEFINER;
