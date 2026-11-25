// [EN] Unit tests of CYLAnimatedItemColorCount.ts (tint spec v2, section 5): one-color detection of Lottie JSON text and of decoded GIF
//      pixels. The fixtures are the same files every platform tests: search_camera.json (the search bar's camera, one near-black color),
//      multi_color.json (green_lottie_tab_discover.json of the examples, 3 colors), gradient.json (CYLPlaceholderSuccess.json, a gradient
//      stroke), image_asset.json (gray_tabbar_home_animation.json, image assets).
//      Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemColorCount.ts 的单元测试（着色规范 v2 第 5 节）：Lottie JSON 文本与解码后 GIF 像素的单色检测。夹具与各平台测试使用的相同。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const K = await import('../src/main/ets/CYLAnimatedItemColorCount.ts');
const fixture = (name) => readFileSync(new URL(`./fixtures/${name}`, import.meta.url), 'utf8');

test('fixtures: the camera Lottie is one color; multi-color, gradient and image-asset files are multi-color', () => {
  assert.equal(K.cylAnimatedItemLottieColorCount(fixture('search_camera.json')), 1);
  assert.equal(K.cylAnimatedItemLottieColorKind(fixture('search_camera.json')), 'oneColor');
  assert.equal(K.cylAnimatedItemLottieColorCount(fixture('multi_color.json')), 3);
  assert.equal(K.cylAnimatedItemLottieColorKind(fixture('multi_color.json')), 'multiColor');
  assert.equal(K.cylAnimatedItemLottieColorCount(fixture('gradient.json')), -1);
  assert.equal(K.cylAnimatedItemLottieColorKind(fixture('gradient.json')), 'multiColor');
  assert.equal(K.cylAnimatedItemLottieColorCount(fixture('image_asset.json')), -1);
  assert.equal(K.cylAnimatedItemLottieColorKind(fixture('image_asset.json')), 'multiColor');
});

const shape = (ty, k, extra = {}) => ({ ty, c: { a: 0, k }, o: { a: 0, k: 100 }, ...extra });
const lottie = (...items) => JSON.stringify({ v: '5.7.0', layers: [{ ty: 4, shapes: [{ ty: 'gr', it: items }] }] });

test('Lottie: distinct fill and stroke colors, static and keyframes; tolerance +-2/255; alpha ignored; transparent skipped', () => {
  const kind = (...items) => K.cylAnimatedItemLottieColorKind(lottie(...items));
  assert.equal(kind(shape('fl', [0.1, 0.1, 0.1, 1])), 'oneColor');
  assert.equal(kind(shape('fl', [0.1, 0.1, 0.1, 1]), shape('st', [0.1, 0.1, 0.1, 1])), 'oneColor', 'fill and stroke of the same color');
  // within +-2/255: 0.1*255 = 25.5 -> 26; 28/255 is 2 away, 29/255 is 3 away
  assert.equal(kind(shape('fl', [26 / 255, 26 / 255, 26 / 255]), shape('st', [28 / 255, 24 / 255, 26 / 255])), 'oneColor');
  assert.equal(kind(shape('fl', [26 / 255, 26 / 255, 26 / 255]), shape('st', [29 / 255, 26 / 255, 26 / 255])), 'multiColor');
  assert.equal(kind(shape('fl', [0, 0, 0, 1]), shape('st', [1, 1, 1, 1])), 'multiColor');
  // alpha (4th component) ignored; fully transparent skipped
  assert.equal(kind(shape('fl', [0.2, 0.3, 0.4, 0.5]), shape('st', [0.2, 0.3, 0.4, 1])), 'oneColor');
  assert.equal(kind(shape('fl', [0.2, 0.3, 0.4, 1]), shape('st', [1, 0, 0, 0])), 'oneColor');
  assert.equal(kind(shape('fl', [1, 0, 0, 0])), 'unknown', 'only transparent colors: nothing to see');
  // keyframes: every value counts (start and end)
  const keyframed = { ty: 'fl', c: { a: 1, k: [{ t: 0, s: [1, 0, 0, 1], e: [0, 0, 1, 1] }, { t: 10, s: [0, 0, 1, 1] }] } };
  assert.equal(K.cylAnimatedItemLottieColorCount(lottie(keyframed)), 2);
  const sameKeyframes = { ty: 'fl', c: { a: 1, k: [{ t: 0, s: [1, 0, 0, 1] }, { t: 10, s: [1, 0, 0, 1] }] } };
  assert.equal(K.cylAnimatedItemLottieColorKind(lottie(sameKeyframes)), 'oneColor');
  // gradients and image assets / layers are multi-color
  assert.equal(kind(shape('fl', [0, 0, 0, 1]), { ty: 'gf' }), 'multiColor');
  assert.equal(kind({ ty: 'gs' }), 'multiColor');
  assert.equal(K.cylAnimatedItemLottieColorKind(JSON.stringify({ assets: [{ id: 'i', p: 'a.png', u: '' }], layers: [] })), 'multiColor');
  assert.equal(K.cylAnimatedItemLottieColorKind(JSON.stringify({ layers: [{ ty: 2, refId: 'i' }] })), 'multiColor');
  // colors 0...255 (a channel above 1) are read as bytes
  assert.equal(kind(shape('fl', [10, 20, 30, 1]), shape('st', [10, 20, 30, 1])), 'oneColor');
});

