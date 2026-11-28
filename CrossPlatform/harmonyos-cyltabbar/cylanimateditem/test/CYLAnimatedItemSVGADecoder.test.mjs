// [EN] Unit tests of the SVGA 2.x decoder (svga/CYLSVGADecoder.ts and svga/CYLInflate.ts), ported from
//      CollectionViewClassifyMenu's SVGADecoder.test.ets and svga-decoder-test.js: params / images / sprites, frames as
//      SVGAPlayer draws them, progress to frames, SVGA 1.x and damaged files rejected, the inflate against Node's zlib on the
//      example's .svga files and on stored / fixed-Huffman blocks, and the engine picked by extension.
//      Node 22.18+: node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] SVGA 2.x 解码器的单元测试，移植自 CollectionViewClassifyMenu 的 SVGADecoder.test.ets 与 svga-decoder-test.js。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const D = await import('../src/main/ets/svga/CYLSVGADecoder.ts');
const { cylInflateZlib } = await import('../src/main/ets/svga/CYLInflate.ts');
const S = await import('../src/main/ets/CYLAnimatedItemSVGATiming.ts');
const { CYLAnimatedItemTypeRegistry } = await import('../src/main/ets/CYLAnimatedItemTypes.ts');
const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '../../../..');

/** [EN] Protobuf writer for the test movies. [CN] 测试动画的 protobuf 写入器。 */
class ProtoWriter {
  bytes = [];
  varint(value) {
    let v = value;
    while (v >= 0x80) { this.bytes.push((v % 0x80) | 0x80); v = Math.floor(v / 0x80); }
    this.bytes.push(v);
    return this;
  }
  key(field, wire) { return this.varint(field * 8 + wire); }
  float(field, value) {
    const view = new DataView(new ArrayBuffer(4));
    view.setFloat32(0, value, true);
    this.key(field, 5);
    for (let i = 0; i < 4; i++) this.bytes.push(view.getUint8(i));
    return this;
  }
  int(field, value) { return this.key(field, 0).varint(value); }
  data(field, value) { this.key(field, 2).varint(value.length); value.forEach((b) => this.bytes.push(b)); return this; }
  text(field, value) { return this.data(field, [...Buffer.from(value, 'utf8')]); }
  message(field, m) { return this.data(field, m.bytes); }
}

/** [EN] A zlib stream of `payload` in one stored deflate block (the checksum is not read). [CN] 单个存储块的 zlib 流。 */
function zlibStored(payload) {
  const header = [0x78, 0x01, 0x01, payload.length & 0xff, payload.length >> 8, (~payload.length) & 0xff, ((~payload.length) >> 8) & 0xff];
  return new Uint8Array(header.concat(payload).concat([0, 0, 0, 0]));
}

// [EN] Shape types of svga.proto: 0 shape, 1 rect, 2 ellipse, 3 keep. [CN] svga.proto 的形状类型。
const RECT = 1;
const KEEP = 3;

function testMovie() {
  const params = new ProtoWriter().float(1, 96).float(2, 48).int(3, 20).int(4, 4);
  const image = new ProtoWriter().text(1, 'img_0').data(2, [0x89, 0x50, 0x4e, 0x47]);
  const layout = new ProtoWriter().float(1, 2).float(2, 3).float(3, 40).float(4, 20);
  const transform = new ProtoWriter().float(1, 1).float(4, 1).float(5, 10).float(6, 5);
  const visible = new ProtoWriter().float(1, 0.5).message(2, layout).message(3, transform).text(4, 'M0 0 L10 10 Z');
  const rect = new ProtoWriter().float(3, 8).float(4, 6).float(5, 2);
  const fill = new ProtoWriter().float(1, 1).float(4, 1);
  const styles = new ProtoWriter().message(1, fill).float(3, 2).int(4, 1);
  const shape = new ProtoWriter().int(1, RECT).message(3, rect).message(10, styles);
  const shaped = new ProtoWriter().float(1, 1).message(5, shape);
  const keep = new ProtoWriter().float(1, 1).message(5, new ProtoWriter().int(1, KEEP));
  const sprite = new ProtoWriter().text(1, 'img_0').message(2, new ProtoWriter()).message(2, visible).message(2, shaped).message(2, keep);
  const movie = new ProtoWriter().text(1, '2.0.0').message(2, params).message(3, image).message(4, sprite);
  return zlibStored(movie.bytes);
}

test('the SVGA engine is picked by extension', () => {
  assert.equal(CYLAnimatedItemTypeRegistry.typeOf('svga/tab_home.svga'), 'SVGA');
  assert.equal(CYLAnimatedItemTypeRegistry.typeOf('svga/TAB.SVGA'), 'SVGA');
  assert.equal(CYLAnimatedItemTypeRegistry.typeOf('rive/house.riv'), 'Rive');
});

