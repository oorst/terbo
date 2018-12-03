CREATE OR REPLACE FUNCTION prj.boq (json, OUT result json) AS
$$
BEGIN
  WITH boq AS (
    SELECT
      boq.product_id,
      boq.uom_id,
      sum(boq.quantity) AS quantity
    FROM prj.deliverable d
    INNER JOIN scm.boq(d.item_uuid) boq
      ON boq.item_uuid = d.item_uuid
    INNER JOIN prd.product_list_v pv
      USING (product_id)
    WHERE d.job_id = ($1->>'jobId')::integer
    GROUP BY boq.product_id, boq.uom_id
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      boq.product_id AS "productId",
      pv.name,
      pv.code,
      pv.short_desc AS "shortDescription",
      boq.quantity,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr"
    FROM boq
    LEFT JOIN prd.product_list_v pv
      USING (product_id)
    LEFT JOIN prd.uom uom
      ON uom.uom_id = boq.uom_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
