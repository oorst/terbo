CREATE OR REPLACE FUNCTION scm.delete_item (json, OUT result json) AS
$$
BEGIN
  DELETE FROM scm.item i
  WHERE i.item_uuid = ($1->>'uuid')::uuid;

  SELECT json_build_object('deleted', TRUE) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
