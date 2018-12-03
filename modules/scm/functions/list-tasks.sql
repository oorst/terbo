CREATE OR REPLACE FUNCTION scm.list_tasks (json, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name,
      p.name AS "productName"
    FROM scm.task t
    INNER JOIN prd.product p
      USING (product_id)
    WHERE p.tsv @@ to_tsquery($1->>'search')
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;

CREATE OR REPLACE FUNCTION scm.list_tasks (OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(json_agg(r)) INTO result
  FROM (
    SELECT
      t.task_id AS "taskId",
      t.name,
      p.name AS "productName",
      p.code
    FROM scm.task t
    INNER JOIN prd.product_list_v p
      USING (product_id)
    ORDER BY t.name, p.name
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
