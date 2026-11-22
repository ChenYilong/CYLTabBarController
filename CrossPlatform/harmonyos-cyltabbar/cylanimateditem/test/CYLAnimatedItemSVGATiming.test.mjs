// [EN] Unit tests of CYLAnimatedItemSVGATiming.ts: one pass's duration and the frame at a progress (1 is the last frame).
//      Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemSVGATiming.ts 的单元测试：一遍的时长与某进度的帧（1 为最后一帧）。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const S = await import('../src/main/ets/CYLAnimatedItemSVGATiming.ts');

test('an SVGA pass lasts frames / fps seconds, 20 fps when the file gives none', () => {
  assert.equal(S.cylSVGADurationMs(30, 15), 2000);
  assert.equal(S.cylSVGADurationMs(20, 0), 1000);
  assert.equal(S.cylSVGADurationMs(0, 30), 0);
});

test('progress 0 is the first frame and 1 the last', () => {
  assert.equal(S.cylSVGAFrameAt(30, 0), 0);
  assert.equal(S.cylSVGAFrameAt(30, 1), 29);
  assert.equal(S.cylSVGAFrameAt(30, 0.5), 15);
  assert.equal(S.cylSVGAFrameAt(30, 2), 29);
  assert.equal(S.cylSVGAFrameAt(30, -1), 0);
  assert.equal(S.cylSVGAFrameAt(0, 0.5), 0);
});
