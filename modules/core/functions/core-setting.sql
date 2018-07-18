CREATE OR REPLACE FUNCTION core_setting (text, OUT result text) AS
$$
BEGIN
  SELECT value INTO result
  FROM core_settings
  WHERE name = $1;
END
$$
LANGUAGE 'plpgsql';