test('decodes params, images and sprites', () => {
  const movie = D.cylInflateSVGAMovie(testMovie());
  assert.equal(movie.version, '2.0.0');
  assert.equal(movie.viewBoxWidth, 96);
  assert.equal(movie.viewBoxHeight, 48);
  assert.equal(movie.fps, 20);
  assert.equal(movie.frames, 4);
  assert.equal(S.cylSVGADurationMs(movie.frames, movie.fps), 200);
  assert.equal(movie.images.get('img_0')?.length, 4);
  assert.equal(movie.sprites.length, 1);
  assert.equal(movie.sprites[0].imageKey, 'img_0');
  assert.equal(movie.sprites[0].frames.length, 4);
});

test('decodes frames as SVGAPlayer draws them', () => {
  const frames = D.cylInflateSVGAMovie(testMovie()).sprites[0].frames;
  // [EN] An empty frame hides the sprite (proto3: alpha 0). [CN] 空帧隐藏精灵（proto3：alpha 为 0）。
  assert.equal(frames[0].alpha, 0);
  assert.equal(frames[1].alpha, 0.5);
  assert.equal(frames[1].layout.x, 2);
  assert.equal(frames[1].layout.width, 40);
  assert.equal(frames[1].transform.tx, 10);
  assert.equal(frames[1].transform.b, 0);
  assert.equal(frames[1].clipPath, 'M0 0 L10 10 Z');
  assert.equal(frames[2].shapes.length, 1);
  assert.equal(frames[2].shapes[0].type, RECT);
  assert.equal(frames[2].shapes[0].rect.width, 8);
  assert.equal(frames[2].shapes[0].rect.cornerRadius, 2);
  assert.deepEqual([frames[2].shapes[0].styles.fill.r, frames[2].shapes[0].styles.fill.a], [1, 1]);
  assert.equal(frames[2].shapes[0].styles.strokeWidth, 2);
  assert.equal(frames[2].shapes[0].styles.lineCap, 1);
  // [EN] KEEP reuses the previous frame's shapes. [CN] KEEP 沿用上一帧的形状。
  assert.equal(frames[3].shapes.length, 1);
  assert.equal(frames[3].shapes[0].type, RECT);
});

test('maps progress to frames', () => {
  const movie = D.cylInflateSVGAMovie(testMovie());
  assert.equal(S.cylSVGAFrameAt(movie.frames, 0), 0);
  assert.equal(S.cylSVGAFrameAt(movie.frames, 0.5), 2);
  assert.equal(S.cylSVGAFrameAt(movie.frames, 1), 3);
});

test('rejects SVGA 1.x and damaged files', () => {
  assert.throws(() => D.cylInflateSVGAMovie(new Uint8Array([0x50, 0x4b, 3, 4])), /1\.x/);
  assert.throws(() => D.cylInflateSVGAMovie(new Uint8Array([1, 2, 3])), /zlib/);
});

test('the inflate matches Node zlib on the example SVGA files', () => {
  const files = ["CrossPlatform/harmonyos-cyltabbar/entry/src/main/resources/rawfile/svga/tab_chat.svga","CrossPlatform/harmonyos-cyltabbar/entry/src/main/resources/rawfile/svga/tab_home.svga","CrossPlatform/harmonyos-cyltabbar/entry/src/main/resources/rawfile/svga/tab_profile.svga","CrossPlatform/harmonyos-cyltabbar/entry/src/main/resources/rawfile/svga/tab_search.svga"];
  assert.ok(files.length > 0);
  for (const f of files) {
    const bytes = new Uint8Array(fs.readFileSync(path.join(repoRoot, f)));
    assert.equal(Buffer.compare(Buffer.from(cylInflateZlib(bytes)), zlib.inflateSync(Buffer.from(bytes))), 0, f);
    const movie = D.cylInflateSVGAMovie(bytes);
    assert.ok(movie.frames > 0, f);
    assert.ok([...movie.images.values()].every((b) => b[0] === 0x89 && b[1] === 0x50), f + ': PNG images');
    assert.ok(movie.sprites.every((s) => s.imageKey === '' || movie.images.has(s.imageKey)), f + ': image keys');
    assert.ok(movie.sprites.every((s) => s.frames.length === movie.frames), f + ': frames per sprite');
  }
});

test('the inflate reads stored and fixed-Huffman blocks', () => {
  for (const level of [0, 1]) {
    const data = Buffer.from('CYLAnimatedItem SVGA '.repeat(500));
    const z = zlib.deflateSync(data, { level, strategy: level === 1 ? zlib.constants.Z_FIXED : 0 });
    assert.equal(Buffer.compare(Buffer.from(cylInflateZlib(new Uint8Array(z))), data), 0, 'level ' + level);
  }
});
