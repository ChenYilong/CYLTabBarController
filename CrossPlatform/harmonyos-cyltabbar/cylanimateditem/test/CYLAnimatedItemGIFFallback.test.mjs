// [EN] Unit tests of the GIF fallbacks in CYLAnimatedItemGIFTiming.ts (CYLTableViewPlaceHolder 3fe1896d, 76762c6a): the
//      trailer check, the frames kept from a truncated file, and the cache file name. Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemGIFTiming.ts 中 GIF 回退的单元测试：结尾字节检查、截断文件保留的帧数与缓存文件名。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const G = await import('../src/main/ets/CYLAnimatedItemGIFTiming.ts');

test('a GIF has its trailer only when its last byte is 0x3B', () => {
  assert.equal(G.cylGIFHasTrailer(new Uint8Array([0x47, 0x49, 0x46, 0x3b])), true);
  assert.equal(G.cylGIFHasTrailer(new Uint8Array([0x47, 0x49, 0x46, 0x00])), false);
  assert.equal(G.cylGIFHasTrailer(new Uint8Array([])), false);
});

test('a truncated GIF drops its incomplete last frame but keeps one', () => {
  assert.equal(G.cylGIFUsableFrameCount(73, true), 73);
  assert.equal(G.cylGIFUsableFrameCount(2, false), 1);
  assert.equal(G.cylGIFUsableFrameCount(1, false), 1);
  assert.equal(G.cylGIFUsableFrameCount(0, false), 0);
});

test('the cache file name is stable for a URL and a size', () => {
  const a = G.cylGIFCacheFileName('Animations/a.gif', 1024);
  assert.equal(a, G.cylGIFCacheFileName('Animations/a.gif', 1024));
  assert.notEqual(a, G.cylGIFCacheFileName('Animations/b.gif', 1024));
  assert.notEqual(a, G.cylGIFCacheFileName('Animations/a.gif', 2048));
  assert.match(a, /^cyl-gif-[0-9a-f]+-1024\.gif$/);
});
