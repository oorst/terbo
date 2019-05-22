CREATE OR REPLACE FUNCTION core.setting (text, OUT result text) AS
$$
BEGIN
  SELECT value INTO result
  FROM core.setting
  WHERE name = $1;
END
$$
LANGUAGE 'plpgsql';
