// Plain, statically analyzable requires: WeChat DevTools' unused-file filter (ignoreDevUnusedFiles, on by default) drops every
// file it cannot see referenced, and it does not follow `...require('./x')` inside an object spread.
const registry = require('./registry');
const center = require('./center');
const log = require('./log');
const types = require('./types');
const controller = require('./controller');

module.exports = Object.assign({}, registry, center, log, types, controller);
