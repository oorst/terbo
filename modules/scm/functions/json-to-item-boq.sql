/**
Calculate the bill of quantities for a serialized item
*/
CREATE OR REPLACE FUNCTION scm.json_to_item_boq (json, OUT result json) AS
$$
BEGIN
  SELECT json_agg(r) INTO result
  FROM (
    SELECT
      COALESCE(pr.gross, pr.cost * (100 + COALESCE(pr.markup, pr.markup_amount, 0)) / 100) AS gross,
      pr.name,
      pr.type,
      q.code,
      SUM(q.quantity) AS quantity
    FROM scm.json_to_boq($1) q
    INNER JOIN prd.product_v pr
      USING (product_id)
    GROUP BY q.code, pr.cost, pr.gross, pr.markup, pr.markup_amount, pr.type, pr.name
  ) r;
END
$$
LANGUAGE 'plpgsql';
