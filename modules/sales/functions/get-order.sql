CREATE OR REPLACE FUNCTION sales.get_order (integer, OUT result json) AS
$$
BEGIN
  WITH document AS (
    SELECT
      o.order_id,
      o.status,
      o.notes,
      o.created_by,
      o.buyer_id,
      o.created,
      buyer.name AS buyer_name,
      buyer.type AS buyer_type,
      creator.name AS creator_name,
      creator.email AS creator_email
    FROM sales.order o
    INNER JOIN party_v buyer
      ON buyer.party_id = o.buyer_id
    INNER JOIN person creator
      ON creator.party_id = o.created_by
    WHERE o.order_id = $1
  ), line_item AS (
    SELECT
      li.line_item_id AS "lineItemId",
      li.order_id AS "orderId",
      li.product_id AS "productId",
      li.position,
      coalesce(li.code, p._code) AS code,
      coalesce(li.name, p._name) AS name,
      coalesce(li.description, p._description) AS description,
      uom.name AS "uomName",
      uom.abbr AS "uomAbbr",
      li.data,
      li.quantity,
      li.gross,
      coalesce(li.gross, prd.product_gross(p.product_id)) AS "$gross"
    FROM sales.line_item li
    INNER JOIN document
      USING (order_id)
    LEFT JOIN prd.product_list_v p
      USING (product_id)
    LEFT JOIN prd.product pp
      ON pp.product_id = li.product_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = pp.uom_id
    ORDER BY position, line_item_id
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      document.order_id AS "orderId",
      document.buyer_name AS "buyerName",
      document.buyer_type AS "buyerType",
      document.status,
      document.created,
      document.notes,
      document.creator_name AS "creatorName",
      document.creator_email AS "creatorEmail",
      (SELECT json_agg(l) FROM line_item l) AS "lineItems"
    FROM document
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.get_order (json, OUT result json) AS
$$
BEGIN
  SELECT sales.get_order(($1->>'orderId')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
