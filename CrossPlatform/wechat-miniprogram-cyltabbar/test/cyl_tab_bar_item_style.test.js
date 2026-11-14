/**
 * [EN] CYLTabBarItemStyle: the enum shared by cyl-tab-bar and cyl-tab-bar-item.
 * [CN] CYLTabBarItemStyle：cyl-tab-bar 与 cyl-tab-bar-item 共用的枚举。
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  CYLTabBarItemStyle, cylTabBarItemStyle, cylTabBarItemStyleForStyleType,
} = require('../src/cyl-tab-bar/cyl_tab_bar_item_style');
const configuration = require('../src/cyl-tab-bar/cyl_configuration');

test('CYLTabBarItemStyle: names, numbers, fallback, style types, export', () => {
  assert.deepEqual(Object.values(CYLTabBarItemStyle), ['flat', 'liquidGlass']);
  assert.ok(Object.isFrozen(CYLTabBarItemStyle));
  assert.equal(cylTabBarItemStyle('liquidGlass'), 'liquidGlass');
  assert.equal(cylTabBarItemStyle(1), 'liquidGlass');
  assert.equal(cylTabBarItemStyle(0), 'flat');
  assert.equal(cylTabBarItemStyle('glass'), 'flat');
  assert.equal(cylTabBarItemStyle(undefined), 'flat');
  assert.equal(cylTabBarItemStyleForStyleType('liquidGlass'), 'liquidGlass');
  ['default', 'system', 'flatDesign', undefined].forEach((styleType) => {
    assert.equal(cylTabBarItemStyleForStyleType(styleType), 'flat');
  });
  assert.equal(configuration.CYLTabBarItemStyle, CYLTabBarItemStyle);
});

test('CYLGlassLensStyle: names, numbers, fallback, export', () => {
  const { CYLGlassLensStyle, cylGlassLensStyle } = require('../src/cyl-tab-bar/cyl_tab_bar_item_style');
  assert.deepEqual(Object.values(CYLGlassLensStyle), ['regular', 'skeuomorphic']);
  assert.ok(Object.isFrozen(CYLGlassLensStyle));
  assert.equal(cylGlassLensStyle('skeuomorphic'), 'skeuomorphic');
  assert.equal(cylGlassLensStyle(1), 'skeuomorphic');
  assert.equal(cylGlassLensStyle(0), 'regular');
  ['', 'clear', undefined, null, 7].forEach((value) => {
    assert.equal(cylGlassLensStyle(value), 'regular');
  });
  assert.equal(configuration.CYLGlassLensStyle, CYLGlassLensStyle);
});
