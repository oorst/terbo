/**

*/

CREATE OR REPLACE FUNCTION get_user_profile_by_email (text) RETURNS json AS
$$
DECLARE

  result json;

BEGIN

  SELECT to_json (profile) INTO result
  FROM (
    SELECT p.name, p.email, p.mobile, p.phone, 'person' AS type, p.password,
      p.roles, p.person_id AS id
    FROM person p
    WHERE p.email = $1
  ) AS profile;

  RETURN result;

END
$$
LANGUAGE 'plpgsql';
