const requireDirectory = require('require-directory')
const { rename } = require('../util')

module.exports = requireDirectory(module, { rename })
