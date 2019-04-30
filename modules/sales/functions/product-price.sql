/**
 * Compute the pricing for a product at a given point in time.
 */

CREATE OR REPLACE FUNCTION sales.product_price (integer, timestamptz DEFAULT CURRENT_TIMESTAMP) RETURNS sales.price AS
$$
DECLARE
  cost  prd.cost;
  price sales.price;
  result sales.price;
  profit numeric(10,2);
BEGIN
  SELECT DISTINCT ON (c.product_id)
    c.*
  INTO cost
  FROM prd.cost c
  WHERE c.product_id = $1 AND
    c.created < $2 AND
    (c.end_at IS NULL OR c.end_at < $2)
  ORDER BY c.product_id, c.created DESC;
  
  SELECT DISTINCT ON (pp.product_id)
    pr.*
  INTO price
  FROM sales.product_price pp
  INNER JOIN sales.price pr
    ON pr.price_uuid = pp.price_uuid
  WHERE pp.product_id = $1
    pr.created < $2 AND
    (pr.end_at IS NULL OR pr.end_at < $2)
  ORDER BY pp.product_id, pr.created DESC;
  
  -- Get any named margins or markups. Since margin has precedence, get it
  -- before markup
  IF price.margin_id IS NOT NULL THEN
    SELECT
      mg.amount INTO price.margin
    FROM sales.margin mg
    WHERE mg.margin_id = price.margin_id;
  ELSIF price.markup_id IS NOT NULL THEN
    SELECT
      mk.amount INTO price.margin
    FROM sales.markup mk
    WHERE mk.markup_id = price.markup_id;
  END IF;
  
  IF price.price IS NOT NULL THEN
    result.price = price.price;
    result.gross = (price.price * 0.909090909)::numeric(10,2);
  ELSIF price.gross IS NOT NULL THEN
    result.price = (price.gross * 1.1)::numeric(10,2);
    result.gross = price.gross;
    
    IF cost.amount IS NOT NULL THEN
      profit = result.gross - cost.amount;
      result.margin = (profit / result.gross)::numeric(4,3);
    END IF;
  ELSIF cost.amount IS NOT NULL AND price.margin IS NOT NULL THEN
    result.gross = (cost.amount / (1.000 - price.margin));
    result.margin = price.margin;
  ELSIF cost.amount IS NOT NULL THEN
    result.gross = cost.amount;
    result.price = (result.gross * 1.1)::numeric(10,2);
  END IF;

  -- The default tax_excluded value is false
  result.tax_excluded = COALESCE(price.tax_excluded, FALSE);

  RETURN result;
END
$$
LANGUAGE 'plpgsql';

/**
 * Compute the pricing for a product at a given point in time.
 */

CREATE OR REPLACE FUNCTION sales.product_price (cost prd.cost, price sales.price) RETURNS sales.price AS
$$
DECLARE
  result sales.price;
BEGIN  
  -- Get any named margins or markups. Since margin has precedence, get it
  -- before markup
  IF sales.product_price.price.margin_id IS NOT NULL THEN
    SELECT
      mg.amount INTO price.margin
    FROM sales.margin mg
    WHERE mg.margin_id = sales.product_price.price.margin_id;
  ELSIF sales.product_price.price.markup_id IS NOT NULL THEN
    SELECT
      mk.amount INTO sales.product_price.price.margin
    FROM sales.markup mk
    WHERE mk.markup_id = price.markup_id;
  END IF;
  
  IF sales.product_price.price.price IS NOT NULL THEN
    result.price = price.price;
    result.gross = (price.price * 0.909090909)::numeric(10,2);
  ELSIF sales.product_price.price.gross IS NOT NULL THEN
    result.price = (price.gross * 1.1)::numeric(10,2);
    result.gross = price.gross;
    
    IF sales.product_price.cost.amount IS NOT NULL THEN
      profit = result.gross - sales.product_price.cost.amount;
      result.margin = (profit / result.gross)::numeric(4,3);
    END IF;
  ELSIF sales.product_price.cost.amount IS NOT NULL AND sales.product_price.price.margin IS NOT NULL THEN
    result.gross = (sales.product_price.cost.amount / (1.000 - sales.product_price.price.margin));
    result.margin = sales.product_price.price.margin;
  ELSIF cost.amount IS NOT NULL THEN
    result.gross = sales.product_price.cost.amount;
    result.price = (result.gross * 1.1)::numeric(10,2);
  END IF;

  -- The default tax_excluded value is false
  result.tax_excluded = COALESCE(price.tax_excluded, FALSE);

  RETURN result;
END
$$
LANGUAGE 'plpgsql';