test('Lottie: a parse failure is unknown (the original colors stay)', () => {
  for (const text of ['', 'not json', '{', 'null', '42']) {
    assert.equal(K.cylAnimatedItemLottieColorCount(text), undefined, text);
    assert.equal(K.cylAnimatedItemLottieColorKind(text), 'unknown', text);
  }
  assert.equal(K.cylAnimatedItemLottieColorKind('{}'), 'unknown', 'no colors at all');
});

const pixels = (...px) => Uint8Array.from(px.flat());

test('GIF: one 4-bit bucket with >= 98 % of the visible pixels is one color', () => {
  const dark = [28, 28, 30, 255];
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(dark, dark, dark), false), 'oneColor');
  // anti-aliased edges in the same bucket (same high nibbles)
  assert.equal(K.cylAnimatedItemGifColorKind(pixels([16, 16, 16, 255], [31, 31, 31, 255]), false), 'oneColor');
  // exactly 98 %: 49 of 50 in the bucket
  const fifty = [...Array(49).fill(dark), [255, 0, 0, 255]];
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(...fifty), false), 'oneColor');
  // 97 %: 97 of 100
  const hundred = [...Array(97).fill(dark), [255, 0, 0, 255], [0, 255, 0, 255], [0, 0, 255, 255]];
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(...hundred), false), 'multiColor');
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(dark, [255, 255, 255, 255]), false), 'multiColor');
});

test('GIF: pixels with alpha < 0.1 are ignored; no visible pixel is unknown', () => {
  const dark = [28, 28, 30, 255];
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(dark, [255, 0, 0, 0], [0, 255, 0, 25], [0, 0, 255, 10]), false), 'oneColor');
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(dark, [255, 0, 0, 26]), false), 'multiColor', 'alpha 26/255 >= 0.1 counts');
  assert.equal(K.cylAnimatedItemGifColorKind(pixels([1, 2, 3, 0], [4, 5, 6, 20]), false), 'unknown');
  assert.equal(K.cylAnimatedItemGifColorKind(new Uint8Array(0), false), 'unknown');
});

test('GIF: premultiplied pixels are un-premultiplied first (a half-transparent red edge is red, not dark red)', () => {
  const red = [255, 0, 0, 255];
  const halfRedPremultiplied = [128, 0, 0, 128];
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(red, halfRedPremultiplied), true), 'oneColor');
  assert.equal(K.cylAnimatedItemGifColorKind(pixels(red, halfRedPremultiplied), false), 'multiColor', 'taken as straight alpha it is dark red');
});

test('detectable types and the cache', () => {
  assert.equal(K.cylAnimatedItemColorDetectable('Lottie'), true);
  assert.equal(K.cylAnimatedItemColorDetectable('GIF'), true);
  for (const type of ['PAG', 'SVGA', 'Rive', '']) {
    assert.equal(K.cylAnimatedItemColorDetectable(type), false, type);
  }
  const cache = new K.CYLAnimatedItemColorCountCache();
  assert.equal(cache.get('a.json'), undefined);
  cache.set('a.json', 'oneColor');
  assert.equal(cache.get('a.json'), 'oneColor');
  cache.clear();
  assert.equal(cache.get('a.json'), undefined);
});
