/**
Provide the normal form of a product in json format
*/

CREATE OR REPLACE FUNCTION prd.price_to_json (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT DISTINCT ON (p.product_id)
      p.price_id AS "priceId",
      p.product_id AS "productId",
      p.gross,
      p.net,
      p.markup,
      p.created,
      m.markup_id AS "markupId",
      m.name AS "markupName",
      m.amount AS "markupAmount",
      m.created AS "markupCreatedAt"
    FROM prd.price p
    LEFT JOIN prd.markup m
      ON m.markup_id = p.markup_id AND p.markup IS NULL
    WHERE p.product_id = $1
    ORDER BY p.product_id, p.created DESC
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.price_to_jsonb (integer, OUT result jsonb) AS
$$
BEGIN
  SELECT prd.price_to_json($1)::jsonb INTO result;
END
$$
LANGUAGE 'plpgsql';
