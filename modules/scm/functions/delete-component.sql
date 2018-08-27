CREATE OR REPLACE FUNCTION scm.delete_component (json, OUT result json) AS
$$
BEGIN
  DELETE FROM scm.component WHERE component_id = ($1->>'componentId')::integer;

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
