CREATE OR REPLACE FUNCTION prd.create_component (json, OUT result json) AS
$$
BEGIN
  IF $1->'parentId' IS NULL THEN
    RAISE EXCEPTION 'must provide parentId to create a component';
  END IF;

  WITH payload AS (
    SELECT
      j."parentId" AS parent_id
    FROM json_to_record($1) AS j ("parentId" integer)
  ), component AS (
    INSERT INTO prd.component (
      parent_id
    )
    SELECT
      p.parent_id
    FROM payload p
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      component_id AS "componentId"
    FROM component
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
