-- DROP TYPE sales.line_item_t CASCADE;
--
-- CREATE TYPE sales.line_item_t AS (
--   "lineItemId"       integer,
--   "orderId"          integer,
--   "productId"        integer,
--   "productCode"      text,
--   "productName"      text,
--   code               text,
--   name               text,
--   "shortDescription" text,
--   data               jsonb,
--   cost               numeric(10,2),
--   "grossPrice"       numeric(10,2),
--   "grossProfit"      numeric(10,2),
--   "grossMargin"      numeric(4,3),
--   "lineGrossPrice"   numeric(10,2),
--   discount           numeric(5,2),
--   "uomId"            integer,
--   "uoms"             json,
--   quantity           numeric(10,3),
--   tax                boolean,
--   note               text,
--   "linePosition"     smallint,
--   created            timestamp,
--   "endAt"            timestamp
-- );

CREATE OR REPLACE FUNCTION sales.line_items(json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      li.*
    FROM sales.line_item li
    WHERE li.order_id = ($1->>'orderId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql';
