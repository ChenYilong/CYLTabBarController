// [EN] Unit tests of CYLRiveLoopPolicy.ts (when CYLRiveIcon repeats a pass). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditemrive/test/*.test.mjs
// [CN] CYLRiveLoopPolicy.ts 的单元测试（CYLRiveIcon 何时重复播放）。
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { CYLRiveLoopPolicy as P } from '../src/main/ets/CYLRiveLoopPolicy.ts';
import { CYLAnimatedItemTypeRegistry as R } from '../../cylanimateditem/src/main/ets/CYLAnimatedItemTypes.ts';

test('the tab policy is the same as the strings the tab bar relied on: active only while selected', () => {
  assert.equal(P.isActive(P.WhileSelected, false, false), false);
  assert.equal(P.isActive(P.WhileSelected, true, false), true);
  assert.equal(P.schedulesNextPass(P.WhileSelected, true, false, false), false);
  assert.equal(P.schedulesNextPass(P.WhileSelected, true, true, false), true);
  assert.equal(P.schedulesNextPass(P.WhileSelected, false, true, false), false);
});

test('tab policy: a load or a change plays when selected and stops otherwise, as before', () => {
  assert.equal(P.updateAction(P.WhileSelected, true, false, false), P.Play);
  assert.equal(P.updateAction(P.WhileSelected, false, false, false), P.Stop);
  assert.equal(P.updateAction(P.WhileSelected, false, true, false), P.Stop);
});

test('while playing: the next pass is scheduled without any selection', () => {
  assert.equal(P.schedulesNextPass(P.WhilePlaying, true, false, false), true);
  assert.equal(P.schedulesNextPass(P.WhilePlaying, false, false, false), false);
});

test('while playing: a never-selected item plays at load; stopped, it rests until a restart', () => {
  assert.equal(P.updateAction(P.WhilePlaying, false, false, false), P.Play);
  assert.equal(P.updateAction(P.WhilePlaying, false, false, true), P.None);
  assert.equal(P.schedulesNextPass(P.WhilePlaying, true, false, true), false);
});

test('while playing: unselected after it was selected stops it; selected plays again', () => {
  assert.equal(P.updateAction(P.WhilePlaying, false, true, false), P.Stop);
  assert.equal(P.updateAction(P.WhilePlaying, true, false, true), P.Play);
  assert.equal(P.schedulesNextPass(P.WhilePlaying, true, true, true), true);
});

test('registering Rive the way cylRegisterRiveEngine does keeps the x86_64 debug kit working', () => {
  // [EN] The kit adds x86_64 to Rive's ABIs; the helper registers without an ABI argument, so it is not overwritten.
  // [CN] 调试引擎包为 Rive 的 ABI 加入 x86_64；辅助函数注册时不传 ABI 参数，因此不会被覆盖。
  R.reset();
  R.setDeviceAbis(['x86_64']);
  assert.equal(R.supportsDevice('Rive'), false);
  R.setRequiredNativeAbis('Rive', R.requiredNativeAbis('Rive').concat(['x86_64']));
  R.register('Rive', undefined, '@ohos/rive');
  assert.equal(R.supportsDevice('Rive'), true);
  assert.equal(R.canPlay('icons.riv'), true);
  assert.deepEqual(R.requiredNativeAbis('Rive'), ['arm64-v8a', 'x86_64']);
  R.reset();
});

test('the default policy is the tab one', () => {
  assert.equal(P.WhileSelected, 'whileSelected');
  assert.notEqual(P.WhileSelected, P.WhilePlaying);
});
