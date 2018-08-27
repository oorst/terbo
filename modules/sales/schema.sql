CREATE TYPE document_status_t AS ENUM ('DRAFT', 'ISSUED', 'DELETED', 'VOID');
CREATE TYPE order_status_t AS ENUM ('PENDING', 'FULFILLED', 'DELIVERED');
CREATE TYPE payment_status_t AS ENUM ('OWING', 'PAID');
CREATE TYPE li_note_importance_t AS ENUM ('NORMAL', 'IMPORTANT');

CREATE SCHEMA sales
  CREATE TABLE sales.order (
    order_id            serial PRIMARY KEY,
    buyer_id            integer REFERENCES party (party_id) ON DELETE SET NULL,
    status              order_status_t DEFAULT 'PENDING',
    notes               text,
    purchase_order_num  text,
    created             timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by          integer REFERENCES person (party_id) NOT NULL
  )

  CREATE TABLE invoice (
    invoice_id      serial PRIMARY KEY,
    invoice_num     text,
    order_id        integer REFERENCES sales.order (order_id) ON DELETE RESTRICT,
    contact_id      integer REFERENCES person (party_id) ON DELETE SET NULL,
    period          integer NOT NULL DEFAULT 30,
    due_date        timestamp,
    status          document_status_t DEFAULT 'DRAFT',
    payment_status  payment_status_t DEFAULT 'OWING',
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

  CREATE TABLE quote (
    quote_id    serial PRIMARY KEY,
    order_id    integer REFERENCES sales.order (order_id) ON DELETE CASCADE,
    period      integer NOT NULL DEFAULT 30,
    expiry_date date,
    contact_id  integer REFERENCES person (party_id),
    notes       text,
    status      document_status_t DEFAULT 'DRAFT',
    issued_at   timestamp,
    created     timestamp DEFAULT CURRENT_TIMESTAMP,
    created_by  integer REFERENCES person (party_id),
    modified    timestamp
  )

  CREATE TABLE payment (
    payment_id serial PRIMARY KEY,
    invoice_id integer REFERENCES invoice (invoice_id),
    amount     numeric(10,2),
    created    timestamp DEFAULT CURRENT_TIMESTAMP
  )

  CREATE TABLE line_item (
    line_item_id         serial PRIMARY KEY,
    order_id            integer REFERENCES sales.order (order_id) ON DELETE CASCADE,
    product_id          integer REFERENCES prd.product (product_id) ON DELETE RESTRICT,
    -- The order in which the line items appear in a document
    position            smallint,
    code                text,
    name                text,
    description         text,
    -- Misc data to be stored with line item
    data               jsonb,
    -- Percentage discount
    discount            numeric(3,2),
    -- Dollar amount discount
    discountAmount      numeric(10,2),
    -- Gross price charged
    gross               numeric(10,2),
    -- Net price charged, no extra tax is applied
    net                 numeric(10,2),
    uom_id              integer REFERENCES prd.uom (uom_id) ON DELETE SET NULL,
    quantity            numeric(10,3),
    tax                 boolean DEFAULT TRUE,
    delivery_address_id integer REFERENCES address (address_id),
    note                text,
    note_importance     li_note_importance_t DEFAULT 'NORMAL',
    created             timestamp DEFAULT CURRENT_TIMESTAMP,
    end_at              timestamp
  );
