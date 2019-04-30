CREATE OR REPLACE FUNCTION prd.create_component (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      *
    FROM json_to_record($1) AS j (
      parent_uuid  uuid,
      product_uuid uuid,
      quantity    numeric(10,3)
    )
  ), component AS (
    INSERT INTO prd.component (
      parent_uuid,
      product_uuid,
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
      component_uuid
    FROM component
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
