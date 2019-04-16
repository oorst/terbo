CREATE OR REPLACE FUNCTION prd.components (
  component_id integer DEFAULT NULL,
  parent_id    integer DEFAULT NULL
) RETURNS SETOF prd.component_v AS
$$
BEGIN
  RETURN QUERY
  SELECT
    *
  FROM prd.component_v c
  WHERE c.component_id = $1 OR c.parent_id = $2;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION prd.components (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      c.component_id,
      c.product_id,
      c.quantity,
      pv.name,
      pv.code,
      pv.short_desc,
      uom.name AS uom_name,
      uom.abbr AS uom_abbr
    FROM prd.component c
    LEFT JOIN prd.product_v pv
      USING (product_id)
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pv.uom_id
    WHERE c.parent_id = ($1->>'product_id')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
