CREATE OR REPLACE FUNCTION sales.price (_cost prd.cost_t, _price sales.price_t)
RETURNS sales.price_t AS
$$
DECLARE
  result sales.price_t;
BEGIN
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

  IF _price.gross IS NOT NULL THEN
    result.gross = _price.gross;
    result.gross_is_set = TRUE;
  ELSIF _price.gross IS NULL AND _cost.amount IS NOT NULL THEN
    IF _price.margin IS NOT NULL THEN
      result.gross = _cost.amount / (1.000 - _price.margin)::numeric(10,2);
    ELSIF _price.markup IS NOT NULL THEN
      result.gross = _cost.amount * (1.00 + _price.markup)::numeric(10,2);
    END IF;
  END IF;

  RETURN result;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.price (uuid)
RETURNS sales.price_t AS
$$
DECLARE
  result sales.price_t;
BEGIN
  SELECT DISTINCT ON (pp.product_uuid)
    p.price_uuid,
    p.gross,
    p.price,
    p.margin,
    p.margin_id,
    p.markup,
    p.markup_id,
    CASE
      WHEN p.gross IS NOT NULL THEN TRUE
      ELSE NULL
    END,
    p.tax_excluded,
    p.created,
    p.end_at
  INTO
    result.price_uuid,
    result.gross,
    result.price,
    result.margin,
    result.margin_id,
    result.markup,
    result.markup_id,
    result.gross_is_set,
    result.tax_excluded,
    result.created,
    result.end_at
  FROM sales.product_price pp
  LEFT JOIN sales.price p
    ON p.price_uuid = pp.price_uuid
  WHERE pp.product_uuid = $1
  ORDER BY pp.product_uuid, p.created DESC;

  RETURN result;
END
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sales.price (json, OUT result json) AS
$$
BEGIN
  result = json_strip_nulls(to_json(sales.price(($1->>'product_uuid')::uuid)));
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;