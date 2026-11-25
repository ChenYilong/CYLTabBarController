'use strict'

/**
 * [EN] Tint spec v2 (mini program): the one-color detector on the shared fixtures, the probe-value built-ins, the animation rendering mode, the
 *      divider contrast (>= 3:1 on light and dark), the stack's inheritance and the tab bar keeping today's look (alwaysOriginal without a tint option).
 * [CN] 着色规范 v2（小程序）：共享夹具上的单色检测、实测值内置颜色、动画渲染模式、分割线对比度（浅色与深色 >= 3:1）、堆叠继承，以及 TabBar 保持现有外观
 *      （没有着色选项时 alwaysOriginal）。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { cylLottieColorKind, cylGIFColorKind } = require('../src/cyl-animated-item/cyl_one_color_detector')
const m = require('../src/cyl-animated-item/cyl_animated_item_model')
const { cylStackModel } = require('../src/cyl-animated-item-stack/cyl_animated_item_stack_model')
const reader = require('../src/cyl-tab-bar/cyl_configuration')

const fixture = (name) => fs.readFileSync(path.join(__dirname, 'fixtures', name), 'utf8')

test('detector fixtures: the camera icon (one near-black color) is one-color; a multi-color Lottie and a gradient are multi-color', () => {
  assert.equal(cylLottieColorKind(fixture('lottie_camera_one_color.json')), 'one')
  assert.equal(cylLottieColorKind(JSON.parse(fixture('lottie_camera_one_color.json'))), 'one')
  assert.equal(cylLottieColorKind(fixture('lottie_multi_color.json')), 'multi')
  assert.equal(cylLottieColorKind(fixture('lottie_gradient.json')), 'multi')
})

test('detector rules: tolerance, transparent colors, keyframes, images, parse failure', () => {
  const fill = (k) => ({ layers: [{ shapes: [{ ty: 'fl', c: { a: 0, k } }] }] })
  const two = (a, b) => ({ layers: [{ shapes: [{ ty: 'fl', c: { a: 0, k: a } }, { ty: 'st', c: { a: 0, k: b } }] }] })
  assert.equal(cylLottieColorKind(fill([0, 0, 0, 1])), 'one')
  assert.equal(cylLottieColorKind(two([0.5, 0.5, 0.5, 1], [0.5 + 2 / 255, 0.5, 0.5 - 2 / 255, 0.3])), 'one', 'within +-2/255, alpha ignored')
  assert.equal(cylLottieColorKind(two([0.5, 0.5, 0.5, 1], [0.5 + 3 / 255, 0.5, 0.5, 1])), 'multi', 'beyond +-2/255')
  assert.equal(cylLottieColorKind(two([0, 0, 0, 1], [1, 0, 0, 0])), 'one', 'a fully transparent color is ignored')
  assert.equal(cylLottieColorKind({ layers: [{ shapes: [{ ty: 'fl', c: { a: 0, k: [1, 0, 0, 1] }, o: { a: 0, k: 0 } }, { ty: 'fl', c: { a: 0, k: [0, 0, 0, 1] } }] }] }), 'one', 'a static opacity of 0 is ignored')
  assert.equal(cylLottieColorKind(fill([1, 1, 1])), 'one', 'three channels')
  assert.equal(cylLottieColorKind({ layers: [{ shapes: [{ ty: 'fl', c: { a: 1, k: [{ t: 0, s: [0, 0, 0, 1], e: [0, 0, 0, 1] }, { t: 9, s: [0, 0, 0, 1] }] } }] }] }), 'one', 'keyframes of one color')
  assert.equal(cylLottieColorKind({ layers: [{ shapes: [{ ty: 'fl', c: { a: 1, k: [{ t: 0, s: [0, 0, 0, 1] }, { t: 9, s: [1, 0, 0, 1] }] } }] }] }), 'multi', 'keyframes of two colors')
  assert.equal(cylLottieColorKind({ layers: [{ ty: 2, refId: 'img_0' }, { shapes: [{ ty: 'fl', c: { k: [0, 0, 0, 1] } }] }], assets: [{ id: 'img_0', p: 'img_0.png', u: '', w: 1, h: 1 }] }), 'multi', 'an image')
  assert.equal(cylLottieColorKind({ assets: [{ id: 'img_0', p: 'x.png', u: 'images/', w: 8, h: 8 }], layers: [{ shapes: [{ ty: 'fl', c: { k: [0, 0, 0, 1] } }] }] }), 'multi', 'an image asset')
  assert.equal(cylLottieColorKind({ assets: [{ id: 'comp', layers: [{ shapes: [{ ty: 'fl', c: { k: [0, 0, 0, 1] } }] }] }], layers: [] }), 'one', 'a precomp asset is not an image')
  assert.equal(cylLottieColorKind({ layers: [] }), 'unknown', 'no color')
  for (const bad of ['{', '', 'null', null, undefined, 5]) assert.equal(cylLottieColorKind(bad), 'unknown', String(bad))
})

test('GIF detector over RGBA: alpha < 0.1 ignored, 4-bit buckets, 98 % in one bucket', () => {
  const pixels = (list) => Uint8Array.from(list.flat())
  const fillPixels = (count, rgba) => Array.from({ length: count }, () => rgba)
  assert.equal(cylGIFColorKind(pixels(fillPixels(100, [10, 10, 10, 255]))), 'one')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(98, [16, 16, 16, 255]), ...fillPixels(2, [250, 0, 0, 255])])), 'one', '98 %')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(97, [16, 16, 16, 255]), ...fillPixels(3, [250, 0, 0, 255])])), 'multi', '97 %')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(50, [0, 0, 0, 255]), ...fillPixels(50, [15, 15, 15, 255])])), 'one', 'one 4-bit bucket')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(50, [0, 0, 0, 255]), ...fillPixels(50, [16, 0, 0, 255])])), 'multi', 'two buckets')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(100, [10, 10, 10, 255]), ...fillPixels(900, [255, 0, 0, 20])])), 'one', 'alpha 20/255 < 0.1 ignored')
  assert.equal(cylGIFColorKind(pixels(fillPixels(10, [255, 0, 0, 0]))), 'unknown', 'nothing visible')
  assert.equal(cylGIFColorKind(null), 'unknown')
  assert.equal(cylGIFColorKind(pixels(fillPixels(10, [64, 64, 64, 128])), true), 'one', 'premultiplied: un-premultiplied first')
  assert.equal(cylGIFColorKind(pixels([...fillPixels(50, [64, 64, 64, 128]), ...fillPixels(50, [128, 128, 128, 255])]), true), 'one', '64/0.5 = 128 is the same bucket as 128')
})

test('built-in colors are the probe values; the selected one yields to the host default', () => {
  const c = m.cylAnimatedItemBuiltInColor
  assert.deepEqual([c('label', false), c('label', true)], ['rgb(0,0,0)', 'rgb(255,255,255)'])
  assert.deepEqual([c('secondaryLabel', false), c('secondaryLabel', true)], ['rgba(60,60,67,0.6)', 'rgba(235,235,245,0.6)'])
  assert.deepEqual([c('disabled', false), c('disabled', true)], ['rgba(134,134,134,0.45)', 'rgba(140,140,140,0.35)'])
  assert.deepEqual([c('selected', false), c('selected', true)], ['rgb(0,136,255)', 'rgb(0,145,255)'])
  const eff = m.cylAnimatedItemEffectiveIconColor
  assert.equal(eff({}), 'rgb(0,0,0)')
  assert.equal(eff({ isDark: true }), 'rgb(255,255,255)')
  assert.equal(eff({ selected: true, builtInSelectedColor: '#07C160' }), '#07C160')
  assert.equal(eff({ selected: true, builtInSelectedColor: '#07C160', selectedIconTint: '#112233' }), '#112233')
  assert.equal(eff({ iconTint: '#445566' }), '#445566')
  assert.equal(eff({ enabled: false }), 'rgba(134,134,134,0.45)')
  assert.equal(eff({ enabled: false, isDark: true, selected: true }), 'rgba(140,140,140,0.35)')
  assert.equal(eff({ enabled: false, iconTint: '#445566' }), '#445566', 'an explicit color of the state wins over the disabled built-in')
  // the title uses them, adaptive with nothing set
  assert.equal(m.cylAnimatedItemModel({ title: 'A', systemTheme: 'dark' }).titleStyle, 'color: rgb(255,255,255);')
  assert.equal(m.cylAnimatedItemModel({ title: 'A', selected: true }).titleStyle, 'color: rgb(0,136,255);')
  assert.equal(m.cylAnimatedItemModel({ title: 'A', selected: true, builtInSelectedColor: '#07C160' }).titleStyle, 'color: #07C160;')
  assert.equal(m.cylAnimatedItemModel({ title: 'A', enabled: false }).titleStyle, 'color: rgba(134,134,134,0.45);')
  assert.equal(m.cylAnimatedItemModel({ title: 'A', titleColor: '#123456', selected: true }).titleStyle, 'color: #123456;')
})

// [EN] Rows: [animationType file, props, expected]. Rive is undetectable (automatic keeps its colors); alwaysTemplate tints Rive and GIF only. [CN] 渲染模式真值行。
const MODES = [
  ['a.riv', {}, ''], ['a.riv', { animationRenderingMode: 'automatic', animationColorKind: 'one' }, 'rgb(0,0,0)'], ['a.riv', { animationColorKind: 'multi' }, ''], ['a.riv', { animationColorKind: 'unknown' }, ''],
  ['a.riv', { animationRenderingMode: 'alwaysTemplate' }, 'rgb(0,0,0)'], ['a.riv', { animationRenderingMode: 'alwaysTemplate', selected: true }, 'rgb(0,136,255)'],
  ['a.riv', { animationRenderingMode: 'alwaysTemplate', selected: true, selectedIconTint: '#07C160' }, '#07C160'],
  ['a.riv', { animationRenderingMode: 'alwaysTemplate', iconTint: '#445566' }, '#445566'], ['a.riv', { animationRenderingMode: 'alwaysTemplate', systemTheme: 'dark' }, 'rgb(255,255,255)'],
  ['a.riv', { animationRenderingMode: 'alwaysOriginal', animationColorKind: 'one' }, ''], ['a.riv', { animationRenderingMode: 'alwaysOriginal', animationTint: '#FF8800' }, '#FF8800'],
  ['a.riv', { animationRenderingMode: ' ALWAYSTEMPLATE ' }, 'rgb(0,0,0)'], ['a.riv', { animationRenderingMode: 'bogus', animationColorKind: 'one' }, 'rgb(0,0,0)'], ['a.riv', { animationRenderingMode: 'bogus' }, ''],
  ['a.gif', {}, ''], ['a.gif', { animationColorKind: 'one' }, 'rgb(0,0,0)'], ['a.gif', { animationColorKind: 'multi' }, ''], ['a.gif', { animationRenderingMode: 'alwaysTemplate', animationColorKind: 'multi' }, 'rgb(0,0,0)'],
  ['a.gif', { animationColorKind: 'one', animationRenderingMode: 'alwaysOriginal' }, ''],
  // Lottie, PAG and SVGA cannot be recolored here: the rendering mode never tints them (an explicit tint is still resolved, as everywhere)
  ['a.json', { animationRenderingMode: 'alwaysTemplate', animationColorKind: 'one' }, ''], ['a.pag', { animationRenderingMode: 'alwaysTemplate' }, ''], ['a.svga', { animationColorKind: 'one' }, ''],
  // the URL option renderingMode=, below the property
  ['a.riv#renderingMode=alwaysTemplate', {}, 'rgb(0,0,0)'], ['a.riv#artboard=X&renderingMode=alwaysOriginal', { animationColorKind: 'one' }, ''],
  ['a.riv#renderingMode=alwaysOriginal', { animationRenderingMode: 'alwaysTemplate' }, 'rgb(0,0,0)'], ['a.riv#renderingMode=alwaysTemplate', { animationRenderingMode: 'alwaysOriginal' }, ''],
  ['a.riv#renderingMode=alwaysTemplate', { animationTint: '#FF8800' }, '#FF8800'],
]

test('animation rendering mode truth table (through the item model)', () => {
  for (const [animationUrl, props, expected] of MODES) {
    const input = { animationUrl, ...props }
    assert.equal(m.cylAnimatedItemModel(input).animationTint, expected, JSON.stringify(input))
  }
})

test('a FIXED animationTint on a selected item yields only to an EXPLICIT selected icon color, never to the built-in selected color', () => {
  const base = { animationUrl: 'a.riv', animationTint: '#FF8800', selected: true }
  assert.equal(m.cylAnimatedItemModel(base).animationTint, '#FF8800')
  assert.equal(m.cylAnimatedItemModel({ ...base, builtInSelectedColor: '#07C160' }).animationTint, '#FF8800')
  assert.equal(m.cylAnimatedItemModel({ ...base, iconTint: '#445566' }).animationTint, '#FF8800', 'the normal explicit color does not count either')
  assert.equal(m.cylAnimatedItemModel({ ...base, selectedIconTint: '#112233' }).animationTint, '#112233')
  assert.equal(m.cylAnimatedItemModel({ ...base, animationTint: 'title' }).animationTint, 'rgb(0,136,255)', '"title" uses the effective color: the built-in selected')
})

// [EN] WCAG contrast of a CSS color (rgb / rgba / #hex) composited over a bar color. [CN] 以 WCAG 公式计算叠加在 TabBar 颜色上的对比度。
function channels(color) {
  const fn = /^rgba?\((\d+),(\d+),(\d+)(?:,([\d.]+))?\)$/.exec(color)
  if (fn) return [Number(fn[1]), Number(fn[2]), Number(fn[3]), fn[4] === undefined ? 1 : Number(fn[4])]
  const hex = /^#([0-9a-f]{6})$/i.exec(color)
  return [0, 2, 4].map((i) => Number.parseInt(hex[1].slice(i, i + 2), 16)).concat(1)
}
function luminance(rgb) {
  const [r, g, b] = rgb.map((v) => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4 })
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
function contrast(line, bar) {
  const [r, g, b, a] = channels(line)
  const back = channels(bar)
  const blended = [r, g, b].map((v, i) => v * a + back[i] * (1 - a))
  const [l1, l2] = [luminance(blended), luminance(back.slice(0, 3))].sort((x, y) => y - x)
  return (l1 + 0.05) / (l2 + 0.05)
}

test('divider contrast: the default (secondaryLabel) and an explicit label color at alpha 0.6 are >= 3:1 on light and dark bars', () => {
  assert.equal(m.CYL_ANIMATED_ITEM_DIVIDER_ALPHA, 0.6)
  const BARS = { light: ['#FFFFFF', '#F2F2F7'], dark: ['#000000', '#1C1C1E'] }
  for (const style of ['light', 'dark']) {
    const label = style === 'dark' ? '#FFFFFF' : '#000000'
    const derived = m.cylAnimatedItemDividerColor({ userInterfaceStyle: style })
    const fromIcon = m.cylAnimatedItemDividerColor({ userInterfaceStyle: style, iconTint: label })
    assert.equal(fromIcon, `rgba(${style === 'dark' ? '255,255,255' : '0,0,0'},0.6)`)
    for (const bar of BARS[style]) {
      assert.ok(contrast(derived, bar) >= 3, `${style} default on ${bar}: ${contrast(derived, bar)}`)
      assert.ok(contrast(fromIcon, bar) >= 3, `${style} explicit label on ${bar}: ${contrast(fromIcon, bar)}`)
    }
  }
  // the default over a white bar and a black bar, as the owner measured (about 3:1 or better)
  assert.ok(contrast('rgba(60,60,67,0.6)', '#FFFFFF') >= 3 && contrast('rgba(235,235,245,0.6)', '#000000') >= 3)
})

test('stack: rendering mode and built-in selected color are inherited; the item wins; cleared inherits nothing', () => {
  const pick = (model) => model.items.map((i) => [i.animationRenderingMode, i.builtInSelectedColor, i.titleColor])
  let model = cylStackModel({ animationRenderingMode: 'alwaysTemplate', defaultSelectedColor: '#07C160', titleColor: '#333333', items: [{ title: 'a' }, { title: 'b', animationRenderingMode: 'alwaysOriginal', titleColor: '#111111' }] })
  assert.deepEqual(pick(model), [['alwaysTemplate', '#07C160', '#333333'], ['alwaysOriginal', '#07C160', '#111111']])
  assert.equal(model.divider.builtInSelectedColor, '#07C160')
  model = cylStackModel({ items: [{ title: 'a' }, { title: 'b' }] })
  assert.deepEqual(pick(model), [['', '', ''], ['', '', '']])
  const appended = cylStackModel({ animationRenderingMode: 'alwaysTemplate', items: [{ title: 'a' }, { title: 'later' }] })
  assert.equal(appended.items[1].animationRenderingMode, 'alwaysTemplate')
  // explicit colors the stack hands over stay explicit: the built-ins are computed in the item, never stored
  const tinted = cylStackModel({ iconColor: '#888888', items: [{ title: 'a', selected: true }] }).items[0]
  assert.equal(tinted.animationSelectedIconTint, '')
  assert.equal(m.cylAnimatedItemModel({ title: 'a', animationUrl: 'a.riv', animationRenderingMode: 'alwaysTemplate', selected: true, animationIconTint: tinted.animationIconTint, animationSelectedIconTint: tinted.animationSelectedIconTint }).animationTint, 'rgb(0,136,255)')
})

test('tab URL option renderingMode= is read; tab bars pass alwaysOriginal without a tint option (today\'s look)', () => {
  const env = { animationBasePath: '', isDark: false }
  const lottie = (extra) => reader.cylRive({ CYLTabBarAnimationFilePath: '/a/b.riv', ...extra }, env)
  assert.equal(lottie({}).renderingMode, '')
  assert.equal(lottie({ CYLTabBarAnimationFilePath: '/a/b.riv#renderingMode=alwaysTemplate' }).renderingMode, 'alwaysTemplate')
  assert.equal(lottie({ CYLTabBarAnimationOptions: { renderingMode: 'ALWAYSORIGINAL' } }).renderingMode, 'alwaysOriginal')
  assert.equal(lottie({ CYLTabBarAnimationOptions: { renderingMode: 'automatic' } }).renderingMode, 'automatic')
  assert.equal(lottie({ CYLTabBarAnimationOptions: { renderingMode: 'bogus' } }).renderingMode, '')
  // the tab bar's rule, read from the source (cylAnimationProperties is not exported)
  const source = fs.readFileSync(path.join(__dirname, '../src/cyl-tab-bar/index.js'), 'utf8')
  assert.match(source, /animationRenderingMode: lottie\.renderingMode \|\| \(lottie\.tint \? '' : 'alwaysOriginal'\)/)
  assert.match(source, /animationTint: '', animationDarkTint: '', animationRenderingMode: ''/)
  assert.match(fs.readFileSync(path.join(__dirname, '../src/cyl-tab-bar/index.wxml'), 'utf8'), /animation-rendering-mode="\{\{item\.item\.animationRenderingMode\}\}"/)
  assert.match(fs.readFileSync(path.join(__dirname, '../src/cyl-tab-bar-item/index.wxml'), 'utf8'), /animation-rendering-mode="\{\{m\.animationRenderingMode\}\}"/)
  assert.equal(require('../src/cyl-tab-bar-item/cyl_tab_bar_item_model').cylItemModel({ animationRenderingMode: 'alwaysOriginal' }).animationRenderingMode, 'alwaysOriginal')
})

function runtime() {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const key = Object.keys(definition.observers)[0]
  return (properties) => {
    const data = { ...definition.data }
    Object.entries(definition.properties).forEach(([name, value]) => { data[name] = value.value })
    Object.assign(data, { loggedIn: true, itemStyle: 'liquidGlass' }, properties)
    const bar = {
      data, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {}, selectComponent: () => null, triggerEvent() {},
      setData(patch, callback) {
        Object.assign(this.data, patch)
        if (key.split(',').some((name) => name.trim() in patch)) definition.observers[key].call(this)
        if (callback) callback()
      },
      ...definition.methods,
    }
    bar.cyl_syncLottie = () => {}
    bar.cyl_playTapAnimation = () => {}
    bar.cyl_playTabButtonTapFeedback = () => {}
    bar.cyl_recordTap = () => {}
    bar.cylLongPressed = false
    definition.lifetimes.attached.call(bar)
    return bar
  }
}


const RUNTIME_TABS = [
  { CYLTabBarItemIdentifier: 'a', CYLTabBarItemTitle: 'A', CYLTabBarItemImage: 'a.png', CYLTabBarItemSelectedImage: 'a-s.png', CYLTabBarItemPageIdentifier: 'a', CYLTabBarAnimationFilePath: '/x/a.riv' },
  { CYLTabBarItemIdentifier: 'b', CYLTabBarItemTitle: 'B', CYLTabBarItemImage: 'b.png', CYLTabBarItemSelectedImage: 'b-s.png', CYLTabBarItemPageIdentifier: 'b', CYLTabBarAnimationFilePath: '/x/b.riv#tint=title' },
  { CYLTabBarItemIdentifier: 'c', CYLTabBarItemTitle: 'C', CYLTabBarItemImage: 'c.png', CYLTabBarItemSelectedImage: 'c-s.png', CYLTabBarItemPageIdentifier: 'c', CYLTabBarAnimationFilePath: '/x/c.riv#renderingMode=alwaysTemplate' },
]

test('the rendered tab bar: no tint option = alwaysOriginal; tint=title keeps the tint (no mode); renderingMode= is passed on', () => {
  const bar = runtime()({ configuration: { CYLTabBarControllerTabBarItemsAttributes: RUNTIME_TABS } })
  const modes = bar.data.cylSlots.map((slot) => [slot.item.animationRenderingMode, slot.item.animationTint])
  assert.deepEqual(modes, [['alwaysOriginal', ''], ['', 'title'], ['alwaysTemplate', '']])
})
