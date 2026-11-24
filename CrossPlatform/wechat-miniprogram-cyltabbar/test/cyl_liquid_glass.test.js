'use strict';

// cyl-liquid-glass: the availability rule and the inline style of the glass (the same names as iOS CYLLiquidGlass /
// CYLLiquidGlassView).
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  cylLiquidGlassIsActive,
  cylLiquidGlassSetActiveOverride,
  cylLiquidGlassStyle,
} = require('../src/cyl-liquid-glass/cyl_liquid_glass');

test('the glass is active in a mini program, and the override replaces the rule', () => {
  cylLiquidGlassSetActiveOverride(undefined);
  assert.equal(cylLiquidGlassIsActive(), true);
  cylLiquidGlassSetActiveOverride(false);
  assert.equal(cylLiquidGlassIsActive(), false);
  cylLiquidGlassSetActiveOverride(true);
  assert.equal(cylLiquidGlassIsActive(), true);
  cylLiquidGlassSetActiveOverride(undefined);
  assert.equal(cylLiquidGlassIsActive(), true);
});

test('the inline style carries the corner radius and, when given, the tint', () => {
  assert.equal(cylLiquidGlassStyle('', 12), 'border-radius:12px;');
  assert.equal(cylLiquidGlassStyle('rgba(255,136,0,0.4)', 12), 'border-radius:12px;background-color:rgba(255,136,0,0.4);');
  assert.equal(cylLiquidGlassStyle(undefined, -3), 'border-radius:0px;');
  assert.equal(cylLiquidGlassStyle('#FF8800', '8'), 'border-radius:8px;background-color:#FF8800;');
});
