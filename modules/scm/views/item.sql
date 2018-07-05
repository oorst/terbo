CREATE VIEW scm.item_v AS
  SELECT
    item.item_id,
    item.item_uuid,
    item.super,
    item.route,
    item.data,
    -- Product details
    pr.name,
    pr.description,
    -- A set price takes precedence over a calculated price
    COALESCE(item.gross_price, price.gross_price) AS gross_price,
    COALESCE(item.net_price, price.net_price) AS net_price
  FROM scm.item item
  LEFT JOIN prd.product pr
    USING (product_id)
  LEFT JOIN
  (
    SELECT
      SUM(
        ti.gross_price
      )::numeric(10,2) as gross_price,
      SUM(
        ti.net_price
      )::numeric(10,2) as net_price,
      ti.item_id
    FROM scm.task_inst_v ti
    GROUP BY ti.item_id
  ) AS price
    USING (item_id);
