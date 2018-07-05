CREATE OR REPLACE FUNCTION scm.get_line_item (uuid, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      item_v.name,
      (
        SELECT sum(line_total) FROM scm.item_bom($1)
      ) AS gross,
      1.000::numeric(10,3) AS quantity
    FROM scm.item_v
    WHERE item_uuid = $1
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
