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
  assert.equal(C.cylAnimatedItemTintArkColor('#ff800080'), '#80FF8000');
  assert.equal(C.cylAnimatedItemTintArkColor('ff800080'), undefined, 'a tint hex needs its #, as on every platform');
  assert.equal(C.cylAnimatedItemTintArkColor('FF8000'), undefined);
  assert.equal(C.cylAnimatedItemTintArkColor('title'), undefined);
  assert.equal(C.cylAnimatedItemTintArkColor(''), undefined);
  assert.equal(C.cylAnimatedItemTintArkColor('#FFF'), undefined);
});

function resolve(fields) {
  return { ...C.cylAnimatedItemResolveTint({ ...new C.CYLAnimatedItemTintInput(), ...fields }) };
}

// [EN] The shared truth table (/tmp/xpr/tint-table-v2.txt; identical on iOS, Android, HarmonyOS and the mini program), one row per
//      combination: the tint kind (unset / "title" / fixed / invalid), the state, whether an EXPLICIT selected icon color exists, dark mode.
//      Expected: 'none' | 'icon' (the view draws in its EFFECTIVE current-state icon color) | the fixed "#AARRGGBB".
// [CN] 共用真值表（着色规范 v2）：每种组合一行：着色种类、状态、是否存在显式选中图标颜色、深色模式。
const FIXED = '#1C1C1E';
const FIXED_ARK = '#FF1C1C1E';
const DARK = '#F2F2F7';
const DARK_ARK = '#FFF2F2F7';
const TABLE = [];
for (const selected of [false, true]) {
  for (const hasSelectedIconColor of [false, true]) {
    for (const dark of [false, true]) {
      const base = { selected, hasSelectedIconColor, dark, propDarkTint: DARK, renderingMode: 'automatic', colorKind: 'unknown' };
      // unset, and invalid text = unset: the file's own colors (automatic, undetected)
      TABLE.push([{ ...base, propDarkTint: '' }, 'none']);
      TABLE.push([{ ...base, propTint: 'bogus' }, 'none']);
      TABLE.push([{ ...base, propTint: '#FFF' }, 'none']);
      // "title": always the effective icon color (explicit, stack or built-in always exists)
      TABLE.push([{ ...base, propTint: 'title' }, 'icon']);
      // fixed: selected with an EXPLICIT selected icon color = icon; else the fixed color (the dark one in dark mode), also when selected
      //        with only the built-in selected color (the "fixed tint does not turn blue when selected" row)
      const fixed = selected && hasSelectedIconColor ? 'icon' : (dark ? DARK_ARK : FIXED_ARK);
      TABLE.push([{ ...base, propTint: FIXED }, fixed]);
    }
  }
}

test('tint resolution table: state x tint kind x explicit selected color x dark', () => {
  for (const [fields, expected] of TABLE) {
    const result = resolve(fields);
    const label = JSON.stringify(fields);
    if (expected === 'none' || expected === 'icon') {
      assert.deepEqual(result, { kind: expected, color: '' }, label);
    } else {
      assert.deepEqual(result, { kind: 'fixed', color: expected }, label);
    }
  }
  assert.equal(TABLE.length, 8 * 5);
});

test('a fixed tint on a SELECTED item yields only to an EXPLICIT selected icon color, never to the built-in selected color', () => {
  assert.deepEqual(resolve({ propTint: FIXED, selected: true, hasSelectedIconColor: false }), { kind: 'fixed', color: FIXED_ARK });
  assert.deepEqual(resolve({ propTint: FIXED, selected: true, hasSelectedIconColor: true }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ propTint: FIXED, selected: false, hasSelectedIconColor: true }), { kind: 'fixed', color: FIXED_ARK });
});

