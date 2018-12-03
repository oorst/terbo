CREATE TYPE product_t AS ENUM ('PRODUCT', 'SERVICE');
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
    attributes        jsonb,
    tsv               tsvector,
    data              jsonb,
    tracked           boolean DEFAULT FALSE,
    uom_id            integer REFERENCES uom (uom_id) ON DELETE SET NULL,
    product_uom_id    integer REFERENCES product_uom (product_uom_id) ON DELETE RESTRICT,
    -- Weight in kilograms for every base unit of measure
    weight            numeric(10,3),
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
    product_id   integer REFERENCES product (product_id) ON DELETE CASCADE,
    parent_id    integer REFERENCES product (product_id) ON DELETE CASCADE,
    quantity    numeric(10,3) DEFAULT 1,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
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
    cost             numeric(10,2),
    cost_rate_uom_id integer REFERENCES uom (uom_id) ON DELETE RESTRICT,
    gross            numeric(10,2),
    net              numeric(10,2),
    margin           numeric(4,3),
    margin_id        integer REFERENCES margin (margin_id) ON DELETE SET NULL,
    markup           numeric(10,2),
    markup_id        integer REFERENCES markup (markup_id) ON DELETE SET NULL,
    tax              boolean,
    created          timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at           timestamp,
    CONSTRAINT margin_value CHECK(margin > 0 AND margin < 1)
  )

  CREATE TABLE product_uom (
    product_uom_id serial PRIMARY KEY,
    product_id     integer REFERENCES product (product_id) ON DELETE CASCADE,
    uom_id         integer REFERENCES uom (uom_id) ON DELETE CASCADE,
    price_id       integer REFERENCES price (price_id) ON DELETE SET NULL,
    divide         numeric(10,3),
    multiply       numeric(10,3),
    rounding_rule  rounding_rule_t DEFAULT 'NONE',
    primary_uom    boolean,
    created        timestamp DEFAULT CURRENT_TIMESTAMP,
    modified       timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by     integer REFERENCES party (party_id)
  )

  CREATE UNIQUE INDEX primary_uom
  ON prd.product_id (product_id)
  WHERE primary_uom IS TRUE;

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

  -- Get the current price record for a product.  The price given is for one unit of the PRoduct's primary unit.
  CREATE OR REPLACE VIEW price_v AS
    WITH RECURSIVE product AS (
      -- Select products and recurse where a product has child components
      SELECT DISTINCT ON (p.product_id)
        p.product_id AS root_id,
        p.product_id,
        1.000 AS quantity,
        NULL::integer AS parent_id,
        c.parent_id = p.product_id AS is_composite
      FROM prd.product p
      LEFT JOIN prd.component c
        ON c.parent_id = p.product_id

      UNION ALL

      SELECT
        p.root_id,
        c.product_id,
        (p.quantity * c.quantity)::numeric(10,3) AS quantity, -- Adjust quantities
        c.parent_id,
        cc.parent_id = c.product_id AS is_composite
      FROM product p
      INNER JOIN prd.component c
        ON c.parent_id = p.product_id
      LEFT JOIN prd.component cc
        ON cc.parent_id = c.product_id
      WHERE p.is_composite IS TRUE
    ),
    -- Get the current price and compute the markup
    current_price AS (
      SELECT DISTINCT ON (price.product_id)
        price.product_id,
        coalesce(
          price.margin,
          mg.amount,
          coalesce(price.markup, mk.amount) / (1 + coalesce(price.markup, mk.amount))
        ) AS margin,
        coalesce(
          coalesce(price.margin, mg.amount) / (1 - coalesce(price.margin, mg.amount)), -- Calculated markup has priority over set markup
          price.markup,
          mk.amount,
          0.00 -- Markup should not be NULL
        ) AS markup,
        price.cost,
        price.gross
      FROM prd.price price
      LEFT JOIN prd.margin mg
        USING (margin_id)
      LEFT JOIN prd.markup mk
        USING (markup_id)
      ORDER BY price.product_id, price.price_id DESC
    ),
    -- Compute the gross price
    computed_price AS (
      SELECT
        root_id,
        coalesce(
          price.gross,
          price.cost + (price.cost * price.markup)
        ) * product.quantity AS gross,
        price.cost * product.quantity AS cost
      FROM product
      INNER JOIN current_price price
        USING (product_id)
    ), sum AS (
      SELECT
        root_id AS product_id,
        sum(price.gross)::numeric(10,2) AS gross,
        sum(price.cost)::numeric(10,2) AS cost
      FROM computed_price price
      GROUP BY root_id
    )
    SELECT
      product_id,
      gross,
      cost,
      gross - cost AS profit,
      ((gross - cost) / gross)::numeric(4,3) AS margin
    FROM sum;

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
