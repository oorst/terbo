CREATE OR REPLACE FUNCTION hucx.get_user (json, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      name,
      email,
      user_id AS "userId",
      person_id AS "personId",
      hash,
      roles
    FROM hucx.user_v u
    WHERE u.email = $1->>'email'
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
