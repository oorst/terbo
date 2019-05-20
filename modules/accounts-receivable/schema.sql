CREATE SCHEMA ar;

CREATE TYPE ar.payment_status_t AS ENUM (
  'OWING',
  'PAID'
);

CREATE TYPE ar.payment_time_t AS ENUM (
  'ON_TIME',
  'LATE'
);

CREATE TABLE ar.invoice (
  invoice_uuid   uuid REFERENCES core.document (document_uuid) PRIMARY KEY,
  payor          uuid REFERENCES core.party (party_uuid),
  due_date       timestamptz,
  payment_status ar.payment_status_t
);

CREATE TABLE ar.receipt (
  receipt_uuid uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  invoice_uuid uuid REFERENCES ar.invoice (invoice_uuid) NOT NULL,
  payment_time ar.payment_time_t
);