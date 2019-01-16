/**
Generate Bill of Materials
*/

DROP FUNCTION prj.bom (integer, integer);

CREATE FUNCTION prj.bom (
  _job_id integer,
  _depth  integer DEFAULT NULL
) RETURNS TABLE (
  job_id integer,
  product_id integer,
  uom_id     integer,
  quantity   numeric(10,3)
) AS
$$
BEGIN
  RETURN QUERY
  SELECT
    job.job_id,
    p.product_id,
    p.uom_id,
    sum((i.quantity * p.quantity)::numeric(10,3)) AS quantity
  FROM prj.flatten_job(_job_id, _depth) job
  LEFT JOIN prj.deliverable d
    ON d.job_id = job.job_id
  LEFT JOIN scm.flatten_item(d.item_uuid) i
    ON i.root_uuid = d.item_uuid
      AND i.item_uuid IS DISTINCT FROM i.root_uuid
      AND i.item_uuid IS NULL -- Component must not be an item
      AND i.product_id IS NOT NULL -- Component must have a product_id
  LEFT JOIN prd.flatten_product(i.product_id, i.uom_id) p
    ON p.root_id = i.product_id
      AND p.is_leaf IS TRUE
  INNER JOIN prd.product q
    ON q.product_id = p.product_id
      AND q.type = 'PRODUCT'
  GROUP BY job.level >= _depth, job.job_id, p.product_id, p.uom_id;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prj.bom (json, OUT result json) AS
$$
BEGIN
  WITH payload AS (
    SELECT
      coalesce(pj.job_id, p."jobId") AS job_id,
      p.depth
    FROM json_to_record($1) AS p (
      "projectId" integer,
      "jobId"     integer,
      depth       integer
    )
    LEFT JOIN prj.project pj
      ON pj.project_id = "projectId"
  )
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      b.*,
      pv.name,
      pv.short_desc AS "shortDescription",
      pu.abbr AS "uomAbbr"
    FROM payload p
    LEFT JOIN prj.bom(p.job_id, p.depth) b
      ON b.job_id = p.job_id
    LEFT JOIN prd.product_list_v pv
      USING (product_id)
    LEFT JOIN prd.product_uom_v pu
      ON pu.product_id = b.product_id AND pu.uom_id = b.uom_id
  ) r;
END
$$
LANGUAGE 'plpgsql';
