/**
 * [EN] Tests of cyl-animated-item's render model (src/cyl-animated-item/cyl_animated_item_model.js): the display priority
 *      shared with iOS and Android (animation, then the static image, then the placeholder), failures, GIF, layout and
 *      accessibility. Run: `npm test`.
 * [CN] cyl-animated-item 渲染模型的测试：与 iOS、Android 相同的显示优先级（动画、静态图片、占位图）、失败、GIF、布局与无障碍。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylAnimatedItemModel, cylAnimatedItemType, cylAnimatedItemPackage, CYL_ANIMATED_ITEM_PLACEHOLDER } = require('../src/cyl-animated-item/cyl_animated_item_model')

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

test('cyl-animated-item: the same file set again keeps the loaded state (the engine view sends no second ready)', () => {
  let definition = null
  global.Component = (options) => { definition = options }
  delete require.cache[require.resolve('../src/cyl-animated-item/index.js')]
  require('../src/cyl-animated-item/index.js')
  delete global.Component
  const observer = definition.observers['animationUrl, animationType']
  const resets = []
  const item = {
    data: { animationFailed: false },
    setData(data) { if (data.animationLoaded === false) resets.push(data) },
    cyl_update() {},
  }
  observer.call(item, '/a.json', '')
  observer.call(item, '/a.json', '')
  observer.call(item, '/a.json', '')
  assert.equal(resets.length, 1, 'set again with the same file: no reset')
  observer.call(item, '/b.json', '')
  assert.equal(resets.length, 2, 'a new file resets')
  observer.call(item, '/b.json', 'lottie')
  assert.equal(resets.length, 3, 'a new type resets')
})

test('cyl-animated-item: the same file after a failure is a retry and resets the state', () => {
  let definition = null
  global.Component = (options) => { definition = options }
  delete require.cache[require.resolve('../src/cyl-animated-item/index.js')]
  require('../src/cyl-animated-item/index.js')
  delete global.Component
  const observer = definition.observers['animationUrl, animationType']
  const item = {
    data: { animationFailed: false },
    setData(data) { Object.assign(this.data, data) },
    cyl_update() {},
  }
  observer.call(item, 'https://x/a.json', '')
  item.data.animationFailed = true
  observer.call(item, 'https://x/a.json', '')
  assert.equal(item.data.animationFailed, false, 'a retry clears the failure')
})
