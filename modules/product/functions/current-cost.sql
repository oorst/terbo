CREATE OR REPLACE FUNCTION prd.current_cost (id integer, OUT result numeric(10,2)) AS
$$
BEGIN
  SELECT r.amount INTO result
  FROM (
    SELECT DISTINCT ON (cost.product_id)
      cost.cost_id,
      cost.product_id,
      cost.amount
    FROM prd.cost cost
    WHERE cost.product_id = id
    ORDER BY cost.product_id, cost.cost_id DESC
  ) r;
END
$$
LANGUAGE 'plpgsql';
