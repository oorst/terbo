CREATE OR REPLACE FUNCTION prd.price (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT DISTINCT ON (p.product_id)
      price_id AS "priceId",
      product_id AS "productId",
      cost,
      cost_uom_id AS "costUomId",
      margin,
      margin_id AS "marginId",
      markup,
      markup_id AS "markupId",
      tax,
      created
    FROM prd.price p
    WHERE p.product_id = ($1->>'productId')::integer
    ORDER BY p.product_id, p.price_id DESC
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION prd.computed_price (integer) RETURNS TABLE (
  product_uom_id integer,
  gross          numeric(10,2),
  profit         numeric(10,2),
  margin         numeric(4,3)
) AS
$$
BEGIN
  RETURN QUERY
  WITH RECURSIVE product AS (
    -- First select the product_uom in question
    SELECT
      p.product_id,
      1.000 AS quantity,
      NULL::integer AS parent_id
    FROM prd.product p
    WHERE p.product_id = $1

    UNION ALL

    SELECT
      c.product_id,
      (p.quantity * c.quantity)::numeric(10,3) AS quantity, -- Adjust quantities
      c.parent_id
    FROM product p
    INNER JOIN prd.component c
      ON c.parent_id = p.product_id
  ),
  -- Filter out the composite products as only the non composites are required for
  -- price calculation
  non_composite AS (
    SELECT
      *
    FROM product p
    WHERE p.product_id NOT IN (
      SELECT
        parent_id
      FROM product
      WHERE parent_id IS NOT NULL
    )
  ),
  -- Calculate the markup
  price AS (
    SELECT
      nc.product_id,
      CASE
        WHEN price.gross IS NOT NULL THEN
          (price.gross * nc.quantity)::numeric(10,2)
        ELSE
          (price.cost * nc.quantity * (1.00 + markup.amount))::numeric(10,2)
      END AS gross,
      (price.cost * nc.quantity)::numeric(10,2) AS cost
    FROM non_composite nc
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (p.product_id)
        p.*
      FROM prd.price p
      WHERE p.product_id = nc.product_id
      ORDER BY p.product_id, p.price_id DESC
    ) price USING (product_id)
    LEFT JOIN prd.margin mg
      ON mg.margin_id = price.margin_id
    LEFT JOIN prd.markup mk
      ON mk.markup_id = price.markup_id
    -- Calculate the markup
    LEFT JOIN LATERAL (
      SELECT
        price.product_id,
        CASE
          WHEN price.margin IS NOT NULL THEN
            (price.margin / (1.00 - price.margin))::numeric(10,2)
          WHEN mg.amount IS NOT NULL THEN
            (mg.amount / (1.00 - mg.amount))::numeric(10,2)
          WHEN price.markup IS NOT NULL THEN
            price.markup
          WHEN mk.amount IS NOT NULL THEN
            mk.amount
          ELSE 1.00::numeric(10,2)
        END AS amount
    ) markup ON markup.product_id = nc.product_id
  )
  SELECT
    $1 AS product_id,
    price.gross,
    price.profit,
    (price.profit / price.gross)::numeric(4,3) AS margin
  FROM (
    SELECT
      sum(price.gross) AS gross,
      sum(price.cost) AS cost,
      sum(price.gross - price.cost) AS profit
    FROM price
  ) price;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
