// [EN] Unit tests of CYLAnimatedItemCountdown, the countdown rules of the HarmonyOS CYLAnimatedItemView (the same cases as iOS
//      CYLAnimatedItemCountdownTests, Android CYLAnimatedItemCountdownTest and the mini program's
//      cyl_animated_item_countdown.test.js). Run with Node 22.18+ (type stripping):
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemCountdown（鸿蒙 CYLAnimatedItemView 的倒计时规则）的单元测试，用例与 iOS 的 CYLAnimatedItemCountdownTests、Android 的
//      CYLAnimatedItemCountdownTest 以及小程序的 cyl_animated_item_countdown.test.js 相同。用 Node 22.18+（类型擦除）运行：
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  CYLAnimatedItemCountdown, CYLCountdownIdle, CYLCountdownRunning, CYLCountdownFinished, cylCountdownText, cylCountdownTitleWidth,
} from '../src/main/ets/CYLAnimatedItemCountdown.ts';

function clock(seconds) {
  const c = { millis: seconds * 1000, now: () => c.millis, set: (s) => { c.millis = s * 1000; } };
  return c;
}

function storage() {
  const values = new Map();
  return { values, get: (n) => values.get(n), set: (n, v) => values.set(n, v), remove: (n) => values.delete(n) };
}

function make(c, store, key) {
  const events = [];
  const countdown = new CYLAnimatedItemCountdown(c.now, store, {
    onChanged: () => {},
    onStarted: () => events.push('start'),
    onTicked: (s) => events.push(`tick ${s}`),
    onFinished: () => events.push('finish'),
  });
  if (key) countdown.setCacheKey(key);
  return { countdown, events };
}

test('the text replaces %d and %ld', () => {
  assert.equal(cylCountdownText('%d s left', 14), '14 s left');
  assert.equal(cylCountdownText('还剩%ld秒', 9), '还剩9秒');
});

test('the seconds spent in the background count (issue #1)', () => {
  const c = clock(1000);
  const { countdown, events } = make(c);
  countdown.start(10);
  assert.equal(countdown.state, CYLCountdownRunning);
  assert.equal(countdown.remainingSeconds, 10);
  c.set(1004);
  countdown.refresh();
  assert.equal(countdown.shownSeconds, 6);
  c.set(1020);
  countdown.refresh();
  assert.equal(countdown.state, CYLCountdownFinished);
  assert.deepEqual(events, ['start', 'tick 10', 'tick 6', 'finish']);
});

test('it ticks once per second and finishes exactly', () => {
  const c = clock(500);
  const { countdown, events } = make(c);
  countdown.start(3);
  c.set(500.4); countdown.refresh();
  c.set(500.9); countdown.refresh();
  assert.equal(countdown.shownSeconds, 3);
  c.set(501.1); countdown.refresh();
  assert.equal(countdown.shownSeconds, 2);
  c.set(503); countdown.refresh();
  assert.equal(countdown.state, CYLCountdownFinished);
  countdown.refresh();
  assert.deepEqual(events, ['start', 'tick 3', 'tick 2', 'finish']);
});

test('a clock set back to before the start, or far past the end, closes the countdown', () => {
  const c = clock(10000);
  const { countdown } = make(c);
  countdown.start(60);
  c.set(5000);
  countdown.refresh();
  assert.equal(countdown.state, CYLCountdownFinished);
  countdown.start(60);
  assert.equal(countdown.state, CYLCountdownRunning, 'a new countdown can start');
  c.set(100000);
  countdown.refresh();
  assert.equal(countdown.state, CYLCountdownFinished);
  assert.equal(countdown.remainingSeconds, 0);
});

test('a reset is not a finish', () => {
  const c = clock(0);
  const { countdown, events } = make(c);
  countdown.start(30);
  countdown.reset();
  assert.equal(countdown.state, CYLCountdownIdle);
  assert.equal(events.includes('finish'), false);
});

test('a cached countdown is taken up again, with no start callback', () => {
  const c = clock(1000);
  const store = storage();
  make(c, store, 'sms-code').countdown.start(60);
  c.set(1042);
  const { countdown, events } = make(c, store, 'sms-code');
  assert.equal(countdown.state, CYLCountdownRunning);
  assert.equal(countdown.shownSeconds, 18);
  assert.deepEqual(events, ['tick 18']);
});

test('an expired, finished, reset or future cache is not taken up', () => {
  const store = storage();
  const c = clock(1000);
  make(c, store, 'k').countdown.start(60);
  c.set(2000);
  assert.equal(make(c, store, 'k').countdown.state, CYLCountdownIdle);
  assert.equal(store.values.size, 0, 'the expired cache is dropped');

  c.set(3000);
  const second = make(c, store, 'k').countdown;
  second.start(60);
  second.reset();
  assert.equal(make(c, store, 'k').countdown.state, CYLCountdownIdle);

  const third = make(c, store, 'k').countdown;
  third.start(60);
  c.set(3061);
  third.refresh();
  assert.equal(make(c, store, 'k').countdown.state, CYLCountdownIdle);

  c.set(10000);
  make(c, store, 'k').countdown.start(60);
  c.set(2000);
  assert.equal(make(c, store, 'k').countdown.state, CYLCountdownIdle, 'the clock was set back');
});

test('one width for every title', () => {
  const width = cylCountdownTitleWidth('Get code', '%d s left', 'Resend', 60, 16);
  assert.ok(width >= Math.ceil(cylCountdownTitleWidth('', '%d s left', '', 9, 16)));
  assert.ok(cylCountdownTitleWidth('获取验证码', '还剩%d秒', '重新获取', 60, 16) >= 16 * 5);
});
