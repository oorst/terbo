## Works

### Tables

#### asset

Assets are files or supporting information that is related to the execution of a
*Work Order*. For example, CNC machining files or drawings.  The location of the
asset is given by an URL.  Ideally the asset can be downloaded from the
Internet, but if the asset resides locally, then the URL should be
prefixed with `file://`.

| Column | Type | Description | Constraint |
|-|-|-|-|
| asset_uuid | uuid | Asset UUID | PRIMARY KEY |
| url | text | Location of asset |-|
| name | text | Name of the asset |-|
| short_desc | text | Short description of the asset |-|
| created | timestamp | Creation time of the asset |-|
#### work_order

| Column | Type | Description |
|-|-|-|
| work_order_id | serial | Work Order id and primary key |
| product_id | integer | prd.product (product_id) of the service to be performed |
| parent_id | integer | Parent Work Order |
| sales_order_id | integer | sales.order id |
| status | work_order_status_t | Work Order status |
| quantity | numeric(10,3) | quantity of specified service |
### API

#### works.list_work_centers

- **works.list_work_centers()**
  - Returns: {Object}


#### works.list_work_orders

- **works.list_work_orders()**
  - Returns: {Array}

When called without arguments, works.list_work_orders returns all *Work Orders* where status is `AUTHORISED`.

- **works.list_work_orders(payload)**
  - `payload`
    - `pending`? {Boolean} Must be `true`
    - `orderId`? {Integer} sales.order_id
  - Returns: {Array}

Exactly one of the payload properties must be provided. When `pending` is set to `true`, all pending work orders are returned.  When `orderId` is provided, all *Work Orders* relating to that sales.order are returned.
