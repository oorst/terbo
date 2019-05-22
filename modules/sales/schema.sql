/*
 * SALES
 *
 * Prerequisites: Product
 *
 */

-- Enables creation of uuids
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA sales;

CREATE TYPE sales.document_status_t AS ENUM ('DRAFT', 'ISSUED', 'DELETED', 'VOID');
CREATE TYPE sales.payment_status_t AS ENUM ('OWING', 'PAID');

CREATE TYPE sales.order_status_t AS ENUM ('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'FULFILLED', 'DELIVERED');
CREATE TYPE sales.line_item_t AS (
  line_item_uuid  uuid,
  order_uuid      uuid,
  product_uuid    uuid,
  line_position   smallint,
  code            text,
  sku             text,
  name            text,
  short_desc      text,
  uom_id          integer,
  uom_name        text,
  uom_abbr        text,
  quantity        numeric(10,3),
  tax_excluded    boolean,
  delivery_id     integer,
  created         timestamptz,
  modified        timestamptz
);

CREATE TYPE sales.price_t AS (
  price_uuid       uuid,
  gross            numeric(10,2),
  price            numeric(10,2),
  margin           numeric(4,3),
  margin_id        integer,
  markup           numeric(10,2),
  markup_id        integer,
  tax_excluded     boolean,
  note             uuid,
  created          timestamptz,
  end_at           timestamptz,
  gross_is_set     boolean,
  price_is_set     boolean
);

CREATE TABLE sales.customer (
  customer_uuid uuid REFERENCES core.party (party_uuid) ON DELETE CASCADE,
  quote_period  smallint DEFAULT 30,
  PRIMARY KEY (customer_uuid)
);

CREATE TABLE sales.order (
  order_uuid          uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  customer_uuid       uuid REFERENCES core.party (party_uuid) ON DELETE RESTRICT,
  contact_uuid        uuid REFERENCES core.party (party_uuid),
  invoice_uuid        uuid REFERENCES ar.invoice (invoice_uuid) ON DELETE RESTRICT,
  status              sales.order_status_t DEFAULT 'PENDING',
  status_changed      timestamptz,
  short_desc          text,
  nickname            text,
  data                jsonb,
  tsv                 tsvector,
  created             timestamptz DEFAULT CURRENT_TIMESTAMP,
  created_by          uuid REFERENCES core.person (party_uuid),
  modified            timestamptz DEFAULT CURRENT_TIMESTAMP
);

-- Partial Invoice links invoices where a partial payment or deposit is made
-- CREATE TABLE sales.partial_invoice (
--   parent_uuid  uuid REFERENCES sales.invoice (invoice_uuid) ON DELETE CASCADE,
--   invoice_uuid uuid REFERENCES sales.invoice (invoice_uuid) ON DELETE CASCADE,
--   PRIMARY KEY (parent_uuid, invoice_uuid)
-- );

CREATE TABLE sales.quote (
  quote_uuid    uuid REFERENCES core.document (document_uuid) ON DELETE CASCADE,
  order_uuid    uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  expiry_date   timestamptz,
  notes         core.note[],
  creator_uuid  uuid REFERENCES core.party (party_uuid),
  PRIMARY KEY (quote_uuid)
);

CREATE TABLE sales.line_item (
  line_item_uuid      uuid REFERENCES ar.invoice_detail (detail_uuid) PRIMARY KEY,
  order_uuid          uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  product_uuid        uuid REFERENCES prd.product (product_uuid) ON DELETE RESTRICT,
  line_position       smallint,
  name                text,
  short_desc          text,
  gross               numeric(10,2),
  price               numeric(10,2),
  discount            numeric(5,2),
  uom_id              integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
  quantity            numeric(10,3),
  tax                 boolean DEFAULT TRUE,
  created             timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified            timestamptz,
  end_at              timestamptz
);

CREATE TABLE sales.margin (
  margin_id serial PRIMARY KEY,
  name      text,
  amount    numeric(4,3),
  created   timestamptz DEFAULT CURRENT_TIMESTAMP,
  end_at    timestamptz,
  CONSTRAINT amount_value CHECK(amount > 0 AND amount < 1)
);

CREATE TABLE sales.markup (
  markup_id serial PRIMARY KEY,
  name      text,
  amount    numeric(10,2),
  created   timestamptz DEFAULT CURRENT_TIMESTAMP,
  end_at    timestamptz
);

CREATE TABLE sales.price (
  price_uuid       uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  price            numeric(10,2),
  amount_payable   numeric(10,2),
  margin           numeric(4,3),
  margin_id        integer REFERENCES sales.margin (margin_id) ON DELETE SET NULL,
  markup           numeric(10,2),
  markup_id        integer REFERENCES sales.markup (markup_id) ON DELETE SET NULL,
  tax_excluded     boolean DEFAULT FALSE,
  note             uuid REFERENCES core.note (note_uuid),
  created          timestamptz DEFAULT NOW(),
  end_at           timestamptz,
  CONSTRAINT margin_value CHECK(margin > 0 AND margin < 1)
);

CREATE TABLE sales.discount (
  discount_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  percent       numeric(5,2),
  amount        numeric(10,2),
  created       timestamptz DEFAULT NOW(),
  modified      timestamptz,
  end_at        timestamptz
);

CREATE TABLE sales.tax (
  tax_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name     text,
  percent  numeric(5,2),
  created  timestamptz DEFAULT NOW(),
  modified timestamptz,
  end_at   timestamptz
);

--
-- Associative Tables
--

-- Pricing can be applied at the product, line item or order level so
-- associations are required for each.
CREATE TABLE sales.product_price (
  product_uuid uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  price_uuid   uuid REFERENCES sales.price (price_uuid) ON DELETE CASCADE,
  PRIMARY KEY (product_uuid, price_uuid)
);

CREATE TABLE sales.line_item_price (
  line_item_uuid uuid REFERENCES sales.line_item (line_item_uuid) ON DELETE CASCADE,
  price_uuid     uuid REFERENCES sales.price (price_uuid) ON DELETE CASCADE,
  PRIMARY KEY (line_item_uuid, price_uuid)
);

CREATE TABLE sales.order_price (
  order_uuid uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  price_uuid uuid REFERENCES sales.price (price_uuid) ON DELETE CASCADE,
  PRIMARY KEY (order_uuid, price_uuid)
);
  
-- Discounts can be applied at the product, line item or order level so
-- associations are required for each.
CREATE TABLE sales.product_discount (
  product_uuid  uuid REFERENCES prd.product (product_uuid) ON DELETE CASCADE,
  discount_uuid uuid REFERENCES sales.discount (discount_uuid) ON DELETE CASCADE,
  PRIMARY KEY (product_uuid, discount_uuid)
);

CREATE TABLE sales.line_item_discount (
  line_item_uuid  uuid REFERENCES sales.line_item (line_item_uuid) ON DELETE CASCADE,
  discount_uuid   uuid REFERENCES sales.discount (discount_uuid) ON DELETE CASCADE,
  PRIMARY KEY (line_item_uuid, discount_uuid)
);

CREATE TABLE sales.order_discount (
  order_uuid    uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  discount_uuid uuid REFERENCES sales.discount (discount_uuid) ON DELETE CASCADE,
  PRIMARY KEY (order_uuid, discount_uuid)
);

CREATE TABLE sales.line_item_note (
  line_item_uuid uuid REFERENCES sales.line_item (line_item_uuid) ON DELETE CASCADE,
  note_uuid      uuid REFERENCES core.note (note_uuid) ON DELETE CASCADE
);

CREATE TABLE sales.order_note (
  order_uuid uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  note_uuid  uuid REFERENCES core.note (note_uuid) ON DELETE CASCADE
);

--
-- Views
--

CREATE OR REPLACE VIEW sales.line_item_v AS
  SELECT
    li.line_item_uuid,
    li.order_uuid,
    li.product_uuid,
    COALESCE(li.name, p.name) AS name,
    COALESCE(li.short_desc, p.short_desc) AS short_desc,
    li.quantity,
    uom.name AS uom_name,
    uom.abbr AS uom_abbr,
    p.short_desc AS product_short_desc
  FROM sales.line_item li
  LEFT JOIN prd.product p
    ON p.product_uuid = li.product_uuid
  LEFT JOIN prd.uom uom
    ON uom.uom_id = p.uom_id;

CREATE OR REPLACE VIEW sales.price_v AS
  SELECT
    pr.price_uuid,
    pr.price,
    pr.amount_payable,
    COALESCE(pr.margin, mg.amount) AS margin,
    COALESCE(pr.markup, mk.amount) AS markup,
    pr.created,
    pr.end_at
  FROM sales.price pr
  LEFT JOIN sales.margin mg
    ON mg.margin_id = pr.margin_id
  LEFT JOIN sales.markup mk
    ON mk.markup_id = pr.markup_id;
    
CREATE OR REPLACE VIEW sales.quote_v AS
  SELECT
    q.quote_uuid,
    q.expiry_date,
    d.approval_status,
    d.created,
    o.order_uuid,
    p.name AS customer_name
  FROM sales.quote q
  INNER JOIN core.document d
    ON d.document_uuid = q.quote_uuid
  LEFT JOIN sales.order o
    ON o.order_uuid = q.order_uuid
  LEFT JOIN core.party p
    ON p.party_uuid = o.customer_uuid;

--
-- Triggers
--

/**
 * When inserting or updating, generate a text search vector for the order
 */
CREATE OR REPLACE FUNCTION sales.order_weighted_tsv_trigger() RETURNS trigger AS
$$
BEGIN
  SELECT
    setweight(to_tsvector('simple', pv.name), 'A') ||
    setweight(to_tsvector('simple', NEW.order_uuid::text), 'A')
  INTO
    NEW.tsv
  FROM core.party pv
  WHERE pv.party_uuid = NEW.customer_uuid;

  RETURN new;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER sales_order_tsv BEFORE INSERT OR UPDATE ON sales.order
FOR EACH ROW EXECUTE PROCEDURE sales.order_weighted_tsv_trigger();

/**
 * Create an associated ar.invoice_detail when creating a line_item
 */
CREATE OR REPLACE FUNCTION sales.insert_line_item_tg () RETURNS trigger AS
$$
BEGIN
  INSERT INTO ar.invoice_detail DEFAULT VALUES
  RETURNING detail_uuid INTO NEW.line_item_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';
 
CREATE TRIGGER sales_insert_line_item_tg BEFORE INSERT ON sales.line_item
FOR EACH ROW EXECUTE PROCEDURE sales.insert_line_item_tg();

/**
 * Create a new document when creating a new quote
 */
CREATE OR REPLACE FUNCTION sales.insert_quote_tg () RETURNS TRIGGER AS
$$
BEGIN
  INSERT INTO core.document (
    kind,
    origin,
    approval_status
  ) VALUES (
    'quote',
    'sales',
    'DRAFT'
  )
  RETURNING document_uuid INTO NEW.quote_uuid;

  RETURN NEW;
END
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER sales_quote_document_tg BEFORE INSERT ON sales.quote
FOR EACH ROW EXECUTE PROCEDURE sales.insert_quote_tg();
