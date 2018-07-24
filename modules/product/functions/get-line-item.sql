CREATE OR REPLACE FUNCTION prd.get_line_item (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      p.product_id AS "productId",
      p.type,
      p._code AS "$productCode",
      p._name AS "$productName",
      p._description AS "$description",
      prd.product_gross($1) AS "gross"
    FROM prd.product_list_v p
    WHERE p.product_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION prd.get_line_item (json, OUT result json) AS
$$
BEGIN
  IF $1->>'productId' IS NULL THEN
    RAISE EXCEPTION 'must provide a product id';
  END IF;

  IF json_typeof($1->'productId') = 'array' THEN
    WITH payload AS (
      SELECT
        value::integer AS product_id
      FROM json_array_elements_text($1->'productId')
    )
    SELECT json_agg(prd.get_line_item(product_id)) INTO result
    FROM payload;
  ELSE
    SELECT prd.get_line_item(($1->>'productId')::integer) INTO result;
  END IF;
END
$$
LANGUAGE 'plpgsql';
