CREATE OR REPLACE FUNCTION scm.list_items (json, OUT result json) AS
$$
BEGIN
  -- Throw if no search term is present
  IF $1->>'search' IS NULL THEN
    RAISE EXCEPTION 'no search term provided';
  END IF;

  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS uuid,
      i.type,
      coalesce(i.name, p._name) AS "$name",
      p.product_id AS "productId",
      p._name AS "$productName",
      p._code AS "$code",
      p._description AS "$productDescription"
    FROM scm.item i
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE to_tsvector(
      concat_ws(' ',
        i.name,
        p._name,
        p._code
      )
    ) @@ plainto_tsquery($1->>'search')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
