CREATE OR REPLACE FUNCTION scm.item_boq (uuid)
RETURNS TABLE (
  item_uuid  uuid,
  product_id integer,
  quantity   numeric(10,3),
  gross      numeric(10,2),
  line_total numeric(10,2)
) AS
$$
BEGIN
  RETURN QUERY
  WITH item AS (
    SELECT
      i.item_uuid,
      i.product_id,
      COALESCE(
        (i.data->'attributes'->>'quantity')::numeric(10,3) * i.quantity,
        (i.data->'attributes'->>uom.type)::numeric(10,3) * i.quantity,
        i.quantity
      )::numeric(10,3) AS quantity,
      i.explode
    FROM scm.flatten_item($1) i
    INNER JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.uom uom -- Left join as some products may have null uom_id
      ON uom.uom_id = p.uom_id
    WHERE i.type = 'PART' OR i.type = 'PRODUCT'
  ), product AS (
    SELECT
      item.product_id,
      item.quantity,
      FALSE AS is_composite
    FROM item
    WHERE item.explode = 0

    UNION ALL

    SELECT
      p.product_id,
      (item.quantity * p.quantity)::numeric(10,3) AS quantity,
      p.is_composite
    FROM item
    INNER JOIN LATERAL (
      SELECT
        item.product_id AS root_id,
        pp.product_id,
        pp.quantity,
        pp.is_composite
      FROM prd.flatten_product(item.product_id) pp
    ) p
      ON p.root_id = item.product_id
    WHERE item.explode = 1
    ), boq_line AS (
      SELECT
        p.product_id,
        p.quantity,
        coalesce(price.gross, cost.amount * (1 + price.markup / 100.00))::numeric(10,2) AS gross
      FROM product p
      LEFT JOIN (
        SELECT DISTINCT ON (cost.product_id)
          cost.product_id,
          cost.cost_id,
          cost.amount
        FROM prd.cost cost
        WHERE cost.end_at > CURRENT_TIMESTAMP OR cost.end_at IS NULL
        ORDER BY cost.product_id, cost.cost_id DESC
      ) cost
        ON cost.product_id = p.product_id
      LEFT JOIN (
        SELECT DISTINCT ON (price.product_id)
          price.product_id,
          price.price_id,
          price.gross,
          price.net,
          COALESCE(price.markup, markup.amount, 0.00) AS markup
        FROM prd.price price
        LEFT JOIN prd.markup
          USING (markup_id)
        ORDER BY price.product_id, price.price_id DESC
      ) price
        ON price.product_id = p.product_id
      WHERE p.is_composite IS FALSE
    )
    SELECT
      $1 AS uuid,
      boq_line.product_id,
      boq_line.quantity,
      boq_line.gross,
      (boq_line.quantity * boq_line.gross)::numeric(10,2) AS line_total
    FROM boq_line;
END
$$
LANGUAGE 'plpgsql';
