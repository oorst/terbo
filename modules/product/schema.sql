CREATE SCHEMA prd
  CREATE TABLE uom (
    uom_id     serial PRIMARY KEY,
    name       text,
    abbr       text,
    type       text
  )

  CREATE TABLE composition (
    composition_id serial PRIMARY KEY,
    -- When retrieving a bill of quantities, return separate entries if true
    explode       boolean DEFAULT false NOT NULL
  )

  CREATE TABLE product (
    product_id        serial PRIMARY KEY,
    family_id         integer REFERENCES product (product_id),
    type              text DEFAULT 'product',
    name              text,
    description       text,
    url               text,
    code              text,
    sku               text UNIQUE,
    manufacturer_id   integer REFERENCES party (party_id) ON DELETE SET NULL,
    manufacturer_code text,
    supplier_id       integer REFERENCES party (party_id) ON DELETE SET NULL,
    supplier_code     text,
    data              jsonb,
    uom_id            integer REFERENCES uom (uom_id) ON DELETE SET NULL,
    -- Weight in kilograms for every base unit of measure
    weight            numeric(10,3),
    composition_id    integer REFERENCES composition (composition_id) ON DELETE SET NULL,
    created           timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at            timestamp,
    modified          timestamp DEFAULT CURRENT_TIMESTAMP,
    CHECK (type IN ('product', 'service')),
    -- A product must have it's own name or get one from it's family
    CONSTRAINT valid_name CHECK(family_id IS NOT NULL OR name IS NOT NULL)
  )

  CREATE TABLE gtin (
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE,
    value      text
  )

  CREATE TABLE product_uom (
    product_uom_id serial PRIMARY KEY,
    product_id     integer REFERENCES product (product_id) ON DELETE CASCADE,
    uom_id         integer REFERENCES uom (uom_id) ON DELETE CASCADE,
    -- Multiply and divide provide ways of converting the base uom
    multiply       numeric,
    divide         numeric,
    UNIQUE(product_id, uom_id)
  )

  CREATE TABLE component (
    component_id serial PRIMARY KEY,
    product_id   integer REFERENCES product (product_id) ON DELETE CASCADE,
    parent_id    integer REFERENCES product (product_id) ON DELETE CASCADE,
    quantity     numeric(10,3) DEFAULT 1,
    created      timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at       timestamp
  )

  CREATE TABLE tag (
    tag_id     serial PRIMARY KEY,
    name       text UNIQUE
  )

  CREATE TABLE product_tag (
    tag_id     integer REFERENCES tag (tag_id) ON DELETE CASCADE,
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE
  )

  CREATE VIEW product_tag_v AS
    SELECT
      p.product_id,
      t.name
    FROM product p
    INNER JOIN product_tag
      USING (product_id)
    INNER JOIN tag t
      USING (tag_id)

  -- Refs are an indirect way of referencing a product. They are similar to a
  -- product code, but where a product code must be unique, refs can be
  -- repeated on many products and a product can have many refs.
  -- Refs are different to tags in that tags are meant specifically for
  -- searching and categorization.
  CREATE TABLE ref (
    ref_id serial PRIMARY KEY,
    name   text UNIQUE
  )

  CREATE TABLE product_ref (
    ref_id     integer REFERENCES ref (ref_id) ON DELETE CASCADE,
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE
  )

  CREATE TABLE cost (
    cost_id   serial PRIMARY KEY,
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE,
    amount     numeric(10,2),
    created    timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at     timestamp
  )

  CREATE TABLE markup (
    markup_id serial PRIMARY KEY,
    name      text,
    -- Percentage markup
    amount    numeric(10,2),
    created   timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at    timestamp
  )

  CREATE TABLE price (
    price_id   serial PRIMARY KEY,
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE,
    gross      numeric(10,2),
    net        numeric(10,2),
    -- Percentage markup on the Product Cost
    markup     numeric(10,2),
    markup_id  integer REFERENCES markup (markup_id) ON DELETE SET NULL,
    created    timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at     timestamp
  )

  -- Do not use this view for composite products.  Only get_product() will
  -- reurn pricing for a composite
  CREATE OR REPLACE VIEW product_pricing_v AS
    SELECT
      p.product_id,
      cost.amount AS cost,
      price.markup,
      COALESCE(price.gross, cost.amount * (1 + price.markup / 100.00))::numeric(10,2) AS gross
    FROM product p
    LEFT JOIN (
      SELECT DISTINCT ON (cost.product_id)
        cost.product_id,
        cost.cost_id,
        cost.amount
      FROM cost
      WHERE cost.end_at > CURRENT_TIMESTAMP OR cost.end_at IS NULL
      ORDER BY cost.product_id, cost.cost_id DESC
    ) cost
      USING (product_id)
    LEFT JOIN (
      SELECT DISTINCT ON (price.product_id)
        price.product_id,
        price.price_id,
        price.gross,
        price.net,
        COALESCE(price.markup, markup.amount) AS markup
      FROM price price
      LEFT JOIN markup
        USING (markup_id)
      ORDER BY price.product_id, price.price_id DESC
    ) price
      USING (product_id)

  CREATE OR REPLACE VIEW product_abbr_v AS
    SELECT
      p.product_id,
      p.type,
      COALESCE(p.code, fam.code) AS code,
      COALESCE(p.sku, fam.sku) AS sku,
      COALESCE(p.manufacturer_code, fam.manufacturer_code) AS manufacturer_code,
      COALESCE(p.supplier_code, fam.supplier_code) AS supplier_code,
      COALESCE(p.name, fam.name) AS name,
      COALESCE(p.description, fam.description) AS description,
      p.created,
      p.modified
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id

  CREATE OR REPLACE VIEW product_list_v AS
    SELECT
      p.product_id,
      p.type,
      p.sku,
      COALESCE(p.sku, p.code, p.supplier_code, p.manufacturer_code, fam.code) AS _code,
      COALESCE(p.name, fam.name) AS _name,
      COALESCE(p.description, fam.description) AS _description,
      p.created,
      p.modified
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id

  CREATE OR REPLACE VIEW product_v AS
    SELECT
      p.product_id,
      p.family_id,
      p.manufacturer_id,
      p.manufacturer_code,
      p.supplier_id,
      p.supplier_code,
      p.code,
      p.sku,
      COALESCE(p.name, fam.name) AS name,
      p.description,
      p.data,
      p.type,
      p.uom_id,
      p.weight,
      p.created,
      p.end_at,
      p.modified,
      (
        SELECT json_strip_nulls(to_json(f))
        FROM (
          SELECT
            fam.manufacturer_id,
            fam.manufacturer_code,
            fam.supplier_id,
            fam.supplier_code,
            fam.code,
            fam.sku
        ) f
        WHERE NOT (f IS NULL)
      ) AS family,
      (
        SELECT
          array_agg(tag.name)
        FROM prd.product_tag pt
        INNER JOIN prd.tag tag
          USING (tag_id)
        WHERE pt.product_id = p.product_id
      ) AS tags,
      cost.cost_id,
      cost.amount AS cost,
      cost.created AS cost_created,
      price.price_id,
      price.gross,
      price.net,
      price.markup,
      price.created AS price_created,
      markup.name AS markup_name,
      markup.amount AS markup_amount,
      markup.created AS markup_created,
      uom.name AS uom_name,
      uom.abbr AS uom_abbr,
      uom.type AS uom_type
    FROM prd.product p
    LEFT JOIN prd.uom uom
      USING (uom_id)
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (cost.product_id)
        *
      FROM prd.cost cost
      WHERE cost.product_id = p.product_id
      ORDER BY cost.product_id, cost.cost_id DESC
    ) cost
      ON cost.product_id = p.product_id
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (price.product_id)
        *
      FROM prd.price price
      WHERE price.product_id = p.product_id
      ORDER BY price.product_id, price.price_id DESC
    ) price
      ON price.product_id = p.product_id
    LEFT JOIN prd.markup markup
      ON markup.markup_id = price.markup_id; -- end CREATE SCHEMA prd

