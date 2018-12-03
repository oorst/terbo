CREATE OR REPLACE FUNCTION prj.estimate (json, OUT result json) AS
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
    WHERE d.job_id = ($1->>'jobId')::integer
    GROUP BY boq.product_id, boq.uom_id
  ), line_item AS (
    SELECT
      pv.name,
      price.gross,
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
      (
        SELECT array_agg(r)
        FROM (
          SELECT
            li.name,
            li.uom_name AS "uomName",
            li.uom_abbr AS "uomAbbr",
            li.gross,
            li.line_total AS "lineTotal"
          FROM line_item li
        ) r
      ) AS "lineItems",
      json_build_object(
        'total', (SELECT sum(line_total) FROM line_item)
      ) AS "totals"
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
