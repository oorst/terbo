/**
Provide names and uuids of a component's ancestors in the form of an array.

Array aelements are ordered from most distant ancestor to closest
*/

CREATE OR REPLACE FUNCTION scm.path (uuid) RETURNS TABLE (
  item_uuid      uuid,
  name_path      text[],
  item_uuid_path uuid[]
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE component AS (
    -- Select the item.  Left join with scm.item so that the queried item is
    -- always included in the results even if the item is not a component
    SELECT
      i.item_uuid,
      0 AS level
    FROM scm.item i
    WHERE i.item_uuid = $1

    UNION ALL

    SELECT
      c.parent_uuid AS item_uuid,
      level + 1 AS level
    FROM component
    -- Join order is important here.
    INNER JOIN scm.item i
      ON i.item_uuid = component.item_uuid
    LEFT JOIN scm.component c
      ON c.item_uuid = component.item_uuid
    WHERE c.parent_uuid IS NOT NULL
  ),
  ordered AS (
    SELECT
      iv.name,
      c.item_uuid
    FROM component c
    INNER JOIN scm.item_list_v iv
      USING (item_uuid)
    WHERE 0 < c.level
    ORDER BY c.level DESC
  )
  SELECT
    $1 AS item_uuid,
    array_agg(o.name) AS name_path,
    array_agg(o.item_uuid) AS item_uuid_path
  FROM ordered o;
END
$$
LANGUAGE 'plpgsql';
