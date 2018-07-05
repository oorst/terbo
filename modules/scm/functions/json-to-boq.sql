/**
Calculate the bill of quantities for a serialized item

`scm.json_to_boq` requires that the top level item provided to the function
has a route associated with it.  If not, an U0001 exception is raised.  The
hint should be returned to the client.
*/
CREATE OR REPLACE FUNCTION scm.json_to_boq (json)
RETURNS TABLE (
  product_id integer,
  code       text,
  quantity   numeric(10,2)
  -- uom_id     integer TODO
) AS
$$
BEGIN
  -- If item does not have a route
  IF NOT EXISTS(
    SELECT
      r.route_id
    FROM prd.product p
    INNER JOIN scm.product_route r
      USING (product_id)
    WHERE p.code = $1->>'code'
  ) THEN
    RAISE EXCEPTION 'No route exists for this item'
      USING ERRCODE = 'U0001',
      HINT = 'No route exists for product code ' || ($1->>'code') || '. Assign a route to the product.';
  END IF;

  -- If the json is an array, recursively get the boq of all items
  IF json_typeof($1) = 'array' THEN
    RETURN QUERY
    SELECT
      q.*
    FROM json_array_elements($1) e
    CROSS JOIN scm.json_to_boq(e.value) q;
    RETURN;
  END IF;

  RETURN QUERY
  WITH
  item_boq_qty AS (
    SELECT
      q.code,
      q.ref,
      q.quantity
    FROM scm.flatten_item($1) i
    CROSS JOIN json_each(i.boq) item_boq
    CROSS JOIN json_to_recordset(item_boq.value) AS
      q(code text, ref text, quantity numeric(10,3))
  )
  SELECT
    p.product_id,
    p.code,
    q.quantity
  FROM item_boq_qty q
  INNER JOIN prd.product p
    USING (code)
  
  UNION ALL

  SELECT
    p.product_id,
    p.code,
    q.quantity
  FROM item_boq_qty q
  INNER JOIN prd.ref ref
    ON ref.name = q.ref
  INNER JOIN prd.product_ref
    USING (ref_id)
  INNER JOIN prd.product p
    USING (product_id);




  -- Quantities from items with attributes
  -- item_attr_qty AS (
  --   SELECT
  --     map.code,
  --     attr.value::text::numeric(10,3) AS quantity
  --   FROM item
  --   -- get all tasks associated with this item's route
  --   INNER JOIN scm.route_task task
  --     USING (route_id)
  --   INNER JOIN scm.task_inst_attr_map map
  --     USING (task_id)
  --   LEFT JOIN json_each(item.attributes) attr
  --     ON map.attribute = attr.key
  --   WHERE item.attributes IS NOT NULL
  -- )
  -- SELECT
  --   pr.code,
  --   pr.product_id,
  --   q.quantity
  -- FROM item_boq_qty
  -- FROM (
  --   SELECT *
  --   FROM item_boq_qty
  --
  --   UNION ALL
  --
  --   SELECT *
  --   FROM item_attr_qty
  -- ) q
  -- INNER JOIN prd.product_v pr
  --   USING (code);
END
$$
LANGUAGE 'plpgsql';
