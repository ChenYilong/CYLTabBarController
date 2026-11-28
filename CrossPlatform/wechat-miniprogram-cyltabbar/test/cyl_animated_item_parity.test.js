'use strict'

/**
 * [EN] iOS parity of cyl-animated-item (the tint unification of CYLAnimatedItemView): the precedence of the color levels, the subclass-explicit and
 *      subclass built-in channels per state, the adaptation on drawn dark glass (explicit and built-in levels, not light, flat or the disabled look),
 *      drawsLiquidGlass / drawsFlatBackground, the rendered-glass floor and the options with their defaults off. Run: `npm test`.
 * [CN] cyl-animated-item 与 iOS 的对齐（CYLAnimatedItemView 的 tint 统一）：颜色层级的优先级、按状态的子类显式与子类内置通道、在绘制的深色玻璃上的适配
 *      （显式与内置层，不含浅色、扁平与禁用外观）、drawsLiquidGlass / drawsFlatBackground、实际渲染玻璃的下限，以及默认关闭的选项。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')
const contrastModule = require('../src/cyl-animated-item/cyl_animated_item_contrast')
const model = require('../src/cyl-animated-item/cyl_animated_item_model')

const {
  cylAnimatedItemContrastLift, cylAnimatedItemGlassReferenceLuminance, cylAnimatedItemRenderedGlassReferenceLuminance,
  cylAnimatedItemRenderedDarkGlassWhiteShare, CYL_TITLE_MINIMUM_CONTRAST, CYL_ICON_MINIMUM_CONTRAST,
} = contrastModule
const {
  cylAnimatedItemModel, cylAnimatedItemResolvedTitleColor, cylAnimatedItemResolvedIconColor, cylAnimatedItemAdaptedColor, cylAnimatedItemDrawsLiquidGlass,
  cylAnimatedItemDrawsFlatBackground, cylAnimatedItemLiquidGlassSetActiveOverride, cylAnimatedItemResolvedContentHorizontalInset,
  cylAnimatedItemIsAnimationEngineAvailable, CYL_ADAPTED_KIND_ICON, CYL_ADAPTED_KIND_TITLE, CYL_ADAPTED_KIND_TEXT,
} = model

test.afterEach(() => cylAnimatedItemLiquidGlassSetActiveOverride(undefined))

const DARK_TEXT = '#3C3C43'
const DARK_GLASS = { itemBackgroundStyle: 'liquidGlass', userInterfaceStyle: 'dark' }
const LIGHT_GLASS = { itemBackgroundStyle: 'liquidGlass', userInterfaceStyle: 'light' }
const DARK_FLAT = { itemBackgroundStyle: 'flat', userInterfaceStyle: 'dark' }

const luminance = (hex) => {
  const n = parseInt(hex.slice(1, 7), 16)
  const ch = (v) => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4) }
  return 0.2126 * ch(Math.floor(n / 65536)) + 0.7152 * ch(Math.floor(n / 256) % 256) + 0.0722 * ch(n % 256)
}
const renderedContrast = (hex) => {
  const a = luminance(hex)
  const b = cylAnimatedItemRenderedGlassReferenceLuminance()
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
}
const titleColorOf = (props) => /color: ([^;]+);/.exec(cylAnimatedItemModel({ title: 'T', ...props }).titleStyle)?.[1]

// ---------------------------------------------------------------- the rendered-glass floor

test('the floor: a constant above the model, max(model, floor), calculated for the dark plate (not black)', () => {
  assert.ok(cylAnimatedItemRenderedDarkGlassWhiteShare > 0.14 && cylAnimatedItemRenderedDarkGlassWhiteShare < 0.5)
  const model14 = cylAnimatedItemGlassReferenceLuminance()
  const reference = cylAnimatedItemRenderedGlassReferenceLuminance()
  assert.ok(reference > model14)
  // [EN] A light glass tint stays above the floor: max(model, floor) is the model there. [CN] 浅色玻璃着色高于下限：此时 max(模型, 下限) 是模型值。
  assert.equal(cylAnimatedItemRenderedGlassReferenceLuminance('#FFFFFF', 1), cylAnimatedItemGlassReferenceLuminance('#FFFFFF', 1))
})

test('the floor, recomputed from the CSS: the three plate stops give a mean white share of about 0.353, the constant is that plus a small margin', () => {
  const clamp = (v) => Math.max(0, Math.min(255, v))
  const saturate = ([r, g, b], s) => [
    clamp((0.213 + 0.787 * s) * r + (0.715 - 0.715 * s) * g + (0.072 - 0.072 * s) * b),
    clamp((0.213 - 0.213 * s) * r + (0.715 + 0.285 * s) * g + (0.072 - 0.072 * s) * b),
    clamp((0.213 - 0.213 * s) * r + (0.715 - 0.715 * s) * g + (0.072 + 0.928 * s) * b),
  ]
  const shares = ['#5B2A3C', '#1F4A63', '#3B2D5C'].map((hex) => {
    const n = parseInt(hex.slice(1), 16)
    const filtered = saturate([n >> 16, (n >> 8) & 255, n & 255], 1.6).map((v) => clamp(v * 1.05))
    const interior = filtered.map((v) => 0.14 * 255 + 0.86 * v)
    return (0.299 * interior[0] + 0.587 * interior[1] + 0.114 * interior[2]) / 255
  })
  const mean = shares.reduce((a, b) => a + b, 0) / shares.length
  assert.ok(Math.abs(mean - 0.353) < 0.005, `mean ${mean}`)
  assert.ok(Math.abs(cylAnimatedItemRenderedDarkGlassWhiteShare - (mean + 0.02)) < 0.01)
})

test('a dark #3C3C43 title reaches 4.5 against the RENDERED reference after the lift (the model alone would stop short)', () => {
  const lifted = cylAnimatedItemContrastLift(DARK_TEXT, CYL_TITLE_MINIMUM_CONTRAST)
  assert.ok(renderedContrast(lifted) >= CYL_TITLE_MINIMUM_CONTRAST - 0.01, `${lifted} ${renderedContrast(lifted)}`)
  // [EN] Against the 0.14 model alone the unlifted color is judged below 4.5 too, but a color lifted only to the model would be dimmer than this one. [CN] 仅对照 0.14 的模型时未提亮的颜色同样低于 4.5，但只提亮到模型的颜色会比这个更暗。
  const against = (hex, reference) => (Math.max(luminance(hex), reference) + 0.05) / (Math.min(luminance(hex), reference) + 0.05)
  assert.ok(against(DARK_TEXT, cylAnimatedItemGlassReferenceLuminance()) < CYL_TITLE_MINIMUM_CONTRAST)
  assert.ok(luminance(lifted) > luminance('#8A8A96'))
  const icon = cylAnimatedItemContrastLift('#202020', CYL_ICON_MINIMUM_CONTRAST)
  assert.ok(renderedContrast(icon) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
})

// ---------------------------------------------------------------- drawsLiquidGlass / drawsFlatBackground

test('drawsLiquidGlass is glass requested AND active; drawsFlatBackground is the opposite (requested but not drawn counts as flat)', () => {
  assert.equal(cylAnimatedItemDrawsLiquidGlass(DARK_GLASS), true)
  assert.equal(cylAnimatedItemDrawsFlatBackground(DARK_GLASS), false)
  assert.equal(cylAnimatedItemDrawsLiquidGlass(DARK_FLAT), false)
  assert.equal(cylAnimatedItemDrawsFlatBackground(DARK_FLAT), true)
  assert.equal(cylAnimatedItemDrawsFlatBackground({}), true)
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.equal(cylAnimatedItemDrawsLiquidGlass(DARK_GLASS), false)
  assert.equal(cylAnimatedItemDrawsFlatBackground(DARK_GLASS), true)
})

// ---------------------------------------------------------------- precedence, per state

test('title precedence: own > subclass-explicit > stack-inherited > subclass built-in > component built-in (flat, so nothing is adapted)', () => {
  const base = { ...DARK_FLAT, builtInTitleColor: '#111111', inheritedTitleColor: '#222222', subclassTitleColor: '#333333', titleColor: '#444444' }
  assert.equal(cylAnimatedItemResolvedTitleColor(base), '#444444')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...base, titleColor: '' }), '#333333')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...base, titleColor: '', subclassTitleColor: '' }), '#222222')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...base, titleColor: '', subclassTitleColor: '', inheritedTitleColor: '' }), '#111111')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_FLAT }), 'rgb(255,255,255)')
  assert.equal(cylAnimatedItemResolvedTitleColor({ userInterfaceStyle: 'light' }), 'rgb(0,0,0)')
  // the dark variant of the own level wins while dark
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...base, titleDarkColor: '#555555' }), '#555555')
})

test('icon precedence: own > subclass-explicit > stack-inherited > subclass built-in > component built-in', () => {
  const base = { ...DARK_FLAT, builtInIconColor: '#111111', inheritedIconTint: '#222222', subclassIconColor: '#333333', iconTint: '#444444' }
  assert.equal(cylAnimatedItemResolvedIconColor(base), '#444444')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...base, iconTint: '' }), '#333333')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...base, iconTint: '', subclassIconColor: '' }), '#222222')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...base, iconTint: '', subclassIconColor: '', inheritedIconTint: '' }), '#111111')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...DARK_FLAT }), 'rgb(255,255,255)')
})

test('per-state channel: the selected value falls back to the normal one; disabled has its own and no fallback', () => {
  const title = { ...DARK_FLAT, subclassTitleColor: '#AA0000' }
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...title, selected: true }), '#AA0000')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...title, selected: true, subclassSelectedTitleColor: '#00AA00' }), '#00AA00')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...title, enabled: false }), 'rgba(140,140,140,0.35)')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...title, enabled: false, subclassDisabledTitleColor: '#0000AA' }), '#0000AA')
  const icon = { ...DARK_FLAT, subclassIconColor: '#AA0000' }
  assert.equal(cylAnimatedItemResolvedIconColor({ ...icon, selected: true }), '#AA0000')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...icon, selected: true, subclassSelectedIconColor: '#00AA00' }), '#00AA00')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...icon, enabled: false }), 'rgba(140,140,140,0.35)')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...icon, enabled: false, subclassDisabledIconColor: '#0000AA' }), '#0000AA')
  // built-in levels are per state too (no fallback): the selected built-in beats the component's systemBlue
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_FLAT, selected: true, builtInTitleColor: '#123456' }), 'rgb(0,145,255)')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_FLAT, selected: true, builtInSelectedTitleColor: '#123456' }), '#123456')
})

// ---------------------------------------------------------------- adaptation on drawn dark glass

test('subclass-explicit title and icon colors are adapted on drawn dark glass, never on light glass, flat or when glass is not drawn', () => {
  const props = { subclassTitleColor: DARK_TEXT, subclassIconColor: '#202020' }
  const lifted = cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, ...props })
  assert.notEqual(lifted, DARK_TEXT)
  assert.ok(renderedContrast(lifted) >= CYL_TITLE_MINIMUM_CONTRAST - 0.01)
  const liftedIcon = cylAnimatedItemResolvedIconColor({ ...DARK_GLASS, ...props })
  assert.ok(renderedContrast(liftedIcon) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...LIGHT_GLASS, ...props }), DARK_TEXT)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_FLAT, ...props }), DARK_TEXT)
  assert.equal(cylAnimatedItemResolvedIconColor({ ...DARK_FLAT, ...props }), '#202020')
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, ...props }), DARK_TEXT)
})

test('the explicit title through the model: the item keeps the public properties and draws the adapted color', () => {
  const props = { ...DARK_GLASS, subclassTitleColor: DARK_TEXT }
  const drawn = titleColorOf(props)
  assert.notEqual(drawn, DARK_TEXT)
  assert.ok(renderedContrast(drawn) >= CYL_TITLE_MINIMUM_CONTRAST - 0.01)
  assert.equal(props.subclassTitleColor, DARK_TEXT)
  assert.equal(props.titleColor, undefined)
  assert.equal(titleColorOf({ ...DARK_GLASS, titleColor: DARK_TEXT, subclassTitleColor: '#FFFFFF' }), cylAnimatedItemAdaptedColor(DARK_TEXT, CYL_ADAPTED_KIND_TITLE, DARK_GLASS))
})

test('both built-in levels, normal and selected, are adapted on drawn dark glass; the disabled look is not', () => {
  // subclass built-in
  assert.notEqual(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, builtInTitleColor: DARK_TEXT }), DARK_TEXT)
  assert.notEqual(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, selected: true, builtInSelectedTitleColor: DARK_TEXT }), DARK_TEXT)
  assert.notEqual(cylAnimatedItemResolvedIconColor({ ...DARK_GLASS, builtInIconColor: '#202020' }), '#202020')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_FLAT, builtInTitleColor: DARK_TEXT }), DARK_TEXT)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...LIGHT_GLASS, builtInTitleColor: DARK_TEXT }), DARK_TEXT)
  // disabled look: a subclass built-in and the component's own, as they are
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, enabled: false, builtInDisabledTitleColor: DARK_TEXT }), DARK_TEXT)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, enabled: false }), 'rgba(140,140,140,0.35)')
  assert.equal(cylAnimatedItemResolvedIconColor({ ...DARK_GLASS, enabled: false }), 'rgba(140,140,140,0.35)')
  // component built-in: the selected blue is lifted, the white label passes unchanged
  const selected = cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, selected: true, builtInSelectedColor: '#0A3D91' })
  assert.notEqual(selected, '#0A3D91')
  assert.ok(renderedContrast(selected) >= CYL_TITLE_MINIMUM_CONTRAST - 0.01)
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS }), 'rgb(255,255,255)')
  assert.equal(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, selected: true }) === 'rgb(0,145,255)', false)
  // an EXPLICIT disabled color counts as explicit: adapted
  assert.notEqual(cylAnimatedItemResolvedTitleColor({ ...DARK_GLASS, enabled: false, subclassDisabledTitleColor: DARK_TEXT }), DARK_TEXT)
})

test('the animation tint follows the same icon resolution: a subclass icon color and a built-in one are adapted on glass; a static image is tinted by explicit levels only', () => {
  const props = { ...DARK_GLASS, animationUrl: 'a.riv', animationTint: 'title', subclassIconColor: '#202020' }
  const tint = cylAnimatedItemModel(props).animationTint
  assert.notEqual(tint, '#202020')
  assert.ok(renderedContrast(tint) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
  assert.equal(cylAnimatedItemModel({ ...props, itemBackgroundStyle: 'flat' }).animationTint, '#202020')
  const built = cylAnimatedItemModel({ ...DARK_GLASS, animationUrl: 'a.riv', animationTint: 'title', builtInIconColor: '#202020' }).animationTint
  assert.notEqual(built, '#202020')
  // still image
  const still = cylAnimatedItemModel({ ...DARK_GLASS, image: 'a.png', subclassIconColor: '#202020', subclassSelectedIconColor: '#303030' })
  assert.ok(renderedContrast(still.still.normalTint) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
  assert.ok(renderedContrast(still.still.selectedTint) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
  const flat = cylAnimatedItemModel({ ...DARK_FLAT, image: 'a.png', subclassIconColor: '#202020', subclassSelectedIconColor: '#303030' })
  assert.equal(flat.still.normalTint, '#202020')
  assert.equal(flat.still.selectedTint, '#303030')
  assert.equal(cylAnimatedItemModel({ ...DARK_GLASS, image: 'a.png', builtInIconColor: '#202020' }).iconTint, '')
  // own selected missing: the normal one (own level) is used for the selected layer; a subclass level does not beat it
  const own = cylAnimatedItemModel({ ...DARK_FLAT, image: 'a.png', selectedImage: 'b.png', iconTint: '#112233', subclassSelectedIconColor: '#445566' })
  assert.equal(own.still.selectedTint, '#112233')
})

test('adaptedOnGlass kinds: icon 3, title 4.5 (title and text are the same kind)', () => {
  const a = cylAnimatedItemAdaptedColor(DARK_TEXT, CYL_ADAPTED_KIND_TITLE, DARK_GLASS)
  assert.equal(a, cylAnimatedItemAdaptedColor(DARK_TEXT, CYL_ADAPTED_KIND_TEXT, DARK_GLASS))
  assert.equal(CYL_ADAPTED_KIND_TITLE, 'title')
  assert.ok(renderedContrast(cylAnimatedItemAdaptedColor('#202020', CYL_ADAPTED_KIND_ICON, DARK_GLASS)) >= 3 - 0.01)
})

// ---------------------------------------------------------------- options, static helpers

test('options: defaults are off', () => {
  const definition = loadDefinition()
  const defaults = Object.fromEntries(Object.entries(definition.properties).map(([key, value]) => [key, value.value]))
  assert.equal(defaults.itemHighlightedBackgroundColor, '')
  assert.equal(defaults.itemDisabledAnimationAlpha, -1)
  assert.equal(defaults.showsLastFrameWhenSelected, false)
  assert.equal(defaults.disabledWinsImage, false)
  for (const key of ['subclassTitleColor', 'subclassSelectedTitleColor', 'subclassDisabledTitleColor', 'subclassIconColor', 'subclassSelectedIconColor', 'subclassDisabledIconColor',
    'builtInTitleColor', 'builtInSelectedTitleColor', 'builtInDisabledTitleColor', 'builtInIconColor', 'builtInSelectedIconColor', 'builtInDisabledIconColor']) {
    assert.equal(defaults[key], '', key)
  }
  // the model with the defaults: no animation style, the selected image on a selected disabled item
  const m = cylAnimatedItemModel({ ...defaults, image: 'a.png', selectedImage: 'b.png', selected: true, enabled: false })
  assert.equal(m.animationStyle, '')
  assert.equal(m.still.selectedHidden, false)
})

test('disabledWinsImage: selectedImage only when selected AND enabled', () => {
  const props = { image: 'a.png', selectedImage: 'b.png', selected: true, enabled: false, disabledWinsImage: true }
  const m = cylAnimatedItemModel(props)
  assert.equal(m.still.selectedHidden, true)
  assert.equal(m.still.normalHidden, false)
  assert.equal(cylAnimatedItemModel({ ...props, enabled: true }).still.selectedHidden, false)
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selectedImage: 'b.png', selected: true, enabled: false, disabledWinsImage: true }).fallbackImage, 'a.png')
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selectedImage: 'b.png', selected: true, enabled: false }).fallbackImage, 'b.png')
})

test('itemDisabledAnimationAlpha applies only while disabled', () => {
  assert.equal(cylAnimatedItemModel({ itemDisabledAnimationAlpha: 0.4, enabled: false }).animationStyle, 'opacity: 0.4;')
  assert.equal(cylAnimatedItemModel({ itemDisabledAnimationAlpha: 0.4, enabled: true }).animationStyle, '')
  assert.equal(cylAnimatedItemModel({ itemDisabledAnimationAlpha: -1, enabled: false }).animationStyle, '')
})

test('showsLastFrameWhenSelected: a selected host-driven item rests on the last frame only when on', () => {
  const props = { drivesAnimationPlayback: false, selected: true, hostRestingProgress: 0.2, animationUrl: 'a.pag' }
  assert.equal(cylAnimatedItemModel(props).restingFrame, 'first')
  assert.equal(cylAnimatedItemModel({ ...props, showsLastFrameWhenSelected: true }).restingFrame, 'last')
  assert.equal(model.cylAnimatedItemRestingProgress({ ...props, showsLastFrameWhenSelected: true }), 1)
})

test('static helpers: resolvedContentHorizontalInset and isAnimationEngineAvailable forward to what exists', () => {
  assert.equal(cylAnimatedItemResolvedContentHorizontalInset(-1, 'liquidGlass'), model.cylAnimatedItemLiquidGlassContentInset)
  assert.equal(cylAnimatedItemResolvedContentHorizontalInset(-1, 'flat'), 0)
  assert.equal(cylAnimatedItemResolvedContentHorizontalInset(6, 'liquidGlass'), 6)
  assert.equal(cylAnimatedItemResolvedContentHorizontalInset(0, 'liquidGlass'), 0)
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.equal(cylAnimatedItemResolvedContentHorizontalInset(-1, 'liquidGlass'), 0)
  assert.equal(cylAnimatedItemIsAnimationEngineAvailable('gif'), true)
  assert.equal(cylAnimatedItemIsAnimationEngineAvailable('lottie', []), true)
  assert.equal(cylAnimatedItemIsAnimationEngineAvailable('lottie', ['lottie']), false)
  assert.equal(cylAnimatedItemIsAnimationEngineAvailable('nope'), false)
})

// ---------------------------------------------------------------- the component (cylMount fake)

function loadDefinition() {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-animated-item/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  return definition
}

function cylMount(properties) {
  const definition = loadDefinition()
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  const observers = Object.entries(definition.observers).map(([keys, fn]) => ({ keys: keys.split(',').map((k) => k.trim()), fn }))
  const item = {
    data,
    setData(patch, callback) {
      Object.entries(patch).forEach(([key, value]) => {
        if (key.startsWith('m.')) this.data.m = { ...this.data.m, [key.slice(2)]: value }
        else this.data[key] = value
      })
      if (callback) callback()
    },
    selectComponent: () => null,
    events: [],
    triggerEvent(name, detail) { this.events.push([name, detail]) },
    set(patch) {
      this.setData(patch)
      observers.filter((o) => o.keys.some((k) => k in patch)).forEach((o) => o.fn.apply(this, o.keys.map((k) => this.data[k])))
    },
  }
  Object.assign(item, definition.methods)
  if (properties) item.set(properties)
  definition.lifetimes.attached.call(item)
  return item
}

test('component: the built-in title color is in the data of the FIRST render (attached, no later set)', () => {
  global.wx = { getAppBaseInfo: () => ({ theme: 'dark' }) }
  try {
    const item = cylMount()
    assert.match(item.data.m.titleStyle, /color: rgb\(255,255,255\);/)
    const selected = cylMount({ selected: true })
    assert.match(selected.data.m.titleStyle, /color: rgb\(0,145,255\);/)
  } finally {
    delete global.wx
  }
})

test('component: itemDrawsLiquidGlass / itemDrawsFlatBackground follow itemGlassDrawn; adaptedOnGlass uses the item state; public properties are untouched', () => {
  global.wx = { getAppBaseInfo: () => ({ theme: 'light' }) }
  try {
    const item = cylMount({ itemBackgroundStyle: 'liquidGlass', userInterfaceStyle: 'dark', subclassTitleColor: DARK_TEXT })
    assert.equal(item.data.itemDrawsLiquidGlass, true)
    assert.equal(item.data.itemDrawsFlatBackground, false)
    assert.equal(item.data.itemGlassDrawn, item.data.itemDrawsLiquidGlass)
    assert.equal(item.adaptedOnGlass(DARK_TEXT, 'title'), cylAnimatedItemAdaptedColor(DARK_TEXT, 'title', DARK_GLASS))
    assert.notEqual(item.adaptedOnGlass(DARK_TEXT, 'title'), DARK_TEXT)
    assert.notEqual(item.data.m.titleStyle.includes(DARK_TEXT), true)
    assert.equal(item.data.subclassTitleColor, DARK_TEXT)
    assert.equal(item.data.titleColor, '')
    // the glass changes: the colors follow (flat draws the color as set)
    item.set({ itemBackgroundStyle: 'flat' })
    assert.equal(item.data.itemDrawsLiquidGlass, false)
    assert.equal(item.data.itemDrawsFlatBackground, true)
    assert.match(item.data.m.titleStyle, new RegExp(`color: ${DARK_TEXT};`))
    assert.equal(item.adaptedOnGlass(DARK_TEXT, 'title'), DARK_TEXT)
  } finally {
    delete global.wx
  }
})

test('component: itemHighlightedBackgroundColor shows while pressed and enabled only (default off: no change)', () => {
  global.wx = { getAppBaseInfo: () => ({ theme: 'light' }) }
  try {
    const plain = cylMount()
    plain.cylOnTouchStart({ touches: [{ clientX: 0, clientY: 0 }] })
    assert.equal(plain.data.itemPressed, false)
    const item = cylMount({ itemHighlightedBackgroundColor: '#336699' })
    assert.equal(item.data.itemBackgroundCss.includes('#336699'), false)
    item.cylOnTouchStart({ touches: [{ clientX: 0, clientY: 0 }] })
    assert.ok(item.data.itemBackgroundCss.includes('background-color:#336699;'))
    item.cylOnTouchEnd({ changedTouches: [{ clientX: 0, clientY: 0 }] })
    assert.equal(item.data.itemBackgroundCss.includes('#336699'), false)
    item.cylOnTouchStart({ touches: [{ clientX: 0, clientY: 0 }] })
    item.cylOnTouchCancel()
    assert.equal(item.data.itemBackgroundCss.includes('#336699'), false)
    item.set({ enabled: false })
    item.cylOnTouchStart({ touches: [{ clientX: 0, clientY: 0 }] })
    assert.equal(item.data.itemBackgroundCss.includes('#336699'), false)
  } finally {
    delete global.wx
  }
})
