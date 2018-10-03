CREATE OR REPLACE FUNCTION scm.list_items (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      i.item_uuid AS "itemUuid",
      i.type,
      coalesce(i.name, p.name) AS name,
      p.product_id AS "productId",
      p.name AS "productName",
      p.code
    FROM scm.item i
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    WHERE to_tsvector(
      concat_ws(' ',
        coalesce(i.name, p.name),
        p.code
      )
    ) @@ plainto_tsquery(($1->>'search') || ':*')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
