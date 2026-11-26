'use strict'

// Colour contrast on dark Liquid Glass: explicit title / icon colours are lifted in the model; everything else is untouched.
const test = require('node:test')
const assert = require('node:assert/strict')
const {
  CYL_ICON_MINIMUM_CONTRAST,
  CYL_TITLE_MINIMUM_CONTRAST,
  cylAnimatedItemContrastLift,
  cylAnimatedItemGlassReferenceLuminance,
} = require('../src/cyl-animated-item/cyl_animated_item_contrast')
const { cylAnimatedItemModel, cylAnimatedItemLiquidGlassSetActiveOverride } = require('../src/cyl-animated-item/cyl_animated_item_model')

test.afterEach(() => cylAnimatedItemLiquidGlassSetActiveOverride(undefined))

const TOLERANCE = 0.01
const DARK_TEXT = '#3C3C43'
const lum = (hex) => {
  const n = parseInt(hex.slice(1, 7), 16)
  const ch = (v) => { const s = v / 255; return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4) }
  return 0.2126 * ch(Math.floor(n / 65536)) + 0.7152 * ch(Math.floor(n / 256) % 256) + 0.0722 * ch(n % 256)
}
const contrast = (hex, glass, alpha) => {
  const a = lum(hex); const b = cylAnimatedItemGlassReferenceLuminance(glass, alpha)
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
}
const hsl = (hex) => {
  const n = parseInt(hex.slice(1, 7), 16)
  const [r, g, b] = [Math.floor(n / 65536) / 255, (Math.floor(n / 256) % 256) / 255, (n % 256) / 255]
  const hi = Math.max(r, g, b); const lo = Math.min(r, g, b); const d = hi - lo
  let h = 0
  if (d > 0) h = hi === r ? ((g - b) / d + 6) % 6 : hi === g ? (b - r) / d + 2 : (r - g) / d + 4
  return { h: h / 6, l: (hi + lo) / 2 }
}
const GLASS = { itemBackgroundStyle: 'liquidGlass', userInterfaceStyle: 'dark', title: 'T', image: 'a.png' }

test('dark text on the default dark glass becomes lighter and passes 4.5', () => {
  assert.ok(contrast(DARK_TEXT) < CYL_TITLE_MINIMUM_CONTRAST)
  const lifted = cylAnimatedItemContrastLift(DARK_TEXT, CYL_TITLE_MINIMUM_CONTRAST)
  assert.notEqual(lifted, DARK_TEXT)
  assert.ok(contrast(lifted) >= CYL_TITLE_MINIMUM_CONTRAST - TOLERANCE)
  assert.ok(hsl(lifted).l > hsl(DARK_TEXT).l)
  assert.ok(Math.abs(hsl(lifted).h - hsl(DARK_TEXT).h) < 0.01)
})

test('an icon tint is judged at 3, a lighter colour that already passes is unchanged, white stays white', () => {
  const icon = cylAnimatedItemContrastLift('#202020', CYL_ICON_MINIMUM_CONTRAST)
  assert.ok(contrast(icon) >= CYL_ICON_MINIMUM_CONTRAST - TOLERANCE)
  assert.equal(cylAnimatedItemContrastLift('#E0E0E0', CYL_TITLE_MINIMUM_CONTRAST), '#E0E0E0')
  assert.equal(cylAnimatedItemContrastLift('#FFFFFF', CYL_TITLE_MINIMUM_CONTRAST), '#FFFFFF')
})

