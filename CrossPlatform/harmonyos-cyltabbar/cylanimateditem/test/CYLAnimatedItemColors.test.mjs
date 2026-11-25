// [EN] Unit tests of CYLAnimatedItemColors.ts: hex colors to components and to Rive's ARGB integer.
//      Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemColors.ts 的单元测试。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const C = await import('../src/main/ets/CYLAnimatedItemColors.ts');

test('hex colors with and without alpha, with and without #', () => {
  assert.deepEqual({ ...C.cylAnimatedItemParseHexColor('#FF8000') }, { red: 255, green: 128, blue: 0, alpha: 255 });
  assert.deepEqual({ ...C.cylAnimatedItemParseHexColor('80ff8000') }, { red: 255, green: 128, blue: 0, alpha: 128 });
  assert.equal(C.cylAnimatedItemParseHexColor('red'), undefined);
  assert.equal(C.cylAnimatedItemParseHexColor('#FFF'), undefined);
});

test('ARGB integers as Rive color properties take them', () => {
  assert.equal(C.cylAnimatedItemARGBInteger(C.cylAnimatedItemParseHexColor('#FF0000')), 0xFFFF0000 | 0);
  assert.equal(C.cylAnimatedItemARGBInteger(C.cylAnimatedItemParseHexColor('#00000000')), 0);
  assert.equal(C.cylAnimatedItemARGBInteger(C.cylAnimatedItemParseHexColor('#7F00FF00')), 0x7F00FF00);
});

test('a glass tint: alpha x 0.75; alpha 0 (clear) is the default frosted tint, as an unset color', () => {
  const DEFAULT = '#80E1DEDC';
  assert.equal(C.cylAnimatedItemGlassTintColor('#2AB9A0', 0.75, DEFAULT), 0xBF2AB9A0);
  assert.equal(C.cylAnimatedItemGlassTintColor('#80FF0000', 0.75, DEFAULT), 0x60FF0000);
  assert.equal(C.cylAnimatedItemGlassTintColor(0xFF336699, 0.75, DEFAULT), 0xBF336699);
  for (const clear of ['#00000000', '#00FFFFFF', 'transparent', 'Transparent', 0, 0x00123456]) {
    assert.equal(C.cylAnimatedItemGlassTintColor(clear, 0.75, DEFAULT), DEFAULT, String(clear));
  }
  assert.equal(C.cylAnimatedItemGlassTintColor('red', 0.75, DEFAULT), undefined, 'other text is used as it is');
});

test('tint colors: #RRGGBB / #RRGGBBAA to ArkUI #AARRGGBB', () => {
  assert.equal(C.cylAnimatedItemTintArkColor('#FF8000'), '#FFFF8000');
  assert.equal(C.cylAnimatedItemTintArkColor('ff800080'), '#80FF8000');
  assert.equal(C.cylAnimatedItemTintArkColor('title'), undefined);
  assert.equal(C.cylAnimatedItemTintArkColor(''), undefined);
  assert.equal(C.cylAnimatedItemTintArkColor('#FFF'), undefined);
});

function resolve(fields) {
  return { ...C.cylAnimatedItemResolveTint({ ...new C.CYLAnimatedItemTintInput(), ...fields }) };
}

test('tint resolution: nothing set changes nothing', () => {
  assert.deepEqual(resolve({ hasIconColor: true, selected: true, dark: true }), { kind: 'none', color: '' });
});

test('tint "title" is the icon color, none without one, ignores the dark tint', () => {
  assert.deepEqual(resolve({ propTint: 'title', hasIconColor: true }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ propTint: 'title', hasIconColor: true, selected: true, dark: true, propDarkTint: '#FFFFFF' }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ propTint: 'title' }), { kind: 'none', color: '' });
});

test('a fixed tint: unselected uses it (dark: the dark tint), selected takes the icon color', () => {
  assert.deepEqual(resolve({ propTint: '#1C1C1E', propDarkTint: '#F2F2F7', hasIconColor: true }), { kind: 'fixed', color: '#FF1C1C1E' });
  assert.deepEqual(resolve({ propTint: '#1C1C1E', propDarkTint: '#F2F2F7', dark: true }), { kind: 'fixed', color: '#FFF2F2F7' });
  assert.deepEqual(resolve({ propTint: '#1C1C1E', propDarkTint: '#F2F2F7', dark: true, selected: true, hasIconColor: true }), { kind: 'icon', color: '' });
  // [EN] Selected without an icon color: nothing to take, the fixed color. [CN] 选中但没有图标颜色：用固定颜色。
  assert.deepEqual(resolve({ propTint: '#1C1C1E', selected: true }), { kind: 'fixed', color: '#FF1C1C1E' });
  // [EN] Dark without a valid dark tint: the light one. [CN] 深色模式没有有效的深色值：用浅色值。
  assert.deepEqual(resolve({ propTint: '#1C1C1E', dark: true, propDarkTint: 'oops' }), { kind: 'fixed', color: '#FF1C1C1E' });
  assert.deepEqual(resolve({ propTint: '#1C1C1E80' }), { kind: 'fixed', color: '#801C1C1E' });
});

test('a set property overrides the same source option, each on its own; unset uses the option', () => {
  assert.deepEqual(resolve({ optionTint: '#111111', optionDarkTint: '#EEEEEE', dark: true }), { kind: 'fixed', color: '#FFEEEEEE' });
  assert.deepEqual(resolve({ optionTint: '#111111', propTint: '#222222' }), { kind: 'fixed', color: '#FF222222' });
  assert.deepEqual(resolve({ optionTint: '#111111', optionDarkTint: '#EEEEEE', propDarkTint: '#DDDDDD', dark: true }), { kind: 'fixed', color: '#FFDDDDDD' });
  assert.deepEqual(resolve({ optionTint: '#111111', propTint: 'title', hasIconColor: true }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ optionTint: 'title', hasIconColor: true, selected: true }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ propTint: 'bogus', optionTint: '#111111' }), { kind: 'none', color: '' });
});
