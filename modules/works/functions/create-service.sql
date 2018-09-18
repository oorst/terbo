CREATE OR REPLACE FUNCTION works.create_service (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."workCenterId" AS work_center_id,
      j."productId" AS product_id
    FROM json_to_record($1) AS j (
      "workCenterId" integer,
      "productId"    integer
    )
  ), service AS (
    INSERT INTO works.service
    SELECT
      *
    FROM payload p
    RETURNING *
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      TRUE AS ok
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
