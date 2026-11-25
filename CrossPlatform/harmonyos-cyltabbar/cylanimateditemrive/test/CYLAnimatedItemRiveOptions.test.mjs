// [EN] Unit tests of cylanimateditemrive's CYLAnimatedItemRiveOptions.ts (pure): the number input's next value, the legacy
//      runtime choice and the active duration. Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditemrive/test/*.test.mjs
// [CN] cylanimateditemrive 的 CYLAnimatedItemRiveOptions.ts（纯逻辑）的单元测试。
import '../../cylanimateditem/test/cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const R = await import('../src/main/ets/CYLAnimatedItemRiveOptions.ts');

test('the color option is read for view model files only, as on iOS', () => {
  const options = (map) => (name) => map[name];
  assert.equal(R.CYLAnimatedItemRiveOption.COLOR, 'color');
  assert.equal(R.CYL_RIVE_COLOR_PROPERTY_PATH, 'color');
  assert.equal(R.cylRiveOptionColor(options({ color: '#FF3B30' })), 0xFFFF3B30 | 0);
  assert.equal(R.cylRiveOptionColor(options({ color: '00FF0080' })), 0x8000FF00 | 0, 'RRGGBBAA, as iOS');
  assert.equal(R.cylRiveOptionColor(options({})), undefined);
  assert.equal(R.cylRiveOptionColor(options({ color: ' ' })), undefined);
  assert.equal(R.cylRiveOptionColor(options({ color: '#12345' })), undefined);
  assert.equal(R.cylRiveOptionColor(options({ color: 'zzzzzz' })), undefined);
  assert.equal(R.cylRiveOptionColor(options({ color: '#FF3B30', legacy: '1' })), undefined);
  assert.equal(R.cylRiveOptionColor(options({ color: '#FF3B30', animation: 'idle' })), undefined);
});

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

test('the NO window of a restart lasts a frame, waits for the machine to settle, ends at 1.5 s', () => {
  assert.equal(R.cylRiveOffWindowEnds(16, true), false);
  assert.equal(R.cylRiveOffWindowEnds(50, true), true);
  assert.equal(R.cylRiveOffWindowEnds(500, false), false);
  assert.equal(R.cylRiveOffWindowEnds(500, true), true);
  assert.equal(R.cylRiveOffWindowEnds(1400, false), false);
  assert.equal(R.cylRiveOffWindowEnds(1500, false), true);
});

test('the NO window cap follows the active duration between a frame and 1.5 s (the case table of iOS and Android)', () => {
  const cases = [[0, 1500], [-1, 1500], [0.001, 50], [0.05, 50], [0.3, 300], [1, 1000], [1.5, 1500], [2, 1500], [60, 1500]];
  for (const [duration, cap] of cases) {
    assert.equal(R.cylRiveOffWindowCapMs(duration), cap, `activeDuration ${duration}`);
  }
});

test('a machine that never settles does not wait the full cap for a short input', () => {
  assert.equal(R.cylRiveOffWindowEnds(300, false), false);
  assert.equal(R.cylRiveOffWindowEnds(1400, false), false);
  assert.equal(R.cylRiveOffWindowEnds(290, false, 0.3), false);
  assert.equal(R.cylRiveOffWindowEnds(300, false, 0.3), true);
  assert.equal(R.cylRiveOffWindowEnds(1500, false, 0), true);
  assert.equal(R.cylRiveOffWindowEnds(1400, false, 60), false);
  assert.equal(R.cylRiveOffWindowEnds(50, true, 1), true);
  assert.equal(R.cylRiveOffWindowEnds(30, true, 0.001), false);
});
