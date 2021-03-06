/*
Replace the native Sales.line_item functions to include Items where a line
item points to an Item
*/

ALTER TYPE sales.line_item_t ADD ATTRIBUTE "itemUuid" uuid;

CREATE OR REPLACE FUNCTION sales.line_item(integer) RETURNS SETOF sales.line_item_t AS
$$
BEGIN
  RETURN QUERY
  SELECT
    li.line_item_id AS "lineItemId",
    li.order_id AS "orderId",
    li.product_id AS "productId",
    p.code AS "productCode",
    p.name AS "productName",
    i.item_uuid AS "itemUuid",
    i.name AS "itemName",
    li.line_position AS "linePosition",
    li.code,
    li.name,
    li.description,
    li.data,
    li.discount,
    li.discount_amount AS "discountAmount",
    li.gross,
    li.uom_id AS "uomId",
    li.quantity,
    li.tax,
    li.note,
    li.created,
    li.end_at AS "endAt"
  FROM sales.line_item li
  LEFT JOIN prd.product_list_v p
    USING (product_id)
  LEFT JOIN scm.line_item sli
    USING (line_item_id)
  LEFT JOIN scm.item_list_v i
    ON i.item_uuid = sli.item_uuid
  WHERE li.line_item_id = $1 AND (li.end_at IS NULL OR li.end_at > CURRENT_TIMESTAMP);
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.line_item (json) RETURNS SETOF sales.line_item_t AS
$$
BEGIN
  IF $1->>'lineItemId' IS NOT NULL THEN
    RETURN QUERY
    SELECT * FROM sales.line_item(($1->>'lineItemId')::integer);
  ELSIF $1->>'orderId' IS NOT NULL THEN
    RETURN QUERY
    SELECT
      lir.*
    FROM sales.line_item li
    INNER JOIN sales.line_item(li.line_item_id) lir
      ON NOT (lir IS NULL)
    WHERE li.order_id = ($1->>'orderId')::integer;
  END IF;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
