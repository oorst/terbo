## Prerequisites

- _Person_
- _Organisation_

## Tables

### InvoiceLine

_InvoiceLine_ is an item on an invoice.

## Functions

### **create_customer_account(options json)**

Creates a customer account from an existing _Person_
or _Organisation_.

**options**
```
{
  [personId: <Integer>],
  [organisationId: <Integer>]
}
```
Either the `personId` or `organisationId` field must be provided.

### **create_invoice(options json)**

Create an invoice.  Invoices can be created by initially providing all the
relevant information, or by adding later on.

**options**
```
{
  customerId: <Integer>,
  [lines: { <InvoiceLine> }]
}
```
