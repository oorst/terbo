CREATE OR REPLACE FUNCTION prj.delete_deliverable (json, OUT result json) AS
$$
BEGIN
  DELETE FROM prj.deliverable d
  WHERE d.deliverable_id = ($1->>'deliverableId')::integer;

  SELECT '{ "ok": true }' INTO result;
END
$$
LANGUAGE 'plpgsql';
