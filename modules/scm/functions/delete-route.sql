CREATE OR REPLACE FUNCTION scm.delete_route (json, OUT result json) AS
$$
BEGIN
  DELETE FROM scm.route r
  WHERE r.route_id = ($1->>'id')::integer;

  SELECT json_build_object('deleted', TRUE) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
