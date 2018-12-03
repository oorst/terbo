CREATE OR REPLACE FUNCTION prj.costing (json, OUT result json) AS
$$
BEGIN
  WITH RECURSIVE job AS (
    SELECT
      j.job_id,
      j.name,
      j.dependant_id
    FROM prj.job j
    WHERE j.job_id = ($1->>'jobId')::integer

    UNION ALL

    SELECT
      j.job_id,
      j.name,
      j.dependant_id
    FROM job p
    INNER JOIN prj.job j
      ON j.job_id = p.dependant_id
  ), root AS (
    SELECT
      j.job_id,
      j.name AS job_name,
      pj.name AS project_name,
      pj.project_id
    FROM job j
    INNER JOIN prj.project pj
      ON pj.job_id = j.job_id
    WHERE j.dependant_id IS NULL
  ), boq AS (
    SELECT
      boq.product_id,
      boq.uom_id,
      sum(boq.quantity) AS quantity
    FROM prj.deliverable d
    INNER JOIN scm.boq(d.item_uuid) boq
      ON boq.item_uuid = d.item_uuid
    WHERE d.job_id = ($1->>'jobId')::integer
    GROUP BY boq.product_id, boq.uom_id
  ), line_item AS (
    SELECT
      pv.name,
      price.gross,
      (boq.quantity * price.profit)::numeric(10,2) AS profit,
      (boq.quantity * price.gross)::numeric(10,2) AS line_total,
      uom.name AS uom_name,
      uom.abbr AS uom_abbr,
      boq.quantity
    FROM boq
    LEFT JOIN prd.product_list_v pv
      USING (product_id)
    LEFT JOIN prd.uom uom
      ON uom.uom_id = boq.uom_id
    LEFT JOIN prd.computed_price(boq.product_id) price
      ON price.product_id = boq.product_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      (SELECT project_name FROM root) AS "projectName",
      (SELECT name FROM job WHERE job_id = ($1->>'jobId')::integer) AS "jobName",
      ($1->>'jobId')::integer AS "jobId",
      json_build_object(
        'total', (SELECT sum(line_total) FROM line_item),
        'profit', (SELECT sum(profit) FROM line_item)
      ) AS "totals"
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
