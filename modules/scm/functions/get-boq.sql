CREATE OR REPLACE FUNCTION scm.get_boq (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      boq.product_id AS "productId",
      p.type AS "productType",
      p.sku,
      p._code AS "productCode",
      p._name AS "productName",
      p._description AS "productDescription",
      pp.supplier_id AS "supplierId",
      pp.manufacturer_id AS "manufacturerId",
      boq.quantity,
      boq.gross,
      (boq.quantity * boq.gross)::numeric(10,2) AS "lineTotal"
    FROM (
      SELECT
        b.product_id,
        b.gross,
        sum(b.quantity) AS quantity
      FROM scm.item_boq(($1->>'itemUuid')::uuid) b
      GROUP BY product_id, gross
    ) boq
    INNER JOIN prd.product_list_v p
      USING (product_id)
    INNER JOIN prd.product pp
      ON pp.product_id = boq.product_id
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
