CREATE TYPE document_status_t AS ENUM ('DRAFT', 'ISSUED', 'DELETED', 'VOID');
CREATE TYPE order_status_t AS ENUM ('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'FULFILLED', 'DELIVERED');
CREATE TYPE payment_status_t AS ENUM ('OWING', 'PAID');
CREATE TYPE li_note_importance_t AS ENUM ('NORMAL', 'IMPORTANT');

CREATE SCHEMA sales
  CREATE TABLE sales.order (
    order_id            serial PRIMARY KEY,
    buyer_id            integer REFERENCES party (party_id) ON DELETE SET NULL,
    status              order_status_t DEFAULT 'PENDING',
    short_desc          text,
    data                jsonb,
    notes               text,
    memo                text,
    purchase_order_num  text,
    created             timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by          integer REFERENCES person (party_id) NOT NULL,
    modified            timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE invoice (
    invoice_id      serial PRIMARY KEY,
    invoice_num     text,
    order_id        integer REFERENCES sales.order (order_id) ON DELETE RESTRICT,
    recipient_id    integer REFERENCES party (party_id) ON DELETE RESTRICT,
    contact_id      integer REFERENCES person (party_id) ON DELETE SET NULL,
    period          integer NOT NULL DEFAULT 30,
    due_date        timestamp,
    status          document_status_t DEFAULT 'DRAFT',
    payment_status  payment_status_t DEFAULT 'OWING',
    short_desc      text,
    notes           text,
    data            jsonb,
    issued_at       timestamp,
    created         timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by      integer REFERENCES person (party_id) NOT NULL,
    modified        timestamp
  )

  CREATE TABLE invoice_memo (
    memo_id    serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    body       text,
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  -- Partial Invoice links invoices where a partial payment or deposit is made
  CREATE TABLE partial_invoice (
    parent_id  integer REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    invoice_id integer REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    PRIMARY KEY (parent_id, invoice_id)
  )

  CREATE TABLE quote (
    quote_id    serial PRIMARY KEY,
    order_id    integer REFERENCES sales.order (order_id) ON DELETE CASCADE,
    period      smallint NOT NULL DEFAULT 30,
    expiry_date date,
    contact_id  integer REFERENCES person (party_id),
    notes       text,
    status      document_status_t DEFAULT 'DRAFT',
    data        jsonb,
    issued_at   timestamp,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by  integer REFERENCES person (party_id),
    modified    timestamp,
    CONSTRAINT valid_period CHECK(period >= 0)
  )

  CREATE TABLE payment (
    payment_id serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id),
    ref_num    text,
    paid_at    timestamptz DEFAULT CURRENT_TIMESTAMP,
    amount     numeric(10,2),
    created    timestamptz DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE line_item (
    line_item_id        serial PRIMARY KEY,
    order_id            integer REFERENCES sales.order (order_id) ON DELETE CASCADE,
    product_id          integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    -- The order in which the line items appear in a document
    line_position       smallint,
    code                text,
    name                text,
    short_desc          text,
    data                jsonb,
    -- Percentage discount
    discount       numeric(5,2),
    -- Dollar amount discount
    line_discount_amount numeric(10,2),
    -- Gross price charged
    gross               numeric(10,2),
    price               numeric(10,2),
    total_gross         numeric(10,2),
    total_price         numeric(10,2),
    uom_id              integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity            numeric(10,3),
    tax                 boolean DEFAULT TRUE,
    delivery_address_id integer REFERENCES address (address_id),
    note                text,
    note_importance     li_note_importance_t DEFAULT 'NORMAL',
    created             timestamp DEFAULT CURRENT_TIMESTAMP,
    modified            timestamp,
    end_at              timestamp
  )

  CREATE OR REPLACE VIEW sales.line_item_v AS
    SELECT
      li.line_item_id,
      li.product_id,
      li.quantity,
      li.line_position,
      coalesce(li.name, p.name) AS name,
      p.code,
      p.sku,
      p.supplier_code,
      p.manufacturer_code,
      pu.gross,
      pu.weight,
      uom.name AS uom_name,
      uom.abbr AS uom_abbr,
      CASE
        WHEN li.line_total_gross IS NOT NULL THEN
          li.line_total_gross
        WHEN li.line_gross IS NOT NULL THEN
          (li.line_gross * li.quantity)::numeric(10,2)
        ELSE (pu.gross * li.quantity)::numeric(10,2)
      END AS total_gross
    FROM sales.line_item li
    LEFT JOIN prd.product p
      USING (product_id)
    LEFT JOIN prd.product_uom(li.product_id, li.uom_id) pu
      ON pu.product_id = li.product_id AND pu.uom_id = li.uom_id
    LEFT JOIN prd.uom uom
      ON uom.uom_id = li.uom_id
    WHERE li.end_at IS NULL OR li.end_at > CURRENT_TIMESTAMP;

  CREATE OR REPLACE VIEW sales.overdue_invoice_v AS
    SELECT
      i.invoice_id
    FROM sales.invoice i
    WHERE i.due_date < CURRENT_TIMESTAMP AND i.payment_status != 'PAID';

--
-- Triggers
--
CREATE TRIGGER sales_update_order_tg BEFORE UPDATE ON sales.order
      FOR EACH ROW EXECUTE PROCEDURE sales.update_order_tg();

CREATE TRIGGER sales_update_line_item_tg BEFORE UPDATE ON sales.line_item
      FOR EACH ROW EXECUTE PROCEDURE sales.update_line_item_tg();

CREATE TRIGGER sales_delete_order_tg BEFORE DELETE ON sales.order
      FOR EACH ROW EXECUTE PROCEDURE sales.delete_order_tg();
