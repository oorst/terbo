CREATE OR REPLACE FUNCTION prd.is_composite (uuid, OUT result boolean) AS
$$
BEGIN
  SELECT
    EXISTS(
      SELECT
      FROM prd.component component
      WHERE component.parent_uuid = $1
    )
  INTO
    result;
END
$$
LANGUAGE 'plpgsql';