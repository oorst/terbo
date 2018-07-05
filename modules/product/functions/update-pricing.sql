CREATE OR REPLACE FUNCTION prd.update_pricing (json, OUT result json) AS
$$
BEGIN
  -- Price
  INSERT INTO prd.price (
    product_id,
    gross,
    net,
    markup,
    markup_id
  )
  SELECT
    ($1->>'id')::integer,
    price.gross,
    price.net,
    price.markup,
    price."markupId"
  FROM json_to_record($1) AS price (
    gross      numeric(10,2),
    net        numeric(10,2),
    markup     numeric(10,2),
    "markupId" integer
  );

  INSERT INTO prd.cost (
    product_id,
    amount
  )
  SELECT
    ($1->>'id')::integer,
    cost.cost
  FROM json_to_record($1) AS cost (cost numeric(10,2));

  -- End the current cost if $1->>'cost' is set to null
  IF json_typeof($1->'cost') = 'null' THEN
    WITH current_cost AS (
      SELECT DISTINCT ON (cost.product_id)
        cost.cost_id
      FROM prd.cost cost
      WHERE cost.product_id = ($1->>'id')::integer
      ORDER BY cost.product_id, cost.cost_id DESC
    )
    UPDATE prd.cost cost SET end_at = CURRENT_TIMESTAMP
    FROM current_cost
    WHERE cost.cost_id = current_cost.cost_id;
  END IF;

  SELECT prd.get_product(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
