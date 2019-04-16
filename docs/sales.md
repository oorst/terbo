# Sales

## Orders

Orders organise the transaction between buyer and seller.

Orders can be in one of several states: PENDING, CONFIRMED.

PENDING orders show the current prices of products.

CONFIRMED orders lock the prices to what they were when the order was
confirmed. Invoices can only be created from confirmed orders.

### API

#### sales.list_quotes

- sales.list_quotes (OUT result json)

- sales.list_quotes (payload json, OUT result json)
  - `payload` {Object}
    - `orderId` {Integer} *Order* id
  - Returns: {Array}

The returned array contains objects with the following properties:

- `orderId` {Integer}
- `quoteId` {Integer}
- `status` {String} document_status_t (See *Types*)
- `issuedAt` {Timestamp}
- `issuedToName` {String} Name of the *Party* the quote was issued to
- `issuedToId` {Integer}
- `contactName` {String} Name of the primary contact
- `contactId` {Integer}
- `outDated` {Boolean} Indicates if the quote was created before the modified date of the *Order*.
