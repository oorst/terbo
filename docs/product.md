# Product

### Dependencies

- Core

## Prototypes

The Terbo Product schema provides a prototyping interface, allowing a Product to
inherit the data of an already existing Product. This can be very helpful when
there are several Products that differ only slightly in their data.

Where a Product provides its own data, that data will override the prototype.

## Models

### Product

The Product model is designed to be as flexible as possible. Products



## API Functions

### prd.create_product(params json)

* `params`
  * `type` {string} `product` | `service`
  * `name` {string}
  * [`code`] {string}
  * [`sku`] {string}
  * [`manufacturerId`] {integer}
  * [`manufacturerCode`] {string}
  * [`supplierId`] {integer}
  * [`supplierCode`] {string}
  * [`data`] {object}
* Returns: {object}

Insert a new *Product* into the database.

### prd.get_product(params json, OUT result json)

* `params`
  * `id` {integer}
* Returns: `result`
  * `id` {integer} product_id
  * `uuid` {string}
  * `type` {string}
  * `name` {string}
  * [`code`] {string}
  * [`description`] {string}
  * [`sku`] {string}
  * [`manufacturer`] {JSON}
    * `id` {integer} manufacturer_id
    * `type` {string}
    * `name` {string}
  * [`manufacturerCode`] {string} manufacturer_code
  * [`supplier`] {JSON}
    * `id` {integer} manufacturer_id
    * `type` {string}
    * `name` {string}
  * [`supplierCode`] {string} manufacturer_code
  * [`data`] {JSON}
  * [`costHistory`] {JSON}
  * [`priceHistory`] {JSON}

Get a full normalised view of the object. Any NULL fields will not be present
on the result.

### prd.get_product_view(params json, OUT result json)

* `params` {JSON}
  * [`id`] {integer}
  * [`code`] {string}
  * [`sku`] {string}
* Returns: {JSON}
  * `id` {integer}
  * `uuid` {string}
  * `name` {string}
  * [`code`] {string}
  * [`sku`] {string}
  * [`description`] {string}
  * [`data`] {JSON}
  * [`gross`] {number} Gross price
  * [`net`] {number} Net price

Retrieve a view of the *Product*.  Used when current product data like pricing
is required.

## Private Functions

### prd.current_cost(id integer, OUT result numeric(10,2))

* `id` product_id

Return the most recent record in the cost history of the *Product*.
