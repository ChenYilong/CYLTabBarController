// [EN] Decoding and drawing tests on the example SVGA files, with a 2D context that records its calls.
// [CN] 用示例 SVGA 文件测试解码与绘制，2D 上下文记录调用。
const test = require('node:test')
const assert = require('node:assert')
const fs = require('fs')
const path = require('path')
const { cylDecodeSVGA } = require('../miniprogram_dist/svga/cyl_svga_movie.js')
const { cylDrawSVGAFrame, cylParsePath, cylFitTransform } = require('../miniprogram_dist/svga/cyl_svga_renderer.js')

const CYL_ASSETS = path.resolve(__dirname, '../../../Example-SwiftUI-Rive/AnimatedApp/SVGAAssets')
const CYL_FILES = fs.readdirSync(CYL_ASSETS).filter((name) => name.endsWith('.svga') && !name.startsWith('.'))

function cylRecordingContext() {
  const calls = []
  const record = (name) => (...args) => calls.push([name, ...args])
  const context = { calls, globalAlpha: 1 }
  ;['save', 'restore', 'setTransform', 'transform', 'clearRect', 'drawImage', 'beginPath', 'moveTo', 'lineTo',
    'bezierCurveTo', 'quadraticCurveTo', 'arcTo', 'closePath', 'clip', 'fill', 'stroke', 'setLineDash'].forEach((name) => {
    context[name] = record(name)
  })
  return context
}

test('every example file decodes as SVGA 2.x with PNG images', () => {
  assert.ok(CYL_FILES.length >= 6)
  CYL_FILES.forEach((name) => {
    const movie = cylDecodeSVGA(fs.readFileSync(path.join(CYL_ASSETS, name)))
    assert.match(movie.version, /^2\./, name)
    assert.ok(movie.viewBoxWidth > 0 && movie.viewBoxHeight > 0, name)
    assert.ok(movie.frames > 0 && movie.fps > 0, name)
    assert.ok(movie.sprites.length > 0, name)
    const images = Object.values(movie.images)
    assert.ok(images.length > 0, name)
    images.forEach((bytes) => assert.deepStrictEqual(Array.from(bytes.slice(0, 4)), [0x89, 0x50, 0x4e, 0x47], name))
    movie.sprites.forEach((sprite) => assert.strictEqual(sprite.frames.length, movie.frames, name))
  })
})

test('frames draw the bitmaps, and the animation changes between frames', () => {
  CYL_FILES.forEach((name) => {
    const movie = cylDecodeSVGA(fs.readFileSync(path.join(CYL_ASSETS, name)))
    const bitmaps = {}
    Object.keys(movie.images).forEach((key) => { bitmaps[key] = { key } })
    const draws = (frame) => {
      const context = cylRecordingContext()
      cylDrawSVGAFrame(context, movie, bitmaps, frame, 64, 64, 'contain')
      return context.calls.filter((call) => call[0] !== 'save' && call[0] !== 'restore')
    }
    const first = draws(0)
    const middle = draws(movie.frames / 2)
    const last = draws(movie.frames - 1)
    const images = (calls) => calls.filter((call) => call[0] === 'drawImage').length
    assert.ok(images(first) + images(middle) + images(last) > 0, `${name} draws images`)
    assert.notDeepStrictEqual(JSON.stringify(first), JSON.stringify(middle), `${name} animates`)
    // [EN] Out-of-range frames clamp to the last one. [CN] 超出范围的帧限制为最后一帧。
    assert.deepStrictEqual(JSON.stringify(draws(movie.frames + 10)), JSON.stringify(last))
  })
})

test('SVG paths become absolute move, line, curve and close commands', () => {
  assert.deepStrictEqual(cylParsePath('M10 10 L20 10 l0 10 H5 v-5 Z'), [
    ['M', 10, 10], ['L', 20, 10], ['L', 20, 20], ['L', 5, 20], ['L', 5, 15], ['Z'],
  ])
  assert.deepStrictEqual(cylParsePath('M0,0 C1,2 3,4 5,6 S9,10 11,12'), [
    ['M', 0, 0], ['C', 1, 2, 3, 4, 5, 6], ['C', 7, 8, 9, 10, 11, 12],
  ])
  assert.deepStrictEqual(cylParsePath('m1 1 2 2 q1 1 2 2 t2 2'), [
    ['M', 1, 1], ['L', 3, 3], ['Q', 4, 4, 5, 5], ['Q', 6, 6, 7, 7],
  ])
  assert.deepStrictEqual(cylParsePath('M0 0 A5 5 0 0 1 10 0'), [['M', 0, 0], ['L', 10, 0]])
})

test('the view box fits contain, cover and fill', () => {
  const movie = { viewBoxWidth: 100, viewBoxHeight: 50 }
  assert.deepStrictEqual(cylFitTransform(movie, 100, 100, 'contain'), { a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 25 })
  assert.deepStrictEqual(cylFitTransform(movie, 100, 100, 'cover'), { a: 2, b: 0, c: 0, d: 2, tx: -50, ty: 0 })
  assert.deepStrictEqual(cylFitTransform(movie, 100, 100, 'fill'), { a: 1, b: 0, c: 0, d: 2, tx: 0, ty: 0 })
})

test('SVGA 1.x (ZIP) files are rejected with a clear message', () => {
  assert.throws(() => cylDecodeSVGA(new Uint8Array([0x50, 0x4b, 3, 4, 0, 0])), /SVGA 1\.x/)
})
