'use strict'

// [EN] cyl-badge as a component in a fake runtime, and the tab bar item's use of it (phase 1): the observer draws what the model says, the tab variant shows
//      what the item computed, the markup registers and uses the component, the item's style split loses nothing.
// [CN] 在模拟运行时中的 cyl-badge 组件，以及 Tab 栏 item 对它的使用（阶段 1）：observer 画出模型给出的内容，tab 变体显示 item 算好的内容，标记注册并使用该组件，
//      item 样式的拆分不丢任何内容。
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')

const SRC = path.join(__dirname, '..', 'src')

function cylLoadBadge() {
  let definition
  global.Component = (d) => { definition = d }
  delete require.cache[require.resolve('../src/cyl-badge/index.js')]
  require('../src/cyl-badge/index.js')
  delete global.Component
  return definition
}
const cylRun = (definition, data) => {
  const component = { data: {}, setData(update) { Object.assign(this.data, update) } }
  const keys = Object.keys(definition.observers)[0].split(',').map((k) => k.trim())
  const values = keys.map((k) => (k in data ? data[k] : definition.properties[k].value))
  definition.observers[Object.keys(definition.observers)[0]].apply(component, values)
  return component.data.m
}

test('cyl-badge: the default value is null, never an empty string (an empty string is a dot)', () => {
  const definition = cylLoadBadge()
  assert.equal(definition.properties.value.value, null)
  assert.equal(cylRun(definition, {}).showsBadge, false)
  assert.equal(cylRun(definition, { value: '' }).isDot, true)
  assert.equal(cylRun(definition, { value: '3' }).text, '3')
})

test('cyl-badge: the tab variant shows what the item computed, as given', () => {
  const m = cylRun(cylLoadBadge(), { variant: 'tab', valueText: '9', dot: false, styleText: 'padding: 1px;', classText: 'cyl-badge-scale' })
  assert.deepEqual([m.showsBadge, m.isDot, m.text, m.style, m.className, m.variant], [true, false, '9', 'padding: 1px;', 'cyl-badge-scale', 'tab'])
  const dot = cylRun(cylLoadBadge(), { variant: 'tab', valueText: '', dot: true, styleText: '', classText: '' })
  assert.equal(dot.isDot, true)
})

test('the tab bar item draws its badge through cyl-badge: registered, used, position classes only on the host', () => {
  const json = JSON.parse(fs.readFileSync(path.join(SRC, 'cyl-tab-bar-item', 'index.json'), 'utf8'))
  assert.equal(json.usingComponents['cyl-badge'], '../cyl-badge/index')
  const wxml = fs.readFileSync(path.join(SRC, 'cyl-tab-bar-item', 'index.wxml'), 'utf8')
  assert.match(wxml, /<cyl-badge /)
  assert.match(wxml, /variant="tab"/)
  assert.doesNotMatch(wxml, /class="cyl-item-badge /)
  const wxss = fs.readFileSync(path.join(SRC, 'cyl-tab-bar-item', 'index.wxss'), 'utf8')
  assert.match(wxss, /\.cyl-item-badge-host \{[^}]*position: absolute/)
  assert.doesNotMatch(wxss, /background-color: #ff3b30/, 'the look moved to cyl-badge')
})

test('the item style split loses nothing: padding + offset + size + look is the old badgeStyle', () => {
  const { cylItemModel } = require('../src/cyl-tab-bar-item/cyl_tab_bar_item_model')
  for (const p of [{ badgeValue: '3' }, { badgeValue: '', badgeSize: '{9, 9}' }, { badgeValue: '8', badgePositionAdjustment: '{4, -2}', badgeColor: '#34C759' }]) {
    const model = cylItemModel(p)
    // the look begins with the padding (or the size), the host part is the margins; together they hold every declaration of the old string
    const declarations = (text) => text.split(';').map((d) => d.trim()).filter(Boolean).sort()
    assert.deepEqual(declarations(model.badgeHostStyle + model.badgeLookStyle), declarations(model.badgeStyle), JSON.stringify(p))
  }
})

test('every animation class the model can name has a keyframe in the one wxss', () => {
  const css = fs.readFileSync(path.join(SRC, 'cyl-badge', 'cyl_badge_animations.wxss'), 'utf8')
  for (const name of ['scale', 'shake', 'bounce', 'breathe', 'scaleOnce']) assert.match(css, new RegExp(`\\.cyl-badge-${name} \\{`))
  assert.equal(fs.existsSync(path.join(SRC, 'cyl-tab-bar', 'cyl_badge_animations.wxss')), false, 'one copy only')
})