// [EN] Rendering mode (tint spec v2, section 4), only while no tint is set: mode x detection.
// [CN] 渲染模式（仅在未设置着色时）：模式 x 检测结果。
const MODE_TABLE = [
  ['automatic', 'oneColor', 'icon'], ['automatic', 'multiColor', 'none'], ['automatic', 'unknown', 'none'],
  ['alwaysTemplate', 'oneColor', 'icon'], ['alwaysTemplate', 'multiColor', 'icon'], ['alwaysTemplate', 'unknown', 'icon'],
  ['alwaysOriginal', 'oneColor', 'none'], ['alwaysOriginal', 'multiColor', 'none'], ['alwaysOriginal', 'unknown', 'none'],
  ['bogus', 'oneColor', 'icon'], ['', 'multiColor', 'none']
];
for (const [renderingMode, colorKind, expected] of MODE_TABLE) {
  test(`rendering mode ${renderingMode || '(empty)'} x ${colorKind} with no tint = ${expected}`, () => {
    assert.deepEqual(resolve({ renderingMode, colorKind }), { kind: expected, color: '' });
  });
}

test('an explicit tint always wins over the rendering mode', () => {
  for (const mode of ['automatic', 'alwaysTemplate', 'alwaysOriginal']) {
    for (const kind of ['oneColor', 'multiColor', 'unknown']) {
      assert.deepEqual(resolve({ propTint: FIXED, renderingMode: mode, colorKind: kind }), { kind: 'fixed', color: FIXED_ARK }, `${mode} ${kind}`);
      assert.deepEqual(resolve({ propTint: 'title', renderingMode: mode, colorKind: kind }), { kind: 'icon', color: '' }, `${mode} ${kind}`);
      assert.deepEqual(resolve({ optionTint: FIXED, renderingMode: mode, colorKind: kind }), { kind: 'fixed', color: FIXED_ARK }, `${mode} ${kind}`);
    }
  }
});

test('effective rendering mode: item (not automatic) > URL option > stack > automatic', () => {
  const E = C.cylAnimatedItemEffectiveRenderingMode;
  assert.equal(E('automatic', '', ''), 'automatic');
  assert.equal(E('', '', ''), 'automatic');
  assert.equal(E('alwaysOriginal', 'alwaysTemplate', 'alwaysTemplate'), 'alwaysOriginal');
  assert.equal(E('automatic', 'alwaysTemplate', 'alwaysOriginal'), 'alwaysTemplate');
  assert.equal(E('automatic', '', 'alwaysOriginal'), 'alwaysOriginal');
  assert.equal(E('automatic', 'bogus', 'alwaysTemplate'), 'alwaysTemplate');
  assert.equal(E('ALWAYSTEMPLATE', '', ''), 'alwaysTemplate');
});

test('a fixed tint without a valid dark tint: dark mode keeps the fixed color; 8-digit hex is #RRGGBBAA', () => {
  assert.deepEqual(resolve({ propTint: FIXED, dark: true }), { kind: 'fixed', color: FIXED_ARK });
  assert.deepEqual(resolve({ propTint: FIXED, dark: true, propDarkTint: 'oops' }), { kind: 'fixed', color: FIXED_ARK });
  assert.deepEqual(resolve({ propTint: '#1C1C1E80' }), { kind: 'fixed', color: '#801C1C1E' });
  assert.deepEqual(resolve({ propTint: '#FF000080', dark: true, propDarkTint: '#00FF0040' }), { kind: 'fixed', color: '#4000FF00' });
});

test('"title" ignores the dark tint', () => {
  assert.deepEqual(resolve({ propTint: 'title', dark: true, propDarkTint: '#FFFFFF' }), { kind: 'icon', color: '' });
});

test('a set property overrides the same source option, each on its own; unset uses the option', () => {
  assert.deepEqual(resolve({ optionTint: '#111111', optionDarkTint: '#EEEEEE', dark: true }), { kind: 'fixed', color: '#FFEEEEEE' });
  assert.deepEqual(resolve({ optionTint: '#111111', propTint: '#222222' }), { kind: 'fixed', color: '#FF222222' });
  assert.deepEqual(resolve({ optionTint: '#111111', optionDarkTint: '#EEEEEE', propDarkTint: '#DDDDDD', dark: true }), { kind: 'fixed', color: '#FFDDDDDD' });
  assert.deepEqual(resolve({ optionTint: '#111111', propTint: 'title' }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ optionTint: 'title', selected: true }), { kind: 'icon', color: '' });
  assert.deepEqual(resolve({ propTint: 'bogus', optionTint: '#111111' }), { kind: 'none', color: '' });
});
