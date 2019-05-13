CREATE OR REPLACE FUNCTION core.create_person (json, OUT result json) AS
$$
DECLARE
  new_person_uuid uuid;
BEGIN
  INSERT INTO core.person (
    name,
    email,
    mobile,
    phone
  )
  SELECT
    *
  FROM json_to_record($1) AS p (
    name   text,
    email  text,
    mobile text,
    phone  text
  )
  RETURNING party_uuid INTO new_person_uuid;
  
  SELECT core.person(new_person_uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
