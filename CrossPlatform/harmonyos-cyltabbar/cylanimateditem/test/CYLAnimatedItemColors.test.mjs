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
