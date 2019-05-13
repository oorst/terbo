/**

*/
CREATE OR REPLACE FUNCTION prd.create_cost (json, OUT result json) AS
$$
DECLARE
  new_cost prd.cost;
BEGIN
  WITH payload AS (
    SELECT
      p.*
    FROM json_to_record($1) AS p (
      product_uuid uuid,
      amount       numeric(10,2),
      end_at       timestamptz
    )
  )
  INSERT INTO prd.cost (
    product_uuid,
    amount,
    end_at
  )
  SELECT
    p.product_uuid,
    p.amount,
    p.end_at
  FROM payload p;

  SELECT prd.cost(($1->>'product_uuid')::uuid) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
