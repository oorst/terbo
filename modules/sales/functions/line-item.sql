CREATE TYPE sales.line_item_t AS (
  "lineItemId"   integer,
  "orderId"      integer,
  "productId"    integer,
  "productCode"  text,
  "productName"  text,
  code           text,
  name           text,
  description    text,
  data           jsonb,
  gross          numeric(10,2),
  discount       numeric(5,2),
  "uomId"        integer,
  "uoms"         json,
  quantity       numeric(10,3),
  tax            boolean,
  note           text,
  "linePosition" smallint,
  created        timestamp,
  "endAt"        timestamp
);

CREATE OR REPLACE FUNCTION sales.line_item(integer)
RETURNS SETOF sales.line_item_t AS
$$
BEGIN
  RETURN QUERY
  SELECT
    li.line_item_id AS "lineItemId",
    li.order_id AS "orderId",
    li.product_id AS "productId",
    p.code AS "productCode",
    p.name AS "productName",
    li.code,
    li.name,
    li.description,
    li.data,
    li.gross,
    li.discount,
    li.uom_id AS "uomId",
    (
      SELECT
        json_strip_nulls(json_agg(r::prd.product_uom_t))
      FROM (
        SELECT
          pu.uom_id AS "uomId",
          u.name,
          u.abbr,
          u.type,
          pu.divide,
          pu.multiply,
          pu.rounding_rule AS "roundingRule"
        FROM prd.product_uom pu
        INNER JOIN prd.uom u
          USING (uom_id)
        INNER JOIN prd.product p
          USING (product_id)
        WHERE pu.product_id = li.product_id
        ORDER BY p.uom_id = pu.uom_id, pu.product_uom_id
      ) r
    ) AS uoms,
    li.quantity,
    li.tax,
    li.note,
    li.line_position AS "linePosition",
    li.created,
    li.end_at AS "endAt"
  FROM sales.line_item li
  LEFT JOIN prd.product_list_v p
    USING (product_id)
  WHERE li.order_id = $1;
END
$$
LANGUAGE 'plpgsql';
