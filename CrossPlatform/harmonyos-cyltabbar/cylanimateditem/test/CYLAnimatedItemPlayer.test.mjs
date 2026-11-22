// [EN] Unit tests of CYLAnimatedItemPlayer.ts (timed player, default playback rules, engine binding) and
//      CYLAnimatedItemGIFTiming.ts. Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemPlayer.ts（定时播放器、默认播放规则、引擎连接）与 CYLAnimatedItemGIFTiming.ts 的单元测试。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const P = await import('../src/main/ets/CYLAnimatedItemPlayer.ts');
const { CYLAnimatedItemSource } = await import('../src/main/ets/CYLAnimatedItemSource.ts');
const G = await import('../src/main/ets/CYLAnimatedItemGIFTiming.ts');

class FakeClock {
  t = 0;
  ticks = new Map();
  next = 1;
  now() { return this.t; }
  start(tick) { const id = this.next++; this.ticks.set(id, tick); return id; }
  stop(id) { this.ticks.delete(id); }
  advance(ms) { this.t += ms; [...this.ticks.values()].forEach((tick) => tick()); }
}

class TimedPlayer extends P.CYLAnimatedItemTimedPlayer {
  frames = [];
  get durationMs() { return 1000; }
  render() { this.frames.push(this.progressValue); }
}

function timed() {
  const player = new TimedPlayer('GIF', CYLAnimatedItemSource.parse('a.gif'));
  player.clock = new FakeClock();
  return player;
}

test('a timed player plays one pass at its speed, then ends once', () => {
  const player = timed();
  let ended = 0;
  player.onEnded = () => ended++;
  player.speed = 2;
  player.play();
  assert.equal(player.isPlaying, true);
  player.clock.advance(250);
  assert.equal(player.progress, 0.5);
  player.clock.advance(300);
  assert.equal(player.progress, 1);
  assert.equal(player.isPlaying, false);
  assert.equal(ended, 1);
});

test('a looping timed player wraps around and never ends; stopAtProgress clamps', () => {
  const player = timed();
  let ended = 0;
  player.onEnded = () => ended++;
  player.loops = true;
  player.play();
  player.clock.advance(1250);
  assert.ok(Math.abs(player.progress - 0.25) < 1e-9);
  assert.equal(ended, 0);
  player.stopAtProgress(7);
  assert.equal(player.progress, 1);
  assert.equal(player.isPlaying, false);
  player.speed = 0;
  assert.equal(player.speed, 1, 'speed 0 or less is 1');
});

class Recorder extends P.CYLAnimatedItemPlayer {
  calls = [];
  playing = false;
  get isPlaying() { return this.playing; }
  play() { this.calls.push('play'); this.playing = true; }
  stopAtProgress(p) { this.calls.push('stop ' + p); this.playing = false; }
  destroy() { this.calls.push('destroy'); super.destroy(); }
}

function playback(overrides) {
  return Object.assign({ selected: false, speed: 1, loops: false, restartToken: 0 }, overrides);
}

test('default rules: selected plays, unselected rests at 0, a restart plays, speed and loop apply', () => {
  const driver = new P.CYLAnimatedItemPlaybackDriver();
  const player = new Recorder('Lottie', CYLAnimatedItemSource.parse('a.json'));
  driver.attach(player, playback({ selected: true, speed: 1.5 }));
  assert.deepEqual(player.calls, ['play']);
  assert.equal(player.speed, 1.5);
  driver.update(playback({ selected: false, speed: 1.5 }));
  driver.update(playback({ selected: false, speed: 1.5, restartToken: 1 }));
  driver.update(playback({ selected: true, speed: 3, restartToken: 1 }));
  assert.deepEqual(player.calls, ['play', 'stop 0', 'play', 'play']);
  assert.equal(player.speed, 3);
  player.playing = false;
  driver.update(playback({ selected: true, speed: 3, restartToken: 1, loops: true }));
  assert.equal(player.loops, true);
  assert.deepEqual(player.calls.slice(-1), ['play'], 'turning loop on replays a finished pass of a selected item');
});

test('the binding hands the player out, reports it loaded, forwards its end, and releases it', () => {
  const events = [];
  const host = Object.assign(playback({ selected: false }), {
    drivesPlayback: true,
    onLoaded: () => events.push('loaded'),
    onFailed: () => events.push('failed'),
    onEnded: () => events.push('ended'),
    onPlayer: (p) => events.push(p === undefined ? 'player gone' : 'player ' + p.type)
  });
  const binding = new P.CYLAnimatedItemEngineBinding();
  const player = new Recorder('SVGA', CYLAnimatedItemSource.parse('a.svga'));
  binding.ready(host, player);
  assert.deepEqual(events, ['player SVGA', 'loaded']);
  assert.deepEqual(player.calls, ['stop 0']);
  player.didEnd();
  assert.deepEqual(events.slice(-1), ['ended']);
  binding.release();
  assert.deepEqual(events.slice(-1), ['player gone']);
  assert.deepEqual(player.calls.slice(-1), ['destroy']);
});

test('a host that drives the player itself gets it untouched', () => {
  const host = Object.assign(playback({ selected: true }), {
    drivesPlayback: false, onLoaded: () => {}, onFailed: () => {}, onEnded: () => {}, onPlayer: () => {}
  });
  const binding = new P.CYLAnimatedItemEngineBinding();
  const player = new Recorder('PAG', CYLAnimatedItemSource.parse('a.pag'));
  binding.ready(host, player);
  binding.update(Object.assign(host, { selected: false, restartToken: 5 }));
  assert.deepEqual(player.calls, []);
});

test('GIF timing: default delays, the frame at a progress, the last frame at 1', () => {
  const delays = G.cylGIFDelays(3, [0, 200]);
  assert.deepEqual(delays, [100, 200, 100]);
  assert.equal(G.cylGIFDuration(delays), 400);
  assert.equal(G.cylGIFFrameIndex(delays, 0), 0);
  assert.equal(G.cylGIFFrameIndex(delays, 0.3), 1);
  assert.equal(G.cylGIFFrameIndex(delays, 0.8), 2);
  assert.equal(G.cylGIFFrameIndex(delays, 1), 2);
  assert.equal(G.cylGIFFrameIndex([], 0.5), -1);
});

test('GIF timing: a delay of 10 ms or less shows for 100 ms, as browsers and the iOS / Android engines do', () => {
  assert.deepEqual(G.cylGIFDelays(5, [10, 1, 11, 20, -5]), [100, 100, 11, 20, 100]);
});
