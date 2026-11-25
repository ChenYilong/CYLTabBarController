'use strict'

// [EN] The animation tint of cyl-animated-item (`animationTint` / `animationDarkTint`, the names and values of Rive's `tint` / `darkTint`):
//      a pure function of the two properties, `selected`, dark mode and the icon colors. [CN] cyl-animated-item 的动画着色。
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylAnimatedItemAnimationTint: tint, cylAnimatedItemTintColor, cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')

test('not set keeps the file colors, whatever the icon colors, selection and mode', () => {
  assert.equal(tint({}), '')
  assert.equal(tint(), '')
  assert.equal(tint({ animationTint: '', animationDarkTint: '#112233', selected: true, isDark: true, iconTint: '#FF0000', selectedIconTint: '#00FF00' }), '')
  assert.equal(tint({ animationTint: '   ', iconTint: '#FF0000' }), '')
  assert.equal(model({ animationUrl: 'a.riv', iconTint: '#FF0000', selected: true }).animationTint, '')
  assert.equal(model({ animationUrl: 'a.riv', animationDarkTint: '#112233', systemTheme: 'dark' }).animationTint, '')
})

test('"title" follows the icon color and the selected state\'s icon color', () => {
  const colors = { animationTint: 'title', iconTint: '#888888', selectedIconTint: '#007AFF' }
  assert.equal(tint({ ...colors, selected: false }), '#888888')
  assert.equal(tint({ ...colors, selected: true }), '#007AFF')
  assert.equal(tint({ animationTint: ' TITLE ', iconTint: '#888888', selected: true }), '#888888', 'a selectedIconTint that is not set means iconTint')
  assert.equal(tint({ animationTint: 'title', iconTint: '#888888', selectedIconTint: '', selected: true }), '#888888')
  assert.equal(tint({ animationTint: 'title', selected: true }), '', 'no icon color: nothing to follow, the file colors')
  assert.equal(tint({ ...colors, selected: true, isDark: true, animationDarkTint: '#FFFFFF' }), '#007AFF', 'the dark tint is for a fixed color only')
})

test('a fixed color is for the unselected item, the selected item takes its icon color, dark uses animationDarkTint', () => {
  const base = { animationTint: '#FF8800', animationDarkTint: '#FFCC88', iconTint: '#888888', selectedIconTint: '#007AFF' }
  assert.equal(tint({ ...base, selected: false }), '#FF8800')
  assert.equal(tint({ ...base, selected: true }), '#007AFF')
  assert.equal(tint({ ...base, selected: false, isDark: true }), '#FFCC88')
  assert.equal(tint({ ...base, selected: true, isDark: true }), '#007AFF')
  assert.equal(tint({ animationTint: '#FF8800', selected: false, isDark: true }), '#FF8800', 'no dark tint: the fixed color')
  assert.equal(tint({ animationTint: '#FF8800', animationDarkTint: 'title', isDark: true }), '#FF8800', 'a dark tint is a color, never "title"')
  assert.equal(tint({ animationTint: '#FF8800', selected: true }), '#FF8800', 'a selected item without any icon color keeps the fixed color')
  assert.equal(tint({ animationTint: '#FF8800', iconTint: '#888888', selectedIconTint: '', selected: true }), '#888888')
})

test('#RRGGBBAA reaches a canvas as rgba(); unusable text is no color', () => {
  assert.equal(cylAnimatedItemTintColor('#112233'), '#112233')
  assert.equal(cylAnimatedItemTintColor('#112233CC'), 'rgba(17,34,51,0.8)')
  assert.equal(cylAnimatedItemTintColor('#1234'), 'rgba(17,34,51,0.267)')
  assert.equal(cylAnimatedItemTintColor('red'), 'red')
  for (const bad of ['', '  ', 'title', 'red;x', 'url("x")', null, undefined]) assert.equal(cylAnimatedItemTintColor(bad), '', String(bad))
  assert.equal(tint({ animationTint: 'red;x', iconTint: '#888888' }), '')
})

test('the property overrides the same option of the animation source', () => {
  // [EN] The source's own `#tint=` is the engine's default; a set property is what the item hands to the engine. [CN] 来源自带的 `#tint=` 是引擎默认值；已设置的属性才是条目交给引擎的值。
  const source = 'https://x/a.riv#artboard=CHAT&tint=%23FF0000'
  assert.equal(model({ animationUrl: source, animationTint: '#00AA00' }).animationTint, '#00AA00')
  assert.equal(model({ animationUrl: source, animationTint: 'title', iconTint: '#123456' }).animationTint, '#123456')
  assert.equal(model({ animationUrl: source }).animationTint, '', 'unset hands nothing over: the source option stays in force')
})

test('set and clear: the model follows the properties, selection and theme at any time', () => {
  const props = { animationUrl: 'a.riv', iconTint: '#888888', selectedIconTint: '#007AFF' }
  assert.equal(model(props).animationTint, '')
  assert.equal(model({ ...props, animationTint: 'title' }).animationTint, '#888888')
  assert.equal(model({ ...props, animationTint: 'title', selected: true }).animationTint, '#007AFF')
  assert.equal(model({ ...props, animationTint: '#FF8800', animationDarkTint: '#FFCC88' }).animationTint, '#FF8800')
  assert.equal(model({ ...props, animationTint: '#FF8800', animationDarkTint: '#FFCC88', systemTheme: 'dark' }).animationTint, '#FFCC88')
  assert.equal(model({ ...props, animationTint: '#FF8800', animationDarkTint: '#FFCC88', systemTheme: 'dark', userInterfaceStyle: 'light' }).animationTint, '#FF8800')
  assert.equal(model({ ...props, animationTint: '' }).animationTint, '', 'cleared: the file colors again')
})

test('the component declares both properties and observes them', () => {
  const fs = require('node:fs')
  const path = require('node:path')
  const source = fs.readFileSync(path.join(__dirname, '../src/cyl-animated-item/index.js'), 'utf8')
  assert.match(source, /animationDarkTint: \{ type: String, value: '' \}/)
  assert.match(source, /selectedIconTint, animationTint, animationDarkTint, titleColor/)
  const wxml = fs.readFileSync(path.join(__dirname, '../src/cyl-animated-item/index.wxml'), 'utf8')
  assert.match(wxml, /tint="\{\{m\.animationTint\}\}"/)
  assert.match(wxml, /drop-shadow\(\{\{m\.animationTint\}\} 200px 0\)/)
})
