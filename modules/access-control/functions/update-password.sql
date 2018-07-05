-- update a person's password.  requires a valid password reset token.
-- On success return 0
-- return 1 when no key is found
-- return 2 if key has expired

CREATE OR REPLACE FUNCTION access_control.update_password (uuid, text) RETURNS integer AS
$$
DECLARE
  reset  RECORD;
BEGIN
  SELECT * INTO reset
  FROM access_control.password_reset
  WHERE key = $1;

  IF reset IS NULL THEN
    RETURN 1;
  ELSIF (CURRENT_TIMESTAMP - reset.created) > INTERVAL '10 mins' THEN
    DELETE FROM access_control.password_reset r
    WHERE r.reset_id = reset.reset_id;

    RETURN 2;
  END IF;

  UPDATE person SET password = $2 WHERE person_id = reset.person_id;

  DELETE FROM access_control.password_reset r
  WHERE r.reset_id = reset.reset_id;

  RETURN 0;
END
$$
LANGUAGE 'plpgsql'
SECURITY DEFINER;