test('alpha is kept; rgb() and #RRGGBBAA forms keep their form', () => {
  assert.match(cylAnimatedItemContrastLift('#3C3C43CC', 4.5), /^#[0-9A-F]{6}CC$/)
  assert.match(cylAnimatedItemContrastLift('rgba(60,60,67,0.5)', 4.5), /^rgba\(\d+, \d+, \d+, 0\.5\)$/)
  assert.match(cylAnimatedItemContrastLift('rgb(60,60,67)', 4.5), /^rgb\(\d+, \d+, \d+\)$/)
})

test('an explicit glass tint is the reference (colour x alpha x tintAlpha)', () => {
  const tint = '#FFFFFF'
  assert.ok(cylAnimatedItemGlassReferenceLuminance(tint, 1) > cylAnimatedItemGlassReferenceLuminance(tint, -1))
  assert.equal(cylAnimatedItemGlassReferenceLuminance('', undefined), cylAnimatedItemGlassReferenceLuminance('#00000000', 0.5))
  const lifted = cylAnimatedItemContrastLift('#808080', 4.5, tint, 1)
  assert.ok(contrast(lifted, tint, 1) >= 4.5 - TOLERANCE || lifted === '#FFFFFF')
})

test('unparseable colours are returned as they are; the function is deterministic', () => {
  for (const c of ['red', 'var(--x)', '#abc', '', 'hsl(0,0%,10%)']) assert.equal(cylAnimatedItemContrastLift(c, 4.5), c)
  assert.equal(cylAnimatedItemContrastLift(DARK_TEXT, 4.5), cylAnimatedItemContrastLift(DARK_TEXT, 4.5))
})

test('the model lifts an explicit title colour and icon tint on dark drawn glass', () => {
  const m = cylAnimatedItemModel({ ...GLASS, titleColor: DARK_TEXT, iconTint: '#202020', selectedIconTint: '#303030' })
  assert.doesNotMatch(m.titleStyle, /#3C3C43/i)
  const title = /color: (#[0-9A-F]{6});/i.exec(m.titleStyle)[1]
  assert.ok(contrast(title) >= 4.5 - TOLERANCE)
  assert.ok(contrast(m.iconTint) >= 3 - TOLERANCE)
  assert.ok(contrast(m.still.selectedTint) >= 3 - TOLERANCE)
  const dark = cylAnimatedItemModel({ ...GLASS, userInterfaceStyle: 'system', systemTheme: 'dark', titleColor: DARK_TEXT })
  assert.doesNotMatch(dark.titleStyle, /#3C3C43/i)
})

test('the model lifts titleDarkColor and the animation tint, not a built-in colour', () => {
  const m = cylAnimatedItemModel({ ...GLASS, titleDarkColor: DARK_TEXT, animationTint: '#202020', animationType: 'rive' })
  assert.doesNotMatch(m.titleStyle, /#3C3C43/i)
  assert.ok(contrast(m.animationTint) >= 3 - TOLERANCE)
  const title = cylAnimatedItemModel({ ...GLASS, iconTint: '#202020', animationTint: 'title', animationType: 'rive' })
  assert.equal(title.animationTint, title.iconTint)
  const builtIn = cylAnimatedItemModel({ ...GLASS, animationTint: 'title', animationType: 'rive' })
  assert.equal(builtIn.animationTint, 'rgb(255,255,255)')
  assert.match(builtIn.titleStyle, /rgb\(255,255,255\)/)
})

test('unset, flat, light and inactive glass are unchanged', () => {
  const base = { title: 'T', image: 'a.png', titleColor: DARK_TEXT, iconTint: '#202020' }
  const same = (input) => { const m = cylAnimatedItemModel(input); assert.match(m.titleStyle, /#3C3C43/i); assert.equal(m.iconTint, '#202020') }
  same({ ...base, userInterfaceStyle: 'dark', itemBackgroundStyle: 'flat' })
  same({ ...base, userInterfaceStyle: 'dark' })
  same({ ...base, userInterfaceStyle: 'light', itemBackgroundStyle: 'liquidGlass' })
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  same({ ...base, userInterfaceStyle: 'dark', itemBackgroundStyle: 'liquidGlass' })
  cylAnimatedItemLiquidGlassSetActiveOverride(undefined)
  const unset = cylAnimatedItemModel({ ...GLASS })
  assert.equal(unset.iconTint, '')
  assert.doesNotMatch(unset.titleStyle, /#3C3C43/i)
})
