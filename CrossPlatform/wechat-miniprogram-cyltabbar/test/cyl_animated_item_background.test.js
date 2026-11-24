'use strict'

// The background of cyl-animated-item (flat, Liquid Glass, corner radius, border): the same names as iOS CYLAnimatedItemView.
const test = require('node:test')
const assert = require('node:assert/strict')
const {
  cylAnimatedItemBackground,
  cylAnimatedItemCornerRadiusCapsule,
  cylAnimatedItemLiquidGlassContentInset,
  cylAnimatedItemLiquidGlassIsActive,
  cylAnimatedItemLiquidGlassSetActiveOverride,
} = require('../src/cyl-animated-item/cyl_animated_item_model')

test.afterEach(() => cylAnimatedItemLiquidGlassSetActiveOverride(undefined))

test('nothing is drawn until an item… background property is set', () => {
  assert.deepEqual(cylAnimatedItemBackground('flat', '', -1, 0, '', false), { css: '', glass: false })
})

test('flat: the solid color, the radius and the border', () => {
  const background = cylAnimatedItemBackground('flat', '#336699', 1000, 1, '#FF0000', false)
  assert.equal(background.glass, false)
  assert.match(background.css, /border-radius:1000px;/)
  assert.match(background.css, /border:1px solid #FF0000;/)
  assert.match(background.css, /background-color:#336699;/)
  assert.doesNotMatch(background.css, /backdrop-filter/)
})

test('liquidGlass: backdrop-filter over the tint where the rule is active, flat where it is not', () => {
  const glass = cylAnimatedItemBackground('liquidGlass', 'rgba(255,136,0,0.4)', 12, 0, '', false)
  assert.equal(glass.glass, true)
  assert.match(glass.css, /backdrop-filter:blur\(16px\) saturate\(180%\)/)
  assert.match(glass.css, /background-color:rgba\(255,136,0,0.3\);/, 'the glass tint is translucent: alpha x 0.75')
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.equal(cylAnimatedItemLiquidGlassIsActive(), false)
  const flat = cylAnimatedItemBackground('liquidGlass', 'rgba(255,136,0,0.4)', 12, 0, '', false)
  assert.equal(flat.glass, false)
  assert.doesNotMatch(flat.css, /backdrop-filter/)
  assert.match(flat.css, /background-color:rgba\(255,136,0,0.4\);/)
})

test('a radius below zero is square and the glass has a default tint', () => {
  assert.match(cylAnimatedItemBackground('flat', '#fff', 0, 0, '', false).css, /border-radius:0px;/)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', 8, 0, '', false).css, /background-color:rgba\(225,222,220,0.5\);/)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', 8, 0, '', true).css, /background-color:rgba\(255,255,255,0.14\);/)
})

test('an unset radius (-1) is a capsule for the drawn glass and square for flat; a set radius wins', () => {
  cylAnimatedItemLiquidGlassSetActiveOverride(true)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', -1, 0, '', false).css, /border-radius:1000px;/)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', 8, 0, '', false).css, /border-radius:8px;/)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', 0, 0, '', false).css, /border-radius:0px;/)
  assert.match(cylAnimatedItemBackground('flat', '#fff', -1, 0, '', false).css, /border-radius:0px;/)
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.match(cylAnimatedItemBackground('liquidGlass', '', -1, 0, '', false).css, /border-radius:0px;/)
})

test('a glass tint is translucent: alpha x 0.75 for hex and rgb colors, other text as it is', () => {
  const { cylAnimatedItemGlassTint } = require('../src/cyl-animated-item/cyl_animated_item_model')
  assert.equal(cylAnimatedItemGlassTint('#2AB9A0'), 'rgba(42,185,160,0.75)')
  assert.equal(cylAnimatedItemGlassTint('#FFF'), 'rgba(255,255,255,0.75)')
  assert.equal(cylAnimatedItemGlassTint('rgba(0, 0, 0, 0.4)'), 'rgba(0,0,0,0.3)')
  assert.equal(cylAnimatedItemGlassTint('rgb(64, 64, 64)'), 'rgba(64,64,64,0.75)')
  assert.equal(cylAnimatedItemGlassTint('currentColor'), 'currentColor', 'other color text is used as it is')
  cylAnimatedItemLiquidGlassSetActiveOverride(true)
  assert.match(cylAnimatedItemBackground('liquidGlass', '#2AB9A0', 8, 0, '', false).css, /background-color:rgba\(42,185,160,0.75\);backdrop-filter/)
})

test('a fully transparent color means no color: the glass gets the default frosted tint', () => {
  const { cylAnimatedItemGlassTint } = require('../src/cyl-animated-item/cyl_animated_item_model')
  assert.equal(cylAnimatedItemGlassTint('rgba(0,0,0,0)'), '')
  assert.equal(cylAnimatedItemGlassTint('transparent'), '')
  assert.equal(cylAnimatedItemGlassTint('#00FF0000'), '')
  cylAnimatedItemLiquidGlassSetActiveOverride(true)
  for (const clear of ['transparent', 'rgba(0,0,0,0)', '']) {
    assert.match(cylAnimatedItemBackground('liquidGlass', clear, -1, 0, '', false).css, /background-color:rgba\(225,222,220,0.5\);backdrop-filter/, `"${clear}": the default tint`)
  }
  assert.match(cylAnimatedItemBackground('liquidGlass', 'transparent', -1, 0, '', true).css, /background-color:rgba\(255,255,255,0.14\);/)
})

test('itemContentHorizontalInset: unset is the glass constant on drawn glass and 0 on flat; an explicit value wins (the partner of the unset radius)', () => {
  const inset = (css) => (css.match(/--cyl-item-inset:([0-9.]+)px;/) || [])[1]
  const glass = cylAnimatedItemBackground('liquidGlass', '', -1, 0, '', false)
  assert.equal(inset(glass.css), String(cylAnimatedItemLiquidGlassContentInset), 'unset on glass: the named constant')
  assert.equal(inset(cylAnimatedItemBackground('flat', '#fff', -1, 0, '', false).css), undefined, 'unset on flat: 0, nothing added')
  assert.equal(inset(cylAnimatedItemBackground('liquidGlass', '', -1, 0, '', false, 0).css), undefined, 'explicit 0 on glass stays 0')
  assert.equal(inset(cylAnimatedItemBackground('flat', '#fff', -1, 0, '', false, 20).css), '20', 'explicit 20 on flat')
  assert.equal(inset(cylAnimatedItemBackground('flat', '', -1, 0, '', false, 20).css), '20', 'an explicit inset alone also draws')
  cylAnimatedItemLiquidGlassSetActiveOverride(false)
  assert.equal(inset(cylAnimatedItemBackground('liquidGlass', '', -1, 0, '', false).css), undefined, 'glass the device does not draw: 0 like the unset radius')
})
