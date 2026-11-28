'use strict'

// [EN] D8 and S8 for the mini program: cyl-utils is the only module that requires the lifecycle library; cyl-badge requires nothing of
//      cyl-animated-item or cyl-tab-bar; the lifecycle library requires nothing outside itself.
// [CN] 小程序的 D8 与 S8：cyl-utils 是唯一引用生命周期库的模块；cyl-badge 不引用 cyl-animated-item 或 cyl-tab-bar；生命周期库不引用自身以外的东西。
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')

const SRC = path.join(__dirname, '..', 'src')
function jsFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? jsFiles(path.join(dir, e.name)) : e.name.endsWith('.js') ? [path.join(dir, e.name)] : []))
}
const requires = (file) => [...fs.readFileSync(file, 'utf8').matchAll(/require\(\s*['"]([^'"]+)['"]\s*\)/g)].map((m) => m[1])

test('only cyl-utils requires the vendored lifecycle library', () => {
  jsFiles(SRC).filter((f) => !f.includes(`${path.sep}cyl-dealloc-block-executor${path.sep}`)).forEach((file) => {
    const hits = requires(file).filter((r) => r.includes('cyl-dealloc-block-executor'))
    if (!file.includes(`${path.sep}cyl-utils${path.sep}`)) assert.deepEqual(hits, [], `${path.relative(SRC, file)} must require ../cyl-utils/index`)
  })
  assert.equal(require('../src/cyl-utils/index'), require('../src/cyl-dealloc-block-executor/index'))
})

test('cyl-badge sees nothing above it', () => {
  jsFiles(path.join(SRC, 'cyl-badge')).forEach((file) => {
    requires(file).filter((r) => r.startsWith('..')).forEach((r) => assert.ok(!/cyl-(animated-item|tab-bar|tab-bar-item)/.test(r), `${path.relative(SRC, file)} requires ${r}`))
  })
})

test('the lifecycle library requires nothing outside itself', () => {
  jsFiles(path.join(SRC, 'cyl-dealloc-block-executor')).forEach((file) => {
    requires(file).forEach((r) => assert.ok(r.startsWith('./') || r.startsWith('node:') || !r.startsWith('.'), `${path.relative(SRC, file)} requires ${r}`))
  })
})
