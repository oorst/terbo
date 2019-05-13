CREATE OR REPLACE FUNCTION prd.create_cost (json, OUT result json) AS
$$
BEGIN
  INSERT INTO prd.cost (
    product_uuid,
    amount,
    end_at
  )
  SELECT
    p.product_uuid,
    p.amount,
    p.end_at
  FROM json_to_record($1) AS p (
    product_uuid uuid,
    amount       numeric(10,2),
    end_at       timestamptz
  );

  SELECT
    json_strip_nulls(to_json(r))
  INTO
    result
  FROM prd.cost(($1->>'product_uuid')::uuid) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
