CREATE OR REPLACE FUNCTION prd.create_component (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      *
    FROM json_to_record($1) AS j (
      parent_id  integer,
      product_id integer,
      quantity    numeric(10,3)
    )
  ), component AS (
    INSERT INTO prd.component (
      parent_id,
      product_id,
      quantity
    )
    SELECT
      *
    FROM payload
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      component_id
    FROM component
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
