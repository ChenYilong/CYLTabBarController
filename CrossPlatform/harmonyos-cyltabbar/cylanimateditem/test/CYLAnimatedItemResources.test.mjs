// [EN] Unit tests of CYLAnimatedItemResources.ts (B30: system symbols). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemResources.ts 的单元测试（B30：系统符号）。
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cylIsSymbolResource, CYL_SYMBOL_RESOURCE_TYPE } from '../src/main/ets/CYLAnimatedItemResources.ts';

test('a sys.symbol resource is recognized by its type, as logged on the emulator', () => {
  // $r('sys.symbol.xmark') and $r('app.media.home_normal') as JSON.stringify printed them (emulator, 2026-11-19)
  assert.equal(cylIsSymbolResource({ id: 125831487, type: 40000, params: [], bundleName: 'b', moduleName: 'entry' }), true);
  assert.equal(cylIsSymbolResource({ id: 50331668, type: 20000, params: [], bundleName: 'b', moduleName: 'entry' }), false);
  assert.equal(cylIsSymbolResource('icons/edit.svg'), false);
  assert.equal(cylIsSymbolResource(undefined), false);
  assert.equal(CYL_SYMBOL_RESOURCE_TYPE, 40000);
});
