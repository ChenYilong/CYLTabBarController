'use strict'

// [EN] The animation tint of cyl-animated-item (`animationTint` / `animationDarkTint`, the names and values of Rive's `tint` / `darkTint`):
//      a pure function of the two properties, `selected`, dark mode and the icon colors. [CN] cyl-animated-item 的动画着色。
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylAnimatedItemAnimationTint: tint, cylAnimatedItemTintColor, cylAnimatedItemTintHex, cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')

test('not set keeps the file colors, whatever the icon colors, selection and mode', () => {
  assert.equal(tint({}), '')
  assert.equal(tint(), '')
  assert.equal(tint({ animationTint: '', animationDarkTint: '#112233', selected: true, isDark: true, iconTint: '#FF0000', selectedIconTint: '#00FF00' }), '')
  assert.equal(tint({ animationTint: '   ', iconTint: '#FF0000' }), '')
  assert.equal(model({ animationUrl: 'a.riv', iconTint: '#FF0000', selected: true }).animationTint, '')
  assert.equal(model({ animationUrl: 'a.riv', animationDarkTint: '#112233', systemTheme: 'dark' }).animationTint, '')
})

// [EN] THE TABLE (identical on iOS, Android, HarmonyOS and the mini program): state x tint kind x which icon colors exist x dark.
//      Each row is [animationTint, animationDarkTint, selected, isDark, iconTint, selectedIconTint, expected]. [CN] 真值表。
const N = '#888888'
const S = '#007AFF'
const F = '#FF8800'
const D = '#112233'
const FA = 'rgba(255,136,0,0.502)'
// [EN] The built-in colors (tint spec v2, section 10): label, and systemBlue as the selected default (light | dark). [CN] 内置颜色。
const LBL = 'rgb(0,0,0)'
const LBL_D = 'rgb(255,255,255)'
const BLUE = 'rgb(0,136,255)'
const BLUE_D = 'rgb(0,145,255)'
const TABLE = [
  // unset, or invalid text = unset: the file's own colors, whatever else exists
  ['', D, false, false, N, S, ''], ['', D, true, true, N, S, ''], ['   ', '', true, false, N, S, ''],
  ['red', D, false, false, N, S, ''], ['red;x', D, true, true, N, S, ''], ['#12345', D, false, false, N, S, ''], ['#GG0000', '', true, false, N, S, ''],
  // "title": unselected normal icon color; selected selected icon color, else normal, else NO tint; darkTint never applies
  ['title', D, false, false, N, S, N], ['title', D, false, true, N, S, N], ['title', D, false, false, N, '', N], ['title', D, false, false, '', S, LBL],
  ['title', D, false, false, '', '', LBL], ['title', D, false, true, '', '', LBL_D],
  ['title', D, true, false, N, S, S], ['title', D, true, true, N, S, S], ['title', D, true, false, N, '', BLUE], ['title', D, true, false, N, null, BLUE],
  ['title', D, true, false, '', S, S], ['title', D, true, false, '', '', BLUE], ['title', D, true, true, '', '', BLUE_D],
  [' title ', '', true, false, N, S, S], [' TITLE ', '', true, false, N, S, ''], [' Title ', '', false, false, N, S, ''],
  // a fixed color, unselected: the fixed color; dark: darkTint when valid, else the fixed color; icon colors do not matter
  [F, '', false, false, N, S, F], [F, '', false, false, '', '', F], [F, D, false, false, N, S, F], [F, D, false, true, N, S, D], [F, D, false, true, '', '', D],
  [F, '', false, true, N, S, F], [F, 'title', false, true, N, S, F], [F, 'red', false, true, N, S, F], [F, 'bad;x', false, true, N, S, F],
  // a fixed color, selected: the selected icon color when present (the normal one does not count), else the fixed color; darkTint applies to the fixed color only
  [F, D, true, false, N, S, S], [F, D, true, true, N, S, S], [F, D, true, false, '', S, S], [F, '', true, false, N, S, S],
  [F, D, true, false, N, '', F], [F, D, true, false, N, null, F], [F, D, true, false, '', '', F], [F, '', true, false, '', '', F],
  [F, D, true, true, N, '', D], [F, D, true, true, '', '', D], [F, '', true, true, N, '', F], [F, 'title', true, true, '', '', F],
  // 8-digit hex is ALWAYS #RRGGBBAA (and #RGBA), reaching a canvas as rgba()
  ['#FF880080', '', false, false, '', '', FA], ['#FF880080', '#11223380', false, true, '', '', 'rgba(17,34,51,0.502)'], ['#F808', '', false, false, '', '', ''], ['#F80', '', false, false, '', '', ''], ['FF8800', '', false, false, '', '', ''],
  ['#FF880080', '', true, false, N, '', FA], ['title', '', false, false, '#11223380', '', 'rgba(17,34,51,0.502)'],
]

test('the truth table: state x tint kind x icon colors x dark', () => {
  for (const [animationTint, animationDarkTint, selected, isDark, iconTint, selectedIconTint, expected] of TABLE) {
    const input = { animationTint, animationDarkTint, selected, isDark, iconTint, selectedIconTint }
    assert.equal(tint(input), expected, JSON.stringify(input))
  }
})

