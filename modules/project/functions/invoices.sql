CREATE OR REPLACE FUNCTION prj.invoices (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.invoice_id AS "invoiceId",
      i.short_desc AS "shortDescription",
      i.status
    FROM prj.job_invoice j
    INNER JOIN sales.invoice i
      USING (invoice_id)
    WHERE j.job_id = ($1->>'jobId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
