CREATE OR REPLACE FUNCTION scm.delete_component (json, OUT result json) AS
$$
BEGIN
  DELETE FROM scm.component WHERE component_id = ($1->>'componentId')::integer;

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION scm.delete_component_tg () RETURNS trigger AS
$$
BEGIN
  DELETE FROM scm.item i
  WHERE i.item_uuid = OLD.item_uuid;

  RETURN NULL;
END
$$
LANGUAGE 'plpgsql';
