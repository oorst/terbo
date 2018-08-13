CREATE OR REPLACE FUNCTION prj.replace_boq (json, OUT result json) AS
$$
BEGIN
  IF $1->'jobId' IS NULL THEN
    RAISE EXCEPTION 'jobId not provided';
  END IF;

  DELETE FROM prj.boq_line_item WHERE job_id = ($1->>'jobId')::integer;

  WITH line_item AS (
    SELECT
      ($1->>'jobId')::integer AS job_id,
      p.product_id,
      j.quantity
    FROM json_to_recordset($1->'lineItems') AS j (
      code     text,
      quantity numeric(10,3)
    )
    INNER JOIN prd.product p
      USING (code)
  )
  INSERT INTO prj.boq_line_item (
    job_id,
    product_id,
    quantity
  )
  SELECT
    *
  FROM line_item;

  SELECT '{ "ok": true }'::json INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
