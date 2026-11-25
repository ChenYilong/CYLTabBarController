/**
 * [EN] Tests of cyl-animated-item's render model (src/cyl-animated-item/cyl_animated_item_model.js): the display priority
 *      shared with iOS and Android (animation, then the static image, then the placeholder), failures, GIF, layout and
 *      accessibility. Run: `npm test`.
 * [CN] cyl-animated-item 渲染模型的测试：与 iOS、Android 相同的显示优先级（动画、静态图片、占位图）、失败、GIF、布局与无障碍。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylAnimatedItemMissingReason, cylAnimatedItemResource, cylAnimatedItemModel, cylAnimatedItemType, cylAnimatedItemPackage, cylAnimatedItemRestingProgress, cylAnimatedItemGifSource, CYL_ANIMATED_ITEM_PLACEHOLDER } = require('../src/cyl-animated-item/cyl_animated_item_model')

test('the animation type from the extension', () => {
  assert.deepEqual(['a.json', 'a.lottie', 'a.pag', 'a.riv', 'a.svga', 'a.gif', 'a.png', 'https://x/a.riv#artboard=HOME', ''].map(cylAnimatedItemType),
    ['lottie', 'lottie', 'pag', 'rive', 'svga', 'gif', '', 'rive', ''])
  assert.equal(cylAnimatedItemPackage('pag'), 'cyl-pag-miniprogram')
  assert.equal(cylAnimatedItemPackage('gif'), '')
})

test('a static image only', () => {
  const m = cylAnimatedItemModel({ title: 'Home', image: 'a.png', selectedImage: 'b.png' })
  assert.equal(m.fallbackImage, 'a.png')
  assert.equal(m.usesEngine, false)
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selectedImage: 'b.png', selected: true }).fallbackImage, 'b.png')
})

test('an animation shows only once its engine is ready; the static image stays until then', () => {
  const loading = cylAnimatedItemModel({ image: 'a.png', animationUrl: 'home.json' })
  assert.equal(loading.usesEngine, true)
  assert.equal(loading.fallbackImage, 'a.png')
  assert.equal(loading.fallbackHidden, false)
  const ready = cylAnimatedItemModel({ image: 'a.png', animationUrl: 'home.json', animationLoaded: true })
  assert.equal(ready.fallbackHidden, true)
})

test('the placeholder only without a static image, while loading and after a failure', () => {
  assert.equal(cylAnimatedItemModel({ animationUrl: 'home.pag' }).fallbackImage, CYL_ANIMATED_ITEM_PLACEHOLDER)
  const failed = cylAnimatedItemModel({ animationUrl: 'home.pag', animationLoaded: true, animationFailed: true })
  assert.equal(failed.usesEngine, false)
  assert.equal(failed.fallbackImage, CYL_ANIMATED_ITEM_PLACEHOLDER)
  assert.equal(cylAnimatedItemModel({ image: 'a.png', animationUrl: 'home.pag', animationFailed: true }).fallbackImage, 'a.png')
  assert.equal(cylAnimatedItemModel({ animationUrl: 'home.pag', placeholderImage: '' }).fallbackImage, '', 'an empty placeholder shows none')
  assert.equal(cylAnimatedItemModel({ title: 'Only a title' }).showsIcon, false)
})

test('an unknown file type plays nothing and falls back', () => {
  const m = cylAnimatedItemModel({ image: 'a.png', animationUrl: 'photo.webp' })
  assert.equal(m.usesEngine, false)
  assert.equal(m.fallbackImage, 'a.png')
})

test('GIF is drawn by <image>, without an engine', () => {
  const m = cylAnimatedItemModel({ image: 'a.png', animationUrl: 'tab.gif' })
  assert.equal(m.gifPath, 'tab.gif')
  assert.equal(m.usesEngine, false)
  assert.equal(cylAnimatedItemModel({ animationUrl: 'tab.gif', animationFailed: true }).gifPath, '')
})

test('layout, accessory and accessibility', () => {
  const m = cylAnimatedItemModel({ title: 'Tag', axis: 'vertical', iconSize: 30, accessoryText: '×', accessoryAccessibilityLabel: 'Delete',
    accessoryPlacement: 'topTrailing', selected: true, enabled: false })
  assert.equal(m.axisClass, 'cyl-animated-item-vertical')
  assert.equal(m.iconStyle, 'width: 30px; height: 30px;')
  assert.equal(m.hasAccessory, true)
  assert.equal(m.accessoryLabel, 'Delete')
  assert.equal(m.accessoryPlacement, 'topTrailing')
  assert.equal(m.ariaLabel, 'Tag')
  assert.equal(m.ariaSelected, true)
  assert.equal(m.ariaDisabled, true)
  assert.equal(cylAnimatedItemModel({ title: 'Tag', accessibilityLabel: 'Tag, 3 new' }).ariaLabel, 'Tag, 3 new')
  assert.equal(cylAnimatedItemModel({ accessoryPlacement: 'nowhere', accessoryText: 'x' }).accessoryPlacement, 'trailing')
})

test('cyl-animated-item: a non-square icon and a static image tint for a host (the tab bar item)', () => {
  const m = cylAnimatedItemModel({ image: 'a.png', iconSize: 24, iconWidth: 30, iconHeight: 20, iconTint: '#ff0000' })
  assert.equal(m.iconStyle, 'width: 30px; height: 20px;')
  assert.equal(m.iconTint, '#ff0000')
  // [EN] Without them: the square icon size, no tint. [CN] 未设置时：正方形图标尺寸，不着色。
  const plain = cylAnimatedItemModel({ image: 'a.png', iconSize: 24 })
  assert.equal(plain.iconStyle, 'width: 24px; height: 24px;')
  assert.equal(plain.iconTint, '')
})

test('cyl-animated-item: a GIF tab icon draws itself; a failed engine shows the image, else the placeholder', () => {
  const gif = cylAnimatedItemModel({ animationUrl: 'tab.gif', image: 'a.png' })
  assert.equal(gif.gifPath, 'tab.gif')
  const failed = cylAnimatedItemModel({ animationUrl: 'tab.json', animationFailed: true })
  assert.equal(failed.usesEngine, false)
  assert.equal(failed.fallbackImage, CYL_ANIMATED_ITEM_PLACEHOLDER)
})

test('cyl-animated-item: *.svga.bin / *.pag.bin / *.riv.bin keep their type, animationType names it (bug B6)', () => {
  assert.equal(cylAnimatedItemType('/assets/tab/svga/tab_activity.svga.bin'), 'svga')
  assert.equal(cylAnimatedItemType('home.pag.bin?v=2'), 'pag')
  assert.equal(cylAnimatedItemType('icons.riv.BIN'), 'rive')
  assert.equal(cylAnimatedItemType('data.bin'), '')
  const m = cylAnimatedItemModel({ animationUrl: '/assets/tab/svga/tab_activity.svga.bin' })
  assert.equal(m.animationType, 'svga')
  assert.equal(m.usesEngine, true)
  const named = cylAnimatedItemModel({ animationUrl: 'https://example.com/icon', animationType: 'Lottie' })
  assert.equal(named.animationType, 'lottie')
  assert.equal(cylAnimatedItemModel({ animationUrl: 'a.json', animationType: 'unknown' }).animationType, 'lottie')
})

test('cyl-animated-item: the placeholder is a data URI, not a path the page would resolve (bug B6)', () => {
  assert.match(CYL_ANIMATED_ITEM_PLACEHOLDER, /^data:image\/png;base64,iVBORw0KGgo/)
  assert.equal(cylAnimatedItemModel({ animationUrl: 'unknown.xyz' }).fallbackImage, CYL_ANIMATED_ITEM_PLACEHOLDER)
})

test('Lottie data instead of a file: a Lottie engine, the placeholder until it is ready', () => {
  const m = cylAnimatedItemModel({ animationData: { v: '5.7', layers: [] } })
  assert.equal(m.animationType, 'lottie')
  assert.equal(m.usesEngine, true)
  assert.equal(m.fallbackImage, CYL_ANIMATED_ITEM_PLACEHOLDER)
  assert.equal(cylAnimatedItemModel({ animationData: { v: '5.7' }, animationLoaded: true }).fallbackImage, '')
  assert.equal(cylAnimatedItemModel({ animationData: { v: '5.7' }, animationFailed: true }).usesEngine, false)
})

test('the resting progress and frame: the last while selected, else restingProgress in 0...1', () => {
  assert.equal(cylAnimatedItemRestingProgress({}), 0)
  assert.equal(cylAnimatedItemRestingProgress({ restingProgress: 0.4 }), 0.4)
  assert.equal(cylAnimatedItemRestingProgress({ restingProgress: 3 }), 1)
  assert.equal(cylAnimatedItemRestingProgress({ restingProgress: -1 }), 0)
  assert.equal(cylAnimatedItemRestingProgress({ restingProgress: 0.4, selected: true }), 1)
  assert.equal(cylAnimatedItemModel({ animationUrl: 'a.json' }).restingFrame, 'first')
  assert.equal(cylAnimatedItemModel({ animationUrl: 'a.json', selected: true }).restingFrame, 'last')
})

test('GIF stills: the first frame at rest, the last while selected, the GIF while it plays', () => {
  const p = { animationUrl: 'star.gif', gifFirstFrame: 'first.png', gifLastFrame: 'last.png' }
  assert.equal(cylAnimatedItemModel(p).gifPath, 'first.png')
  assert.equal(cylAnimatedItemModel({ ...p, selected: true }).gifPath, 'last.png')
  assert.equal(cylAnimatedItemModel({ ...p, restingProgress: 1 }).gifPath, 'last.png')
  assert.equal(cylAnimatedItemModel({ ...p, gifPlaying: true }).gifPath, 'star.gif')
  assert.equal(cylAnimatedItemGifSource({ gifLastFrame: 'last.png' }, 'star.gif'), 'last.png', 'a missing still uses the other one')
  assert.equal(cylAnimatedItemGifSource({}, 'star.gif'), 'star.gif', 'without stills the GIF plays, as before')
})

test('a named type wins over the extension (files renamed to .bin for a code package)', () => {
  assert.equal(cylAnimatedItemModel({ animationUrl: '/rive/house.riv.bin', animationType: 'rive' }).animationType, 'rive')
  assert.equal(cylAnimatedItemModel({ animationUrl: '/pag/0.pag.bin', animationType: 'pag' }).usesEngine, true)
  // [EN] Without a name, *.pag.bin keeps its type too (bug B6). [CN] 未指定类型时 *.pag.bin 也保留其类型（bug B6）。
  assert.equal(cylAnimatedItemModel({ animationUrl: '/pag/0.pag.bin' }).usesEngine, true)
  assert.equal(cylAnimatedItemModel({ animationUrl: 'a.json', animationType: 'unknown' }).animationType, 'lottie')
})

test('embedded in a control: hidden from accessibility, no padding class of its own', () => {
  const m = cylAnimatedItemModel({ animationUrl: 'a.json', embedded: true })
  assert.equal(m.ariaHidden, true)
  assert.match(m.axisClass, /cyl-animated-item-embedded/)
  assert.equal(cylAnimatedItemModel({ animationUrl: 'a.json' }).ariaHidden, false)
})

test('cyl-animated-item: the same file set again keeps the loaded state (the engine view sends no second ready)', () => {
  let definition = null
  global.Component = (options) => { definition = options }
  delete require.cache[require.resolve('../src/cyl-animated-item/index.js')]
  require('../src/cyl-animated-item/index.js')
  delete global.Component
  const observer = definition.observers['animationUrl, animationData, animationType']
  const resets = []
  const item = {
    data: { animationFailed: false },
    setData(data) { if (data.animationLoaded === false) resets.push(data) },
    cyl_update() {},
  }
  observer.call(item, '/a.json', null, '')
  observer.call(item, '/a.json', null, '')
  observer.call(item, '/a.json', null, '')
  assert.equal(resets.length, 1, 'set again with the same file: no reset')
  observer.call(item, '/b.json', null, '')
  assert.equal(resets.length, 2, 'a new file resets')
  observer.call(item, '/b.json', null, 'lottie')
  assert.equal(resets.length, 3, 'a new type resets')
})

test('cyl-animated-item: the same file after a failure is a retry and resets the state', () => {
  let definition = null
  global.Component = (options) => { definition = options }
  delete require.cache[require.resolve('../src/cyl-animated-item/index.js')]
  require('../src/cyl-animated-item/index.js')
  delete global.Component
  const observer = definition.observers['animationUrl, animationData, animationType']
  const item = {
    data: { animationFailed: false },
    setData(data) { Object.assign(this.data, data) },
    cyl_update() {},
  }
  observer.call(item, 'https://x/a.json', null, '')
  item.data.animationFailed = true
  observer.call(item, 'https://x/a.json', null, '')
  assert.equal(item.data.animationFailed, false, 'a retry clears the failure')
})

test('title color, font size and line count', () => {
  const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')
  const plain = model({ title: 'A' })
  assert.equal(plain.titleStyle, 'color: rgb(0,0,0);', 'no explicit color: the built-in label color')
  assert.equal(plain.titleLinesClass, '')
  const styled = model({ title: 'A', titleColor: '#FF0000', titleFontSize: 17, titleLines: 2 })
  assert.equal(styled.titleStyle, 'color: #FF0000;font-size: 17px;-webkit-line-clamp: 2;')
  assert.equal(styled.titleLinesClass, 'cyl-animated-item-title-wrap cyl-animated-item-title-clamp')
  assert.equal(model({ title: 'A', titleLines: 0 }).titleLinesClass, 'cyl-animated-item-title-wrap')
  assert.equal(model({ title: 'A', titleLines: -3 }).titleLinesClass, '')
})

test('title line height and spacing; spacing follows the axis', () => {
  const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')
  const L = 'color: rgb(0,0,0);'
  assert.equal(model({ title: 'A', titleSpacing: -1 }).titleStyle, L)
  assert.equal(model({ title: 'A', axis: 'vertical', titleLineHeight: 22, titleSpacing: 12 }).titleStyle, L + 'line-height: 22px;margin-top: 12px;')
  assert.equal(model({ title: 'A', axis: 'horizontal', titleSpacing: 0 }).titleStyle, L + 'margin-left: 0px;')
})

test('title font weight: keywords and 100–900 only', () => {
  const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')
  const L = 'color: rgb(0,0,0);'
  assert.equal(model({ title: 'A', titleFontWeight: 'bold' }).titleStyle, L + 'font-weight: bold;')
  assert.equal(model({ title: 'A', titleFontWeight: 600 }).titleStyle, L + 'font-weight: 600;')
  assert.equal(model({ title: 'A', titleFontWeight: '650' }).titleStyle, L)
  assert.equal(model({ title: 'A', titleFontWeight: 'red; x' }).titleStyle, L)
  assert.equal(model({ title: 'A', titleFontWeight: '' }).titleStyle, L)
})

test('title dark color follows userInterfaceStyle and the system theme', () => {
  const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')
  const base = { title: 'A', titleColor: '#333333', titleDarkColor: '#EEEEEE' }
  assert.equal(model({ ...base, systemTheme: 'light' }).titleStyle, 'color: #333333;')
  assert.equal(model({ ...base, systemTheme: 'dark' }).titleStyle, 'color: #EEEEEE;')
  assert.equal(model({ ...base, systemTheme: 'dark', userInterfaceStyle: 'light' }).titleStyle, 'color: #333333;')
  assert.equal(model({ ...base, systemTheme: 'light', userInterfaceStyle: 'dark' }).titleStyle, 'color: #EEEEEE;')
  assert.equal(model({ title: 'A', titleColor: '#333333', systemTheme: 'dark' }).titleStyle, 'color: #333333;')
  assert.equal(model({ title: 'A', titleDarkColor: '#EEEEEE', systemTheme: 'light' }).titleStyle, 'color: rgb(0,0,0);', 'light: the built-in label')
  assert.equal(model({ title: 'A', systemTheme: 'dark' }).titleStyle, 'color: rgb(255,255,255);')
})

test('animationTint passes to the Rive engine as one color', () => {
  const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')
  assert.equal(model({ animationUrl: 'a.riv', animationTint: ' #007AFF ' }).animationTint, '#007AFF')
  assert.equal(model({ animationUrl: 'a.riv' }).animationTint, '')
})

test('the reason of resourcemissing is one of the four strings every platform uses', () => {
  assert.equal(cylAnimatedItemMissingReason('cyl-tab-bar: no animation component for a.riv; install its package and set the generic'), 'engine library missing')
  assert.equal(cylAnimatedItemMissingReason('request:fail 404'), 'not found')
  assert.equal(cylAnimatedItemMissingReason('ENOENT: no such file or directory'), 'not found')
  assert.equal(cylAnimatedItemMissingReason('EACCES permission denied'), 'unreadable')
  assert.equal(cylAnimatedItemMissingReason('bad file'), 'decode failed')
  assert.equal(cylAnimatedItemMissingReason(undefined), 'decode failed')
})

test('the resource is the file as configured, without the # options', () => {
  assert.equal(cylAnimatedItemResource('icons.riv#artboard=CHAT'), 'icons.riv')
  assert.equal(cylAnimatedItemResource('https://x/a.json'), 'https://x/a.json')
  assert.equal(cylAnimatedItemResource(undefined), '')
})
