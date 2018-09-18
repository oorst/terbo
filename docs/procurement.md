## Procurement

### Types

#### purchase_order_status_t

- `DRAFT`
- `RFQ` Request For Quote
- `ISSUED`
- `VOID`

### Tables

#### purchase_order

| Column | Type | Description | Constraint |
|-|-|-|-|
| purchase_order_id | serial | Purchase Order ID | PRIMARY KEY |
| order_id | integer | Id of related Sales.Order | FK sales.order (order_id) |
| issued_to | integer | Id of recipient *Party* | FK party (party_id) |
| status | purchase_order_status_t | Status of purchase order |-|
| data | jsonb | Saved data when purchase order is issued |-|
| created_by | integer | Party that created the purchase order | FK party (party_id) |
| created | timestamp | Creation time of purchase order |-|
| modified | timestamp | Last modification time |-|
