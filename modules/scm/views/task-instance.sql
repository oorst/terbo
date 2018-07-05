/**
This view provides some pricing for a task instance.
It sums the task instance product records to produce a price.
*/
CREATE VIEW scm.task_inst_v AS
  SELECT
    ti.*,
    task.name,
    price.gross_price,
    price.net_price
  FROM scm.task_instance ti
  INNER JOIN scm.task task
    USING (task_id)
  LEFT JOIN
    (
      SELECT
        SUM(
          COALESCE(tip.quantity * pr.gross_price, 0)
        )::numeric(10,2) as gross_price,
        SUM(
          tip.quantity * pr.net_price
        )::numeric(10,2) as net_price,
        tip.task_inst_id
      FROM scm.task_instance_product tip
      INNER JOIN prd.product_v pr
        USING (product_id)
      GROUP BY tip.task_inst_id
    ) AS price
    USING (task_inst_id);
