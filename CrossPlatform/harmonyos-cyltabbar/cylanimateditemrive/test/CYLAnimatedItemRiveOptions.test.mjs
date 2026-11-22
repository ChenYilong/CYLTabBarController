// [EN] Unit tests of cylanimateditemrive's CYLAnimatedItemRiveOptions.ts (pure): the number input's next value, the legacy
//      runtime choice and the active duration. Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditemrive/test/*.test.mjs
// [CN] cylanimateditemrive 的 CYLAnimatedItemRiveOptions.ts（纯逻辑）的单元测试。
import '../../cylanimateditem/test/cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const R = await import('../src/main/ets/CYLAnimatedItemRiveOptions.ts');

test('a number input steps through its values, cycling, else +1', () => {
  assert.equal(R.cylRiveNextNumber('3,4,5,6', 3), 4);
  assert.equal(R.cylRiveNextNumber('3,4,5,6', 6), 3);
  assert.equal(R.cylRiveNextNumber('3,4,5,6', 9), 3);
  assert.equal(R.cylRiveNextNumber('3,4,5,6', undefined), 3);
  assert.equal(R.cylRiveNextNumber(undefined, 2), 3);
  assert.equal(R.cylRiveNextNumber(' , x', undefined), 1);
});

test('state machine inputs and named animations play without the view model', () => {
  const opts = (o) => (name) => o[name];
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({})), false);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ legacy: '1' })), true);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ input: 'active' })), true);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ triggerInput: 'go' })), true);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ animation: 'idle' })), true);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ numberInput: 'Rooms' })), true);
  assert.equal(R.cylRiveUsesLegacyRuntime(opts({ trigger: 'tap' })), false);
});

test('the boolean stays true for the duration option, 1 s by default', () => {
  assert.equal(R.cylRiveActiveDuration(undefined), 1);
  assert.equal(R.cylRiveActiveDuration('0'), 0);
  assert.equal(R.cylRiveActiveDuration('2.5'), 2.5);
  assert.equal(R.cylRiveActiveDuration('-1'), 1);
  assert.equal(R.cylRiveActiveDuration('x'), 1);
});
