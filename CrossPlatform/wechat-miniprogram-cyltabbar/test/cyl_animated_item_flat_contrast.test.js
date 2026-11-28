'use strict'

// The flat-fill contrast rule (iOS `contrastApplies` / `flatReferenceLuminance`, Android `CYLAnimatedItemFlatContrastTest`, HarmonyOS
// `CYLAnimatedItemFlatContrast.test.ets`): in dark mode an item that draws a flat fill lifts its colours against the fill over black; flat without a fill,
// light mode and a fixed animation tint on flat are not adapted; a light fill never turns a colour whiter.
const test = require('node:test')
const assert = require('node:assert/strict')
const {
  CYL_TITLE_MINIMUM_CONTRAST,
  CYL_ICON_MINIMUM_CONTRAST,
  cylAnimatedItemFlatReferenceLuminance,
  cylAnimatedItemContrastLiftToReference,
} = require('../src/cyl-animated-item/cyl_animated_item_contrast')
const {
  cylAnimatedItemAdaptedColor, cylAnimatedItemFlatFill, cylAnimatedItemLiquidGlassSetActiveOverride, CYL_ADAPTED_KIND_ICON, CYL_ADAPTED_KIND_TEXT,
} = require('../src/cyl-animated-item/cyl_animated_item_model')

test.afterEach(() => cylAnimatedItemLiquidGlassSetActiveOverride(undefined))

const GREY = '#3C3C43'
const DARK_FILL = '#1C1C1E'
const lum = (hex) => {
  const n = parseInt(hex.slice(1, 7), 16)
  const ch = (v) => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4) }
  return 0.2126 * ch(Math.floor(n / 65536)) + 0.7152 * ch(Math.floor(n / 256) % 256) + 0.0722 * ch(n % 256)
}
const contrastOn = (hex, fill) => {
  const a = lum(hex); const b = cylAnimatedItemFlatReferenceLuminance(fill)
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
}
const DARK_FLAT = { itemBackgroundStyle: 'flat', userInterfaceStyle: 'dark' }

test('the flat reference is the fill over black; clear and unparseable fills have none', () => {
  assert.ok(Math.abs(cylAnimatedItemFlatReferenceLuminance(DARK_FILL) - lum(DARK_FILL)) < 1e-9)
  assert.ok(Math.abs(cylAnimatedItemFlatReferenceLuminance('#FFFFFF80') - 0.216) < 0.003)
  assert.equal(cylAnimatedItemFlatReferenceLuminance('#FFFFFF00'), null)
  assert.equal(cylAnimatedItemFlatReferenceLuminance(''), null)
  assert.equal(cylAnimatedItemFlatReferenceLuminance('var(--x)'), null)
})

test('a dark title on the dark flat fill reaches 4.5 in dark mode only', () => {
  assert.ok(contrastOn(GREY, DARK_FILL) < 2)
  const lifted = cylAnimatedItemAdaptedColor(GREY, CYL_ADAPTED_KIND_TEXT, { ...DARK_FLAT, itemBackgroundColor: DARK_FILL })
  assert.ok(contrastOn(lifted, DARK_FILL) >= CYL_TITLE_MINIMUM_CONTRAST - 0.01)
  assert.equal(cylAnimatedItemAdaptedColor(GREY, CYL_ADAPTED_KIND_TEXT, { ...DARK_FLAT, userInterfaceStyle: 'light', itemBackgroundColor: DARK_FILL }), GREY)
})

test('flat without a fill or with a clear fill is not adapted', () => {
  assert.equal(cylAnimatedItemAdaptedColor(GREY, CYL_ADAPTED_KIND_TEXT, DARK_FLAT), GREY)
  assert.equal(cylAnimatedItemAdaptedColor(GREY, CYL_ADAPTED_KIND_TEXT, { ...DARK_FLAT, itemBackgroundColor: '#00000000' }), GREY)
})

test('an icon is lifted to 3 on the fill', () => {
  const icon = cylAnimatedItemAdaptedColor(GREY, CYL_ADAPTED_KIND_ICON, { ...DARK_FLAT, itemBackgroundColor: DARK_FILL })
  assert.ok(contrastOn(icon, DARK_FILL) >= CYL_ICON_MINIMUM_CONTRAST - 0.01)
})

test('a light fill never turns a mid-grey title white', () => {
  const white = cylAnimatedItemFlatReferenceLuminance('#FFFFFF')
  assert.equal(cylAnimatedItemContrastLiftToReference('#8E8E93', CYL_TITLE_MINIMUM_CONTRAST, white), '#8E8E93')
  assert.equal(cylAnimatedItemAdaptedColor('#8E8E93', CYL_ADAPTED_KIND_TEXT, { ...DARK_FLAT, itemBackgroundColor: '#FFFFFF' }), '#8E8E93')
})

test('the flat fill: the pressed colour while pressed and enabled, the countdown fill, else the background; none on drawn glass', () => {
  assert.equal(cylAnimatedItemFlatFill({ ...DARK_FLAT, itemBackgroundColor: '#123456' }), '#123456')
  assert.equal(cylAnimatedItemFlatFill({ ...DARK_FLAT, itemBackgroundColor: '#123456', itemHighlightedBackgroundColor: DARK_FILL, itemPressed: true }), DARK_FILL)
  assert.equal(cylAnimatedItemFlatFill({ ...DARK_FLAT, itemBackgroundColor: '#123456', itemHighlightedBackgroundColor: DARK_FILL, itemPressed: true, enabled: false }), '#123456')
  assert.equal(cylAnimatedItemFlatFill({ ...DARK_FLAT, itemStyle: 'countdown' }), '#F2F2F7')
  cylAnimatedItemLiquidGlassSetActiveOverride(true)
  assert.equal(cylAnimatedItemFlatFill({ ...DARK_FLAT, itemBackgroundStyle: 'liquidGlass', itemBackgroundColor: DARK_FILL }), '')
})
