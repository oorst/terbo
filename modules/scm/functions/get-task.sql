CREATE OR REPLACE FUNCTION scm.get_task (integer, OUT result json) AS
$$
BEGIN
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      task_id AS id,
      t.name,
      t.data,
      json_build_object(
        'name', p.name,
        'id', p.product_id,
        'code', p.code,
        'sku', p.sku
      ) AS product,
      json_build_object(
        'id', w.work_center_id,
        'name', w.name
      ) AS "workCenter"
    FROM scm.task t
    INNER JOIN prd.product p
      USING (product_id)
    LEFT JOIN scm.work_center w
      USING (work_center_id)
    WHERE t.task_id = $1
  ) r;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION scm.get_task (json, OUT result json) AS
$$
BEGIN
  SELECT scm.get_task(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
