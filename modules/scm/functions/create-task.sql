CREATE OR REPLACE FUNCTION scm.create_task (json, OUT result json) AS
$$
BEGIN
  WITH new_task AS (
    INSERT INTO scm.task (
      product_id,
      name,
      work_center_id
    ) VALUES (
      ($1->>'productId')::integer,
      $1->>'name',
      ($1->>'workCenterId')::integer
    )
    RETURNING *
  )
  SELECT json_strip_nulls(to_json(r)) INTO result
  FROM (
    SELECT
      t.task_id AS id,
      p.name,
      p.code,
      p.supplier_code AS "supplierCode"
    FROM new_task t
    INNER JOIN prd.product p
      USING (product_id)
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
