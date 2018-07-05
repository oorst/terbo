CREATE OR REPLACE FUNCTION scm.update_task (json, OUT result json) AS
$$
BEGIN
  -- Throw if no id is present
  IF $1->>'id' IS NULL THEN
    RAISE EXCEPTION 'no id provided';
  END IF;

  WITH existing AS (
    SELECT *
    FROM scm.task
    WHERE task_id = ($1->>'id')::integer
  )
  UPDATE scm.task task
  SET (
    product_id,
    name,
    concurrency,
    data,
    modified
  ) = (
    CASE
      WHEN $1->'productId' IS NULL THEN -- Note use of single bracket selector
        x.product_id
      ELSE ($1->>'productId')::integer
    END,
    CASE
      WHEN $1->'name' IS NULL THEN
        x.name
      ELSE $1->>'name'
    END,
    CASE
      WHEN $1->'concurrency' IS NULL THEN
        x.concurrency
      ELSE ($1->>'concurrency')::scm_task_concurrency_t
    END,
    CASE
      WHEN $1->'data' IS NULL THEN
        x.data
      ELSE ($1->'data')::jsonb
    END,
    -- modified
    CURRENT_TIMESTAMP
  )
  FROM existing x
  WHERE task.task_id = x.task_id;

  SELECT scm.get_task(($1->>'id')::integer) INTO result;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
