CREATE OR REPLACE FUNCTION hucx.create_element (json, OUT result json) AS
$$
BEGIN
  WITH new_item AS (
    INSERT INTO scm.item DEFAULT VALUES RETURNING *
  ), new_element AS (
    INSERT INTO hucx.element (
      project_id,
      item_id,
      data
    ) VALUES (
      ($1->>'projectId')::integer,
      (SELECT item_id FROM new_item),
      ($1->'data')::jsonb
    ) RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT hucx_project_id AS "projectId", element_id AS "elementId", data
    FROM new_element
  ) r;

END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
