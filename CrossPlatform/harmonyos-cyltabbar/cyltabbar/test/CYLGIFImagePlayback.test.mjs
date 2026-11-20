// [EN] Unit tests of CYLGIFImagePlayback (GIF tab images rest until played). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cyltabbar/test/*.test.mjs
// [CN] CYLGIFImagePlayback（GIF Tab 图片在播放前静止）的单元测试。Node 22.18+：node --test CrossPlatform/harmonyos-cyltabbar/cyltabbar/test/*.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { cylIsGIFImagePath, cylGIFDuration, CYLGIFImagePlayback, CYLGIFImageState } from '../src/main/ets/CYLGIFImagePlayback.ts';

test('a GIF path is recognized before its query', () => {
  assert.equal(cylIsGIFImagePath('https://example.com/tab_fire.GIF?v=2'), true);
  assert.equal(cylIsGIFImagePath('gif/a.gif#tint=title'), true);
  assert.equal(cylIsGIFImagePath('home.png'), false);
  assert.equal(cylIsGIFImagePath(undefined), false);
  assert.equal(cylIsGIFImagePath({ id: 1 }), false, 'a Resource is not a path');
});

test('the duration adds the delays, 100 ms for a missing one', () => {
  assert.equal(cylGIFDuration([100, 200, 300]), 600);
  assert.equal(cylGIFDuration([0, 50]), 150);
  assert.equal(cylGIFDuration([]), 100);
});

test('a GIF image rests, plays one pass per play, then rests', () => {
  const playback = new CYLGIFImagePlayback();
  assert.equal(playback.stateOf(3), CYLGIFImageState.Resting, 'rests at launch');
  const first = playback.play(3);
  assert.equal(playback.stateOf(3), CYLGIFImageState.PlayingOnce);
  const second = playback.play(3);
  assert.notEqual(first, second, 'a re-tap restarts it');
  assert.equal(playback.finish(3, first), false, 'an older pass does not end the newer one');
  assert.equal(playback.finish(3, second), true);
  assert.equal(playback.stateOf(3), CYLGIFImageState.Resting);
});

test('looping repeats the selected GIF image, and off rests them all', () => {
  const playback = new CYLGIFImagePlayback();
  playback.play(1);
  playback.setLoops(true, 2, 4);
  assert.equal(playback.stateOf(2), CYLGIFImageState.Looping, 'the selected one repeats');
  const token = playback.tokenOf(2);
  assert.equal(playback.finish(2, token), false, 'a looping GIF does not end');
  playback.play(0);
  assert.equal(playback.stateOf(0), CYLGIFImageState.Looping, 'a play while looping repeats');
  playback.setLoops(false, 2, 4);
  for (const index of [0, 1, 2, 3]) {
    assert.equal(playback.stateOf(index), CYLGIFImageState.Resting);
  }
});
