/**

*/
CREATE OR REPLACE FUNCTION prd.create_price (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."productId" AS product_id,
      j.cost,
      j.gross,
      j.net,
      j.margin,
      j."marginId" AS margin_id,
      j.markup,
      j."markupId" AS markup_id,
      j.tax
    FROM json_to_record($1) AS j (
      "productId" integer,
      cost        numeric(10,2),
      gross       numeric(10,2),
      net         numeric(10,2),
      margin      numeric(5,2),
      "marginId"  integer,
      markup      numeric(10,2),
      "markupId"  integer,
      tax         boolean
    )
  ), price AS (
    INSERT INTO prd.price (
      product_id,
      cost,
      gross,
      net,
      margin,
      margin_id,
      markup,
      markup_id,
      tax
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      price_id AS "priceId",
      product_id AS "productId",
      cost,
      gross,
      net,
      margin,
      margin_id AS "marginId",
      markup,
      markup_id AS "markupId",
      tax
    FROM price
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
