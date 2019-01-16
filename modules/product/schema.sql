CREATE TYPE product_t AS ENUM ('PRODUCT', 'SERVICE', 'FAMILY', 'CATEGORY');
CREATE TYPE rounding_rule_t AS ENUM ('NONE', 'NEAREST_INTEGER', 'ROUND_UP');

CREATE TYPE prd.product_uom_t AS (
  "uomId"        integer,
  name           text,
  abbr           text,
  type           text,
  divide         numeric(10,3),
  multiply       numeric(10,3),
  "roundingRule" rounding_rule_t
);

CREATE SCHEMA prd
  CREATE TABLE uom (
    uom_id     serial PRIMARY KEY,
    name       text,
    abbr       text,
    type       text
  )

  CREATE TABLE product (
    product_id        serial PRIMARY KEY,
    family_id         integer REFERENCES product (product_id) ON DELETE SET NULL,
    prototype_id      integer REFERENCES product (product_id) ON DELETE CASCADE,
    type              product_t DEFAULT 'PRODUCT',
    name              text,
    short_desc        text,
    description       text,
    url               text,
    code              text,
    sku               text UNIQUE,
    manufacturer_id   integer REFERENCES party (party_id) ON DELETE SET NULL,
    manufacturer_code text,
    supplier_id       integer REFERENCES party (party_id) ON DELETE SET NULL,
    supplier_code     text,
    -- Text search vector
    tsv               tsvector,
    data              jsonb,
    -- The product_uom referenced here is the primary uom of the product
    primary_uom_id    integer REFERENCES product_uom (product_uom_id) ON DELETE RESTRICT,
    created           timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at            timestamp,
    modified          timestamp DEFAULT CURRENT_TIMESTAMP,
    -- A product must have it's own name or get one from it's family
    CONSTRAINT valid_name CHECK(family_id IS NOT NULL OR name IS NOT NULL)
  )

  CREATE TABLE product_attribute (
    attribute_id serial PRIMARY KEY,
    product_id   integer REFERENCES product (product_id) ON DELETE CASCADE,
    name         text,
    value        text,
    created      timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by   integer REFERENCES party (party_id) ON DELETE SET NULL,
    modified     timestamp,
    UNIQUE (product_id, name)
  )

  CREATE TABLE gtin (
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE,
    value      text
  )

  CREATE TABLE component (
    component_id serial PRIMARY KEY,
    parent_id    integer REFERENCES product (product_id) ON DELETE CASCADE,
    product_id   integer REFERENCES product (product_id) ON DELETE CASCADE,
    uom_id       integer REFERENCES uom (uom_id) ON DELETE RESTRICT,
    quantity     numeric(10,3) DEFAULT 1,
    created      timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at       timestamp
  )

  CREATE TABLE product_tag (
    tag_id     integer REFERENCES tag (tag_id) ON DELETE CASCADE,
    product_id integer REFERENCES product (product_id) ON DELETE CASCADE
  )

  CREATE TABLE margin (
    margin_id serial PRIMARY KEY,
    name      text,
    amount    numeric(4,3),
    created   timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at    timestamp,
    CONSTRAINT amount_value CHECK(amount > 0.000 AND amount < 1.000)
  )

  CREATE TABLE markup (
    markup_id serial PRIMARY KEY,
    name      text,
    amount    numeric(10,2),
    created   timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at    timestamp
  )

  CREATE TABLE price (
    price_id         serial PRIMARY KEY,
    product_id       integer REFERENCES product (product_id) ON DELETE CASCADE,
    product_uom_id   integer REFERENCES product_uom (product_uom_id) ON DELETE CASCADE,
    cost             numeric(10,2),
    gross            numeric(10,2),
    price            numeric(10,2),
    margin           numeric(4,3),
    margin_id        integer REFERENCES margin (margin_id) ON DELETE SET NULL,
    markup           numeric(10,2),
    markup_id        integer REFERENCES markup (markup_id) ON DELETE SET NULL,
    tax_excluded     boolean,
    created          timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at           timestamp,
    CONSTRAINT margin_value CHECK(margin > 0 AND margin < 1)
  )

  CREATE TABLE product_uom (
    product_uom_id serial PRIMARY KEY,
    product_id     integer REFERENCES product (product_id) ON DELETE CASCADE,
    uom_id         integer REFERENCES uom (uom_id) ON DELETE CASCADE,
    weight         numeric(8,3),
    divide         numeric(10,3),
    multiply       numeric(10,3),
    rounding_rule  rounding_rule_t DEFAULT 'NONE',
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    modified       timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by     integer REFERENCES party (party_id),
    UNIQUE (product_id, uom_id)
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

  CREATE OR REPLACE VIEW product_list_v AS
    SELECT
      p.product_id,
      p.type,
      COALESCE(p.sku, p.code, p.supplier_code, p.manufacturer_code, fam.code) AS code,
      COALESCE(p.name, fam.name) AS name,
      COALESCE(p.short_desc, fam.short_desc) AS short_desc,
      p.created,
      p.modified
    FROM prd.product p
    LEFT JOIN prd.product fam
      ON fam.product_id = p.family_id

  -- This view will only return correct results for non composite products.
  -- Use prd.product_uom() to get results for all products
  CREATE OR REPLACE VIEW prd.product_uom_v AS
    SELECT
      uom.product_uom_id,
      uom.uom_id,
      uom.product_id,
      CASE
        WHEN modifier.is_primary IS TRUE OR uom.weight IS NOT NULL THEN
            uom.weight
        ELSE (prm.weight * modifier.value)
      END AS weight,
      uom.rounding_rule,
      p.primary_uom_id = uom.product_uom_id AS is_primary,
      price.price_id,
      CASE
        WHEN modifier.is_primary IS TRUE THEN
            price.cost
        ELSE (price.cost * modifier.value)::numeric(10,2)
      END AS cost,
      CASE
        WHEN modifier.is_primary IS TRUE THEN
            price.gross
        ELSE (price.gross * modifier.value)::numeric(10,2)
      END AS gross,
      CASE
        WHEN modifier.is_primary IS TRUE THEN
            n.price
        ELSE (n.price * modifier.value)::numeric(10,2)
      END AS price,
      t.tax_amount,
      u.name,
      u.abbr,
      u.type
    FROM prd.product p
    LEFT JOIN prd.product_uom prm -- Primary uom
      ON prm.product_uom_id = p.primary_uom_id
    LEFT JOIN prd.product_uom uom
      ON uom.product_id = p.product_id
    LEFT JOIN prd.uom u
      ON u.uom_id = uom.uom_id
    LEFT JOIN LATERAL (
      SELECT
        uom.product_uom_id,
        uom.product_uom_id = prm.product_uom_id AS is_primary,
        (coalesce(uom.multiply, 1.000) / coalesce(uom.divide, 1.000))::numeric AS value
    ) modifier ON modifier.product_uom_id = uom.product_uom_id
    -- Price data and gross price
    LEFT JOIN LATERAL (
      SELECT DISTINCT ON (pr.product_uom_id)
        pr.product_uom_id,
        pr.price_id,
        pr.cost,
        CASE
          WHEN pr.price IS NOT NULL THEN
            (pr.price * 0.90909)::numeric(10,2) -- TODO get rid of this constant
          WHEN pr.gross IS NOT NULL THEN
            pr.gross
          WHEN pr.margin IS NOT NULL THEN
            (pr.cost / (1 - pr.margin))::numeric(10,2)
          WHEN mg.amount IS NOT NULL THEN
            (pr.cost / (1 - mg.amount))::numeric(10,2)
          WHEN pr.markup IS NOT NULL THEN
            (pr.cost * (1 + pr.markup))::numeric(10,2)
          WHEN mk.amount IS NOT NULL THEN
            (pr.cost * (1 + mk.amount))::numeric(10,2)
          ELSE NULL
        END AS gross,
        pr.price
      FROM prd.price pr
      LEFT JOIN prd.margin mg
        ON mg.margin_id = pr.margin_id
      LEFT JOIN prd.markup mk
        ON mk.markup_id = pr.markup_id
      WHERE pr.product_uom_id = uom.product_uom_id
        AND (
          pr.cost IS NOT NULL OR pr.gross IS NOT NULL OR pr.net IS NOT NULL
        )
      ORDER BY pr.product_uom_id, pr.price_id DESC
    ) price ON price.product_uom_id = uom.product_uom_id
    -- Net Price
    LEFT JOIN LATERAL (
      SELECT
        price.product_uom_id,
        CASE
          WHEN price.price IS NOT NULL THEN
            price.price
          ELSE (price.gross * 1.1)::numeric(10,2)
        END AS price
    ) n ON n.product_uom_id = uom.product_uom_id
    -- Tax
    LEFT JOIN LATERAL (
      SELECT
        price.product_uom_id,
        (n.price - price.gross)::numeric(10,2) AS tax_amount
    ) t ON t.product_uom_id = uom.product_uom_id

  -- For viewing a product as a line item
  CREATE OR REPLACE VIEW line_item_v AS
    SELECT
      -- Where fields are null determine values by using divide or multiply with
      -- the primary_uom's values
      coalesce(uom.weight, prim_uom.weight * uom.multiply / uom.divide) AS weight
    FROM product p
    INNER JOIN product_uom prim_uom
      USING (product_uom_id)
    LEFT JOIN product_uom uom
      ON uom.product_id = p.product_id;

--
-- Triggers
--

-- Update modified column automatically and update parents
CREATE OR REPLACE FUNCTION prd.product_update_tg () RETURNS TRIGGER AS
$$
BEGIN
  NEW.modified = CURRENT_TIMESTAMP;

  -- Update parent products
  UPDATE prd.product p SET (
    modified
  ) = (
    CURRENT_TIMESTAMP
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
CREATE OR REPLACE FUNCTION prd.price_insert_tg () RETURNS TRIGGER AS
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
  FOR EACH ROW EXECUTE PROCEDURE prd.price_insert_tg();

CREATE FUNCTION product_weighted_tsv_trigger() RETURNS trigger AS
$$
BEGIN
  new.tsv :=
     setweight(to_tsvector('simple', COALESCE(new.name,'')), 'A') ||
     setweight(to_tsvector('simple', COALESCE(new.code,'')), 'A') ||
     setweight(to_tsvector('simple', COALESCE(new.sku,'')), 'A') ||
     setweight(to_tsvector('english', COALESCE(new.short_desc,'')), 'B');

  RETURN new;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER upd_product_tsvector BEFORE INSERT OR UPDATE ON prd.product
FOR EACH ROW EXECUTE PROCEDURE product_weighted_tsv_trigger();
