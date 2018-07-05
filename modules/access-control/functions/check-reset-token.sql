-- Checks that the passed key belongs to a valid token.
-- Return 0 on success, 1 on failure, 2 if token has expired.

CREATE OR REPLACE FUNCTION access_control.check_reset_token (uuid) RETURNS integer AS
$$
DECLARE
  reset RECORD;
BEGIN
  SELECT * INTO reset
  FROM access_control.password_reset
  WHERE key = $1;

  IF reset IS NULL THEN
    RETURN 1;
  ELSIF (CURRENT_TIMESTAMP - reset.created) > INTERVAL '10 mins' THEN
    -- Delete the token if it has expired
    DELETE FROM access_control.password_reset r
    WHERE r.reset_id = reset.reset_id;

    RETURN 2;
  END IF;

  RETURN 0;
END
$$
LANGUAGE 'plpgsql'
SECURITY DEFINER;
