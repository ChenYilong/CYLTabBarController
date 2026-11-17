/**
 * [EN] Tests of cyl-animated-item's render model (src/cyl-animated-item/cyl_animated_item_model.js): the display priority
 *      shared with iOS and Android (animation, then the static image, then the placeholder), failures, GIF, layout and
 *      accessibility. Run: `npm test`.
 * [CN] cyl-animated-item 渲染模型的测试：与 iOS、Android 相同的显示优先级（动画、静态图片、占位图）、失败、GIF、布局与无障碍。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylAnimatedItemModel, cylAnimatedItemType, cylAnimatedItemPackage, cylAnimatedItemRestingProgress, cylAnimatedItemGifSource, CYL_ANIMATED_ITEM_PLACEHOLDER } = require('../src/cyl-animated-item/cyl_animated_item_model')

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
