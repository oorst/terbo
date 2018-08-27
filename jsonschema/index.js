const requireDirectory = require('require-directory')
const camelCase = require('lodash.camelcase')

function rename (name) {
  return camelCase(name)
}

module.exports = requireDirectory(module, { rename })
