/**
 * Return the cost of a composite product.
 */
CREATE OR REPLACE FUNCTION prd.composite_cost (uuid, OUT result prd.cost) AS
$$
BEGIN
  WITH RECURSIVE product AS (
    -- First, select the immediate children of the root product
    SELECT
      c.product_uuid,
      c.quantity,
      c.parent_uuid
    FROM prd.component c
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (c.product_uuid)
        c.product_uuid,
        c.amount
      FROM prd.cost c
      WHERE c.product_uuid = c.product_uuid
      ORDER BY c.product_uuid, c.created DESC
    ) cst ON cst.product_uuid = c.product_uuid
    WHERE c.parent_uuid = $1

    UNION ALL

    -- Now that we have the first level of descendants, recursively select the
    -- components whose parent has NULL cost
    SELECT
      c.product_uuid,
      (p.quantity * c.quantity)::numeric(10,3) AS quantity, -- Adjust quantities
      c.parent_uuid
    FROM product p
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (c.product_uuid)
        c.product_uuid,
        c.amount
      FROM prd.cost c
      WHERE c.product_uuid = p.product_uuid
      ORDER BY c.product_uuid, c.created DESC
    ) parent_cost ON parent_cost.product_uuid = p.product_uuid
    INNER JOIN prd.component c
      ON c.parent_uuid = p.product_uuid AND parent_cost.amount IS NULL
  ), totals AS (
    SELECT
      sum(c.amount * p.quantity)::numeric(10,2) AS amount
    FROM product p
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (c.product_uuid)
        c.product_uuid,
        c.amount
      FROM prd.cost c
      WHERE c.product_uuid = p.product_uuid
      ORDER BY c.product_uuid, c.created DESC
    ) c ON c.product_uuid = p.product_uuid
  )
  SELECT
    $1,
    t.amount
  INTO
    result.product_uuid,
    result.amount
  FROM totals t;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;