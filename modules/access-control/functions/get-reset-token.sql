CREATE OR REPLACE FUNCTION access_control.get_reset_token (uuid) RETURNS json AS
$$
DECLARE
  token  RECORD;
  result json;
BEGIN
  SELECT r.key, p.email INTO token
  FROM access_control.password_reset r
  INNER JOIN person p USING (person_id)
  WHERE r.key = $1;

  IF token IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT row_to_json(token) INTO result;

  RETURN result;
END
$$
LANGUAGE 'plpgsql'
SECURITY DEFINER;
