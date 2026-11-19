// [EN] Unit tests of CYLAnimatedItemTypes.ts (CYLAnimatedItemEngines: app types, extra extensions, unregister). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemTypes.ts 的单元测试（CYLAnimatedItemEngines：App 类型、额外扩展名、注销）。
import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { CYLAnimatedItemTypeRegistry as R } from '../src/main/ets/CYLAnimatedItemTypes.ts';

beforeEach(() => R.reset());

test('built-in types by extension, a trailing .bin skipped', () => {
  assert.equal(R.typeOf('lottie/home.json'), 'Lottie');
  assert.equal(R.typeOf('icons.riv.bin'), 'Rive');
  assert.equal(R.typeOf('https://x/a.GIF?v=1'), 'GIF');
  assert.equal(R.typeOf('a.apng'), '');
  assert.deepEqual(R.missingTypes(), ['Lottie', 'PAG', 'Rive', 'SVGA', 'GIF']);
});

test('an app registers its own type with its extensions', () => {
  assert.equal(R.canPlay('tab.apng'), false, 'unknown before');
  R.register('APNG', ['.APNG', 'png']);
  assert.equal(R.typeOf('tab.apng'), 'APNG');
  assert.equal(R.typeOf('tab.png'), 'APNG');
  assert.equal(R.canPlay('tab.apng'), true);
  assert.deepEqual(R.registeredTypes(), ['APNG']);
  assert.ok(R.knownTypes().some((type) => type.name === 'APNG'));
});

test('extensions added to a known type, without duplicates', () => {
  R.register('Lottie', ['lottiejson', 'json']);
  assert.deepEqual(R.extensionsOf('Lottie'), ['json', 'lottie', 'lottiejson']);
  assert.equal(R.canPlay('a.lottiejson'), true);
});

test('unregister: an added type is forgotten, a built-in type stays known', () => {
  R.register('APNG', ['apng']);
  R.register('Lottie', ['lottiejson']);
  R.unregister('APNG');
  assert.equal(R.typeOf('tab.apng'), '', 'forgotten with its extensions');
  assert.equal(R.canPlay('tab.apng'), false);
  R.unregister('Lottie');
  assert.equal(R.typeOf('a.json'), 'Lottie', 'still known');
  assert.equal(R.canPlay('a.json'), false, 'but no longer plays');
  assert.equal(R.typeOf('a.lottiejson'), '', 'its added extension is gone');
  assert.deepEqual(R.registeredTypes(), []);
});

test('registering a known type without extensions just turns it on; an empty name is ignored', () => {
  R.register('Rive');
  R.register('');
  assert.deepEqual(R.registeredTypes(), ['Rive']);
  assert.equal(R.canPlay('a.riv'), true);
});
