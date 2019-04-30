/**
 * sales.create_price
 *
 * Create a price for an entity.
 *
 * Prices can be associated with Products, Line Items and Orders. Prices should
 * not be updated. Creating a new price for each change, produces a price
 * history.
 *
 */
 
CREATE OR REPLACE FUNCTION sales.create_price (json, OUT result json) AS
$$
DECLARE
  payload   RECORD;
  new_price sales.price;
BEGIN
  SELECT INTO payload
    p.*
  FROM json_to_record($1) AS p (
    product_id   integer,
    line_item_id integer,
    order_id     integer,
    gross        numeric(10,2),
    price        numeric(10,2),
    margin       numeric(4,3),
    margin_id    integer,
    markup       numeric(5,2),
    markup_id    integer,
    tax_excluded boolean
  );

  INSERT INTO sales.price (
    gross,
    price,
    margin,
    margin_id,
    markup,
    markup_id,
    tax_excluded
  ) VALUES (
    payload.gross,
    payload.price,
    payload.margin,
    payload.margin_id,
    payload.markup,
    payload.markup_id,
    payload.tax_excluded
  )
  RETURNING * INTO new_price;

  IF payload.product_id IS NOT NULL THEN
    INSERT INTO sales.product_price (
      product_id,
      price_uuid
    ) VALUES (
      payload.product_id,
      new_price.price_uuid
    );
  ELSIF payload.line_item_id IS NOT NULL THEN
    INSERT INTO sales.line_item_price (
      line_item_id,
      price_uuid
    ) VALUES (
      payload.line_item_id,
      new_price.price_uuid
    );
  ELSIF payload.order_id IS NOT NULL THEN
    INSERT INTO sales.order_price (
      order_id,
      price_uuid
    ) VALUES (
      payload.order_id,
      new_price.price_uuid
    );
  END IF;

  SELECT INTO result
    json_strip_nulls(to_json(new_price));
END
$$
LANGUAGE 'plpgsql' SECURITY DEFINER;
