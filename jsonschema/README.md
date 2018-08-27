# Terbo JSON Schema

## Install

`npm install --save terbo`

## Usage

To access all of the available schemas, require the Terbo package.

`const schema = require('terbo/jsonschema')`

The schema are organised by module and function name. Multiple word names are
camel cased.

```javascript
{
  product: {
    createPrice,
    createProduct,
    ...
  },
  ...
}
```

Check the 'jsonschema' directory in the repo for the available schemas.
