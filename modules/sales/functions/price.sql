CREATE OR REPLACE FUNCTION sales.price (_cost prd.cost, _price sales.price)
RETURNS sales.price AS
$$
DECLARE
  result sales.price;
BEGIN
  -- Get any named margins or markups. Since margin has precedence, get it
  -- before markup
  IF _price.margin_id IS NOT NULL THEN
    SELECT
      mg.amount INTO _price.margin
    FROM sales.margin mg
    WHERE mg.margin_id = _price.margin_id;
  ELSIF _price.markup_id IS NOT NULL THEN
    SELECT
      mk.amount INTO _price.markup
    FROM sales.markup mk
    WHERE mk.markup_id = _price.markup_id;
  END IF;

  RETURN result;
END
$$
LANGUAGE 'plpgsql';