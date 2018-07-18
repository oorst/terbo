CREATE OR REPLACE FUNCTION scm.create_item_instance (json, OUT result json) AS
$$
BEGIN
  IF json_typeof($1) == 'array' THEN
    SELECT json_agg(scm)
  ELSE
    -- Check there is a valid UUID present
    IF $1->'uuid' IS NULL OR $1->>'uuid' ~* core_setting('rgx.uuid') IS FALSE THEN
      RAISE EXCEPTION 'a valid uuid must be provided';
    END IF;
  END IF;

  SELECT '{ "ok": "yep"}' INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
