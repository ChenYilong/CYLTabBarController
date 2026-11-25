// The home page's sectioned lists are tag lists (docs/instructions/examples.md): which sections become tags and what the tag list is
// told. 首页带分组的列表是 TagList：哪些分组变为 Tag，以及 TagList 收到的配置。
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylRowIsTag, cylSectionIsTags, cylTagConfiguration } = require('../example/miniprogram/utils/cyl_demo_tags')

test('a plain row, a chevron and a check are tags; a slider, a switch, the arrows and a swatch are not', () => {
  assert.equal(cylRowIsTag({ id: 'a', title: 'A' }), true)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', accessory: 'chevron' }), true)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', accessory: 'check' }), true)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', slider: 1.5 }), false)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', accessory: 'switch' }), false)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', accessory: 'arrows' }), false)
  assert.equal(cylRowIsTag({ id: 'a', title: 'A', preview: { swatch: '#fff' } }), false)
})

test('a section is tags only when it has rows and every row is a tag', () => {
  assert.equal(cylSectionIsTags({ rows: [{ id: 'a', title: 'A' }, { id: 'b', title: 'B', accessory: 'chevron' }] }), true)
  assert.equal(cylSectionIsTags({ rows: [{ id: 'a', title: 'A' }, { id: 'b', title: 'B', accessory: 'switch' }] }), false)
  assert.equal(cylSectionIsTags({ rows: [] }), false)
  assert.equal(cylSectionIsTags({ badges: [] }), false)
})

test('the configuration: a titled section, no selection, a callout, 3 lines, More after 3 rows', () => {
  const configuration = cylTagConfiguration({ title: 'General', rows: [{ id: 'language', title: 'Language', subtitle: 'Current: en' }, { id: 'memory', title: 'Memory' }] })
  assert.equal(configuration.selectionMode, 'none')
  assert.equal(configuration.longPressAction, 'callout')
  assert.equal(configuration.defaultVisibleRows, 3)
  assert.equal(configuration.style.titleMaxLines, 3)
  assert.deepEqual(configuration.foldControl, { position: 'headerTrailing', content: 'iconAndTitle' })
  assert.equal(configuration.sections.length, 1)
  assert.equal(configuration.sections[0].title, 'General')
  assert.deepEqual(configuration.sections[0].items, [{ id: 'language', title: 'Language', subtitle: 'Current: en' }, { id: 'memory', title: 'Memory' }])
})
