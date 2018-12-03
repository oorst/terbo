CREATE OR REPLACE FUNCTION scm.task (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name,
      t.product_id AS "productId",
      t.description,
      p.name AS "productName",
      p.code AS "productCode"
    FROM scm.task t
    INNER JOIN prd.product_list_v p
      USING (product_id)
    WHERE t.task_id = ($1->>'taskId')::integer
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
