CREATE OR REPLACE FUNCTION prj.create_invoice (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      j."jobId" AS job_id,
      j."userId" AS created_by
    FROM json_to_record($1) AS j (
      "jobId" integer,
      "userId"    integer
    )
  ), sales_invoice AS (
    INSERT INTO sales.invoice (
      created_by
    )
    SELECT
      p.created_by
    FROM payload p
    RETURNING invoice_id
  ), job_invoice AS (
    INSERT INTO prj.job_invoice (
      job_id,
      invoice_id
    ) VALUES (
      (SELECT job_id FROM payload),
      (SELECT invoice_id FROM sales_invoice)
    )
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      invoice_id AS "invoiceId"
    FROM sales_invoice
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
