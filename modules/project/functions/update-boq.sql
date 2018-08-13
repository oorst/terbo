/*
Create a dyamic query that only updates fileds that present on the payload
*/
CREATE OR REPLACE FUNCTION prj.update_boq (json, OUT result json) AS
$$
BEGIN
  IF $1->'jobId' IS NULL THEN
    RAISE EXCEPTION 'jobId not provided';
  END IF;

  WITH payload AS (
    SELECT
      j."jobId" AS job_id,
      j.code,
      j.quantity
    FROM json_to_record($1) AS j (
      "jobId"  integer,
      code     text,
      quantity numeric(10,3)
    )
  ), existing_line_item AS (
    SELECT
      *
    FROM prj.line_item
    INNER JOIN payload p
      USING (job_id)
    INNER JOIN prd.product pr
      USING (product_id)
  ), new_line_item AS (
    SELECT
      *
    FROM prj.line_item
    INNER JOIN payload p
      USING (job_id)
    INNER JOIN prd.product pr
      USING (product_id)
  )

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