test('the truth table through the item model (dark from userInterfaceStyle / systemTheme, icon colors from animationIconTint first)', () => {
  for (const [animationTint, animationDarkTint, selected, isDark, iconTint, selectedIconTint, expected] of TABLE) {
    const props = { animationUrl: 'a.riv', animationTint, animationDarkTint, selected, userInterfaceStyle: isDark ? 'dark' : 'light' }
    const label = JSON.stringify(props)
    assert.equal(model({ ...props, iconTint, selectedIconTint }).animationTint, expected, label)
    assert.equal(model({ ...props, systemTheme: isDark ? 'dark' : 'light', userInterfaceStyle: 'system', iconTint, selectedIconTint }).animationTint, expected, label)
    // the animation icon colors win over the still image's; the still image's tint is not touched by them (an empty one means the still's)
    if (!iconTint || !selectedIconTint) continue
    const own = model({ ...props, image: 'a.png', iconTint: '#010101', selectedIconTint: '#020202', animationIconTint: iconTint || '', animationSelectedIconTint: selectedIconTint || '' })
    assert.equal(own.animationTint, expected, label)
    assert.equal(own.still.normalTint, '#010101')
    assert.equal(own.still.selectedTint, '#020202')
  }
})

test('the selected icon color of the still image is not the animation\'s: a null one is absent for the animation', () => {
  assert.equal(model({ animationUrl: 'a.riv', animationTint: F, selected: true, iconTint: N }).animationTint, F)
  assert.equal(model({ animationUrl: 'a.riv', animationTint: 'title', selected: true, iconTint: N }).animationTint, BLUE, 'selected without an explicit selected color: the built-in selected color, not the normal one')
})

test('#RRGGBBAA reaches a canvas as rgba(); unusable text is no color', () => {
  assert.equal(cylAnimatedItemTintColor('#112233'), '#112233')
  assert.equal(cylAnimatedItemTintColor('#112233CC'), 'rgba(17,34,51,0.8)')
  assert.equal(cylAnimatedItemTintColor('#1234'), 'rgba(17,34,51,0.267)')
  assert.equal(cylAnimatedItemTintColor('red'), 'red')
  for (const bad of ['', '  ', 'title', 'red;x', 'url("x")', null, undefined]) assert.equal(cylAnimatedItemTintColor(bad), '', String(bad))
  assert.equal(tint({ animationTint: 'red;x', iconTint: '#888888' }), '')
  assert.equal(cylAnimatedItemTintHex('red'), '', 'a tint option is a hex color only')
  assert.equal(cylAnimatedItemTintHex('#112233CC'), 'rgba(17,34,51,0.8)', '#RRGGBBAA, never #AARRGGBB')
})

test('the property overrides the same option of the animation source', () => {
  // [EN] The item reads the source's `#tint=` / `darkTint=` options like every platform; a non-blank property wins over them. [CN] 条目像其他平台一样读取来源的 `#tint=` / `darkTint=` 选项；非空属性优先。
  const source = 'https://x/a.riv#artboard=CHAT&tint=%23FF0000'
  assert.equal(model({ animationUrl: source, animationTint: '#00AA00' }).animationTint, '#00AA00')
  assert.equal(model({ animationUrl: source, animationTint: 'title', iconTint: '#123456' }).animationTint, '#123456')
  assert.equal(model({ animationUrl: source }).animationTint, '#FF0000', 'unset property: the source option')
  assert.equal(model({ animationUrl: source, animationTint: 'bad' }).animationTint, '', 'an invalid property wins over the option: unset')
  assert.equal(model({ animationUrl: 'https://x/a.riv#tint=title', iconTint: '#123456' }).animationTint, '#123456', 'title from the source option')
  assert.equal(model({ animationUrl: 'https://x/a.riv#tint=%23FF0000&darkTint=%2300FF00', systemTheme: 'dark' }).animationTint, '#00FF00', 'darkTint from the source option')
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
  assert.match(source, /selectedIconTint, animationTint, animationDarkTint, animationIconTint, animationSelectedIconTint, animationRenderingMode, builtInSelectedColor, animationColorKind, titleColor/)
  const wxml = fs.readFileSync(path.join(__dirname, '../src/cyl-animated-item/index.wxml'), 'utf8')
  assert.match(wxml, /tint="\{\{m\.animationTint\}\}"/)
  assert.match(wxml, /drop-shadow\(\{\{m\.animationTint\}\} 200px 0\)/)
})

test('a playing GIF with animationTint "title" gets the icon color, never the literal "title"', () => {
  const m = model({ animationUrl: 'https://x/a.gif', animationTint: 'title', iconTint: '#112233', selectedIconTint: '#445566', selected: true })
  assert.equal(m.animationTint, '#445566')
  assert.equal(model({ animationUrl: 'https://x/a.gif#tint=title', iconTint: '#112233' }).animationTint, '#112233')
})
