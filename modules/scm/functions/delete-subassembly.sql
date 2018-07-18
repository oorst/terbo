CREATE OR REPLACE FUNCTION scm.delete_sub_assembly (json, OUT result json) AS
$$
BEGIN
  IF $1->>'id' IS NULL THEN
    RAISE EXCEPTION 'an id is required to delete a subassembly';
  END IF;

  DELETE FROM scm.sub_assembly WHERE sub_assembly_id = ($1->>'id')::integer;

  SELECT '{"deleted": true}'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
