## Sales

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
