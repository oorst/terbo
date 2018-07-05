CREATE OR REPLACE FUNCTION sales.total_gst_json (_line_items sales.line_item, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT sum(gross_price) AS "grossPrice"
    FROM _line_items
  ) r;
END
$$
LANGUAGE 'plpgsql';
