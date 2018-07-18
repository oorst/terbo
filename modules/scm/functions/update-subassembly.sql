CREATE OR REPLACE FUNCTION scm.update_sub_assembly (json, OUT result json) AS
$$
BEGIN
  IF $1->'subAssemblyId' IS NULL THEN
    RAISE EXCEPTION 'sub-assembly id not provided';
  END IF;

  WITH payload AS (
    SELECT
      quantity,
      j."subAssemblyId" AS sub_assembly_id
    FROM json_to_record($1) AS j (
      quantity        numeric(10,3),
      "subAssemblyId" integer
    )
  ), updated_sub_assembly AS (
    UPDATE scm.sub_assembly s SET (
      quantity
    ) = (
      p.quantity
    )
    FROM payload p
    WHERE s.sub_assembly_id = p.sub_assembly_id
    RETURNING s.*
  )
  SELECT to_json(r) INTO result
  FROM (
    SELECT
      u.sub_assembly_id AS "subAssemblyId"
    FROM updated_sub_assembly u
  ) r;
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
