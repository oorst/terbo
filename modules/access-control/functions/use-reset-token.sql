-- Reset a perspn's password by using a reset token.
-- Returns 0 on success, returns 1 if emial not found, or 2 if key is invalid

CREATE OR REPLACE FUNCTION access_control.use_reset_token (uuid, text) RETURNS integer AS
$$
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
