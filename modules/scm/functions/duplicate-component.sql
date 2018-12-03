CREATE OR REPLACE FUNCTION scm.duplicate_component (json, OUT result json) AS
$$
DECLARE
  _component_id integer;
BEGIN
  WITH component AS (
    -- Only select components that are items and not products
    -- If the component is a copy, return the prototype's item_uuid
    SELECT
      coalesce(i.prototype_uuid, c.item_uuid) AS item_uuid,
      c.parent_uuid
    FROM scm.component c
    INNER JOIN scm.item i
      USING (item_uuid)
    WHERE c.component_id = ($1->>'componentId')::integer
      AND c.product_id IS NULL
  ), new_item AS (
    INSERT INTO scm.item (
      prototype_uuid,
      name
    )
    SELECT
      c.item_uuid,
      i.name || ' (copy)'
    FROM component c
    INNER JOIN scm.item_list_v i
      USING (item_uuid)
    RETURNING *
  ), new_component AS (
    INSERT INTO scm.component (
      parent_uuid,
      item_uuid
    )
    SELECT
      c.parent_uuid,
      (SELECT item_uuid FROM new_item)
    FROM component c
    RETURNING *
  )
  SELECT component_id INTO _component_id
  FROM new_component;

  SELECT scm.component(_component_id) INTO result;
END
$$
LANGUAGE 'plpgsql';
