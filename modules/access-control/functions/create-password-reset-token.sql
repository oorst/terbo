-- Takes an email address, creates a password resset key for that user.
-- If the person is not found, return null

CREATE OR REPLACE FUNCTION access_control.create_reset_token (text) RETURNS json AS
$$
DECLARE
  result    json;
  person_id integer;
BEGIN
  SELECT p.person_id INTO person_id
  FROM person p WHERE p.email = $1;

  IF person_id IS NULL THEN
    RETURN NULL;
  END IF;

  WITH reset AS (
    INSERT INTO access_control.password_reset (key, person_id) VALUES (
      (SELECT md5(random()::text || clock_timestamp()::text)::uuid),
      person_id
    ) RETURNING key
  )
  SELECT row_to_json(r) INTO result
  FROM reset r;

  RETURN result;
END
$$
LANGUAGE 'plpgsql'
SECURITY DEFINER;
