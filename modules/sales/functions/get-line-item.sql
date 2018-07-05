CREATE OR REPLACE FUNCTION sales.get_line_item (integer, OUT result json) AS
$$
BEGIN
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      li.identifier,
      li.name,
      (li.gross_price)::text AS "grossPrice",
      (li.net_price)::text AS "netPrice",
      (
        SELECT json_agg(body)
        FROM sales.line_item_note lin
        WHERE lin.line_item_id = $1 AND lin.importance = 'normal'
      ) AS notes
    FROM sales.line_item li
    WHERE line_item_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';
