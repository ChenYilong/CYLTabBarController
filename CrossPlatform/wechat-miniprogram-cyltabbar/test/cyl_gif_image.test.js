/**
 * [EN] Tests of cyl_gif_image.js (a GIF given as an item's image rests on its first frame): the GIF is the one of the
 *      Android CYLGIFDecoderTest, three 4 x 4 frames (red, green, blue; 100, 200, 300 ms). Run: `npm test`.
 * [CN] cyl_gif_image.js 的测试（作为条目图片传入的 GIF 停在第一帧）：GIF 与 Android CYLGIFDecoderTest 相同，三个 4 x 4 帧（红、绿、蓝；100、200、300 毫秒）。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylIsGIFImagePath, cylGIFImageInfo } = require('../src/cyl-animated-item/cyl_gif_image.js')

const THREE_FRAMES = Buffer.from('R0lGODlhBAAEAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQECgAAACwAAAAABAAEAAAICQABCBxIsCCAgAAh+QQFFAABACwAAAAABAAEAIEA/wAAAAAAAAAAAAAICQABCBxIsCCAgAAh+QQFHgABACwAAAAABAAEAIEAAP8AAAAAAAAAAAAICQABCBxIsCCAgAA7', 'base64')

test('a GIF path is recognized before its query', () => {
  assert.equal(cylIsGIFImagePath('/shared/tab_fire.gif'), true)
  assert.equal(cylIsGIFImagePath('https://example.com/a.GIF?v=1'), true)
  assert.equal(cylIsGIFImagePath('/shared/home.png'), false)
  assert.equal(cylIsGIFImagePath(''), false)
})

test('the size, the play time and the first frame of a GIF', () => {
  const info = cylGIFImageInfo(new Uint8Array(THREE_FRAMES))
  assert.equal(info.width, 4)
  assert.equal(info.height, 4)
  assert.equal(info.duration, 600)
  assert.equal(info.frame.length, 4 * 4 * 4)
  assert.deepEqual(Array.from(info.frame.slice(0, 4)), [255, 0, 0, 255], 'the first frame is red')
  assert.deepEqual(Array.from(info.frame.slice(60, 64)), [255, 0, 0, 255])
})

test('bytes that are not a GIF give null', () => {
  assert.equal(cylGIFImageInfo(new Uint8Array([1, 2, 3])), null)
  assert.equal(cylGIFImageInfo(new Uint8Array(Buffer.from('\x89PNG\r\n\x1a\n0000000000', 'binary'))), null)
})
