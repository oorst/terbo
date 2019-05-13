CREATE OR REPLACE FUNCTION prd.cost (uuid) RETURNS prd.cost_t AS
$$
DECLARE
  result prd.cost_t;
BEGIN
  SELECT DISTINCT ON (c.product_uuid)
    c.cost_uuid,
    c.amount,
    CASE
      WHEN c.amount IS NOT NULL THEN
        TRUE
      ELSE NULL
    END,
    c.created,
    c.end_at
  INTO
    result.cost_uuid,
    result.amount,
    result.amount_is_set,
    result.created,
    result.end_at
  FROM prd.cost c
  WHERE c.product_uuid = $1
  ORDER BY c.product_uuid, c.created DESC;

  IF result IS NULL AND prd.is_composite($1) IS TRUE THEN
    SELECT
      c.cost_uuid,
      c.amount,
      c.created,
      c.end_at
    INTO
      result.cost_uuid,
      result.amount,
      result.created,
      result.end_at
    FROM prd.composite_cost($1) c;
  ELSE
    
  END IF;

  RETURN result;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.cost (json, OUT result json) AS
$$
BEGIN
  SELECT
    json_strip_nulls(to_json(prd.cost(($1->>'product_uuid')::uuid)))
  INTO
    result;
END
$$
LANGUAGE 'plpgsql';


