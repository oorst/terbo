DROP FUNCTION prd.product_uom(integer, integer);
CREATE OR REPLACE FUNCTION prd.product_uom (
  _product_id integer,
  _uom_id     integer DEFAULT NULL
) RETURNS TABLE (
  product_id   integer,
  uom_id       integer,
  cost         numeric(10,2),
  gross        numeric(10,2),
  price        numeric(10,2),
  weight       numeric(8,3)
) AS
$$
DECLARE
  _item_uuid uuid := (
    SELECT product_uuid FROM prd.product q WHERE q.product_id = _product_id
  );
BEGIN
  IF _item_uuid IS NOT NULL THEN
    RETURN QUERY
    SELECT * FROM prd.product_uom(_item_uuid, _uom_id);
  ELSE
    RETURN QUERY
    -- Adjust the quantities with respect to the given uom_id
    WITH component AS (
      SELECT
        f.*
      FROM prd.flatten_product(_product_id, _uom_id) f
      WHERE f.is_leaf IS TRUE
    ), product AS (
      SELECT
        sum(pu.cost * c.quantity)::numeric(10,2) AS cost,
        sum(pu.gross * c.quantity)::numeric(10,2) AS gross,
        sum(NULL::numeric(10,2))::numeric(10,2) AS price, -- TODO implement this part
        sum(pu.weight * c.quantity)::numeric(8,3) AS weight
      FROM component c
      LEFT JOIN prd.product_uom_v pu
        ON pu.product_id = c.product_id
          AND (
            (pu.uom_id = c.uom_id) OR (pu.is_primary IS TRUE) OR (pu.uom_id = _uom_id)
          )
    )
    SELECT
      _product_id AS product_id,
      _uom_id AS uom_id,
      p.*
    FROM product p;
  END IF;
END
$$
LANGUAGE 'plpgsql';


/**
Return a product_uom for an item
*/
DROP FUNCTION prd.product_uom(uuid, integer);
CREATE OR REPLACE FUNCTION prd.product_uom (
  _item_uuid uuid,
  _uom_id  integer DEFAULT NULL
) RETURNS TABLE (
  product_id   integer,
  uom_id       integer,
  cost         numeric(10,2),
  gross_price  numeric(10,2),
  weight       numeric(8,3)
) AS
$$
DECLARE
  _product_id integer := (
    SELECT i.product_id FROM scm.item i WHERE item_uuid = _item_uuid
  );
BEGIN
  --
  RETURN QUERY
  WITH product AS (
    SELECT
      sum((pu.cost * boq.quantity)::numeric(10,2))::numeric(10,2) AS cost,
      sum((pu.gross_price * boq.quantity)::numeric(10,2))::numeric(10,2) AS gross_price,
      sum((pu.weight * boq.quantity)::numeric(8,3)) AS weight
    FROM scm.boq(_item_uuid) boq
    LEFT JOIN prd.product_uom(boq.product_id, boq.uom_id) pu
      ON pu.product_id = boq.product_id
  )
  SELECT
    _product_id AS product_id,
    _uom_id AS uom_id,
    p.*
  FROM product p;
END
$$
LANGUAGE 'plpgsql';
