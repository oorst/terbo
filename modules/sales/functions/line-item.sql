DROP TYPE sales.line_item_t CASCADE;

CREATE TYPE sales.line_item_t AS (
  "lineItemId"       integer,
  "orderId"          integer,
  "productId"        integer,
  "productCode"      text,
  "productName"      text,
  code               text,
  name               text,
  "shortDescription" text,
  data               jsonb,
  gross              numeric(10,2),
  "grossLineTotal"   numeric(10,2),
  "netLineTotal"     numeric(10,2),
  discount           numeric(5,2),
  "uomId"            integer,
  "uoms"             json,
  quantity           numeric(10,3),
  tax                boolean,
  note               text,
  "linePosition"     smallint,
  created            timestamp,
  "endAt"            timestamp
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
    li.line_position AS "linePosition",
    p.code AS "productCode",
    p.name AS "productName",
    li.code,
    li.name,
    li.short_desc AS "shortDescription",
    li.gross,
    li.total_gross AS "totalGross",
    li.price,
    li.total_price AS "totalPrice",
    li.discount,
    li.uom_id AS "uomId",
    prd.units(li.product_id) AS units,
    li.quantity,
    li.tax,
    li.note,
    li.created,
    li.end_at AS "endAt"
  FROM sales.line_item li
  LEFT JOIN prd.product_list_v p
    USING (product_id)
  WHERE li.order_id = $1;
END
$$
LANGUAGE 'plpgsql';