--
-- Triggers
--

-- Update modified column automatically and update parents
CREATE OR REPLACE FUNCTION prd.product_update_tg () RETURNS TRIGGER AS
$$
DECLARE
  now timestamp := CURRENT_TIMESTAMP;
BEGIN
  SELECT now INTO NEW.modified;

  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    now
  )
  FROM prd.component c
  WHERE p.product_id = c.parent_id AND c.product_id = NEW.product_id;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER product_update_tg BEFORE UPDATE ON prd.product
  FOR EACH ROW EXECUTE PROCEDURE prd.product_update_tg();

-- Update parents on component update
CREATE OR REPLACE FUNCTION prd.component_update_tg () RETURNS TRIGGER AS
$$
BEGIN
  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
  )
  FROM prd.component c
  WHERE p.product_id = c.product_id AND c.component_id = NEW.component_id;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER product_update_tg BEFORE UPDATE ON prd.component
  FOR EACH ROW EXECUTE PROCEDURE prd.component_update_tg();

-- Update products when cost or pricing has changed
CREATE OR REPLACE FUNCTION prd.price_cost_insert_tg () RETURNS TRIGGER AS
$$
BEGIN
  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
  )
  WHERE p.product_id = NEW.product_id;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER price_insert_tg AFTER INSERT ON prd.price
  FOR EACH ROW EXECUTE PROCEDURE prd.price_cost_insert_tg();

CREATE TRIGGER cost_insert_tg AFTER INSERT ON prd.cost
  FOR EACH ROW EXECUTE PROCEDURE prd.price_cost_insert_tg();
