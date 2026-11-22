/**
 * [EN] The `#` options of an animation value against the shared vectors every platform reads
 *      (`CrossPlatform/animated-item-fixtures/source-options.json`, from the HarmonyOS parser): `cylAnimatedItemSource` in
 *      src/cyl-animated-item/cyl_animated_item_model.js. A field a vector does not have is not checked. Run: `npm test`.
 * [CN] 动画值的 `#` 选项与各平台共同读取的测试向量（`CrossPlatform/animated-item-fixtures/source-options.json`，取自鸿蒙解析器）
 *      对照：src/cyl-animated-item/cyl_animated_item_model.js 中的 `cylAnimatedItemSource`。向量中没有的字段不检查。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { cylAnimatedItemSource } = require('../src/cyl-animated-item/cyl_animated_item_model')

const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, '../../animated-item-fixtures/source-options.json'), 'utf8'))

test('the fixture has vectors', () => {
  assert.ok(fixture.cases.length >= 7)
})

fixture.cases.forEach((vector) => {
  test(`source vector: ${vector.input.trim().slice(0, 60)}`, () => {
    const source = cylAnimatedItemSource(vector.input)
    assert.equal(source.url, vector.input)
    if ('file' in vector) assert.equal(source.file, vector.file)
    if ('inlineJSON' in vector) assert.equal(source.inlineJSON, vector.inlineJSON)
    if ('type' in vector) assert.equal(source.type, vector.type.toLowerCase())
    assert.deepEqual(source.options, vector.options)
  })
})

test('a value with no options, nothing, or an undecodable option', () => {
  assert.deepEqual(cylAnimatedItemSource(undefined), { url: '', file: '', inlineJSON: undefined, options: {}, type: '' })
  assert.deepEqual(cylAnimatedItemSource('a.riv#x=%E0%A4%A').options, { x: '%E0%A4%A' })
  assert.deepEqual(cylAnimatedItemSource('a.riv#=1&b&c=2').options, { c: '2' })
  assert.equal(cylAnimatedItemSource('asset:icons.svga.bin').type, 'svga')
})
