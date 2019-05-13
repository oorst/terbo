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
  order_id        integer,
  product_id      integer,
  line_position   smallint,
  code            text,
  sku             text,
  name            text,
  short_desc      text,
  discount        numeric(5,2),
  line_item_gross numeric(10,2),  -- User defined gross of the line
  product_gross   numeric(10,2),
  line_item_price numeric(10,2),  -- User defined price of the line
  product_price   numeric(10,2),
  line_gross      numeric(10,2),  -- Computed gross of the line
  line_price      numeric(10,2),  -- Computed price of the line
  uom_id          integer,
  uom_name        text,
  uom_abbr        text,
  quantity        numeric(10,3),
  tax_excluded    boolean,
  delivery_id     integer,
  notes           core.note[],
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

CREATE TABLE sales.order (
  order_uuid          uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  customer_uuid       uuid REFERENCES core.party (party_uuid) ON DELETE SET NULL,
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

CREATE TABLE sales.invoice (
  invoice_uuid    uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_num     text,
  order_uuid      uuid REFERENCES sales.order (order_uuid) ON DELETE RESTRICT,
  recipient_id    uuid REFERENCES core.party (party_uuid) ON DELETE RESTRICT,
  contact_id      uuid REFERENCES core.person (party_uuid) ON DELETE SET NULL,
  period          integer NOT NULL DEFAULT 30,
  due_date        timestamp,
  status          sales.document_status_t DEFAULT 'DRAFT',
  payment_status  sales.payment_status_t DEFAULT 'OWING',
  short_desc      text,
  notes           text,
  data            jsonb,
  locale          
  issued_at       timestamp,
  created         timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by      uuid REFERENCES core.person (party_uuid) NOT NULL,
  modified        timestamp
);

-- Partial Invoice links invoices where a partial payment or deposit is made
CREATE TABLE sales.partial_invoice (
  parent_uuid  uuid REFERENCES sales.invoice (invoice_uuid) ON DELETE CASCADE,
  invoice_uuid uuid REFERENCES sales.invoice (invoice_uuid) ON DELETE CASCADE,
  PRIMARY KEY (parent_uuid, invoice_uuid)
);

CREATE TABLE sales.quote (
  quote_uuid  uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_uuid  uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  period      smallint NOT NULL DEFAULT 30,
  expiry_date date,
  contact_id  uuid REFERENCES core.person (party_uuid),
  notes       text,
  status      sales.document_status_t DEFAULT 'DRAFT',
  data        jsonb,
  issued_at   timestamp,
  created     timestamp DEFAULT CURRENT_TIMESTAMP,
  created_by  uuid REFERENCES core.person (party_uuid),
  modified    timestamp,
  CONSTRAINT valid_period CHECK(period >= 0)
);

CREATE TABLE sales.payment (
  payment_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_uuid uuid REFERENCES sales.invoice (invoice_uuid),
  ref_num      text,
  paid_at      timestamptz DEFAULT CURRENT_TIMESTAMP,
  amount       numeric(10,2),
  created      timestamptz DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sales.line_item (
  line_item_uuid      uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_uuid          uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  product_uuid        uuid REFERENCES prd.product (product_uuid) ON DELETE RESTRICT,
  line_position       smallint,
  name                text,
  short_desc          text,
  gross               numeric(10,2),
  price               numeric(10,2),
  uom_id              integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
  quantity            numeric(10,3),
  tax                 boolean DEFAULT TRUE,
  created             timestamptz DEFAULT CURRENT_TIMESTAMP,
  modified            timestamptz,
  end_at              timestamptz
);

CREATE TABLE sales.credit_item (
  credit_item_id      uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  order_uuid          uuid REFERENCES sales.order (order_uuid) ON DELETE CASCADE,
  line_position       smallint,
  short_desc          text,
  amount              numeric(10,2),
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
  gross            numeric(10,2),
  price            numeric(10,2),
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

CREATE OR REPLACE VIEW sales.price_v AS
  SELECT
    pr.price_uuid,
    pr.gross,
    pr.price,
    COALESCE(pr.margin, mg.amount) AS margin,
    COALESCE(pr.markup, mk.amount) AS markup,
    pr.created,
    pr.end_at
  FROM sales.price pr
  LEFT JOIN sales.margin mg
    ON mg.margin_id = pr.margin_id
  LEFT JOIN sales.markup mk
    ON mk.markup_id = pr.markup_id;

CREATE OR REPLACE VIEW sales.overdue_invoice_v AS
  SELECT
    i.invoice_uuid
  FROM sales.invoice i
  WHERE i.due_date < CURRENT_TIMESTAMP AND i.payment_status != 'PAID';

--
-- Triggers
--

/**
 * When inserting or updating, generate a text search vector for the order
 */
CREATE FUNCTION sales.order_weighted_tsv_trigger() RETURNS trigger AS
$$
BEGIN
  SELECT
    setweight(to_tsvector('simple', pv.name), 'A') ||
    setweight(to_tsvector('simple', NEW.order_uuid::text), 'A')
  INTO
    NEW.tsv
  FROM core.party_v pv
  WHERE pv.party_uuid = NEW.buyer_uuid;

  RETURN new;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER sales_order_tsv BEFORE INSERT OR UPDATE ON sales.order
FOR EACH ROW EXECUTE PROCEDURE sales.order_weighted_tsv_trigger();
