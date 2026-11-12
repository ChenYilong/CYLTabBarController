/**
 * [EN] Tests of the built library (miniprogram_dist/index.js) with a fake wx and a fake canvas: loading, playing,
 *      several canvases, destroy and load again, path reading, and the issue fixes. Run: `npm test` after
 *      `npm run build`.
 * [CN] 使用模拟的 wx 与 canvas 测试构建产物（miniprogram_dist/index.js）：加载、播放、多个 canvas、销毁后再次加载、
 *      读取 path，以及各个 issue 的修复。运行：先 `npm run build`，再 `npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('fs')
const path = require('path')

const CYL_SAMPLE = path.join(__dirname, '..', '..', '..', 'Example', 'Classes', 'Other', 'LottieResources',
  'tab_home_animate.json')
const cylFiles = {}

global.wx = {
  getSystemInfoSync: () => ({pixelRatio: 3}),
  env: {USER_DATA_PATH: 'wxfile://usr'},
  request({url, success, fail}) {
    setTimeout(() => {
      if (url.endsWith('/missing.json')) {
        success({statusCode: 404, data: ''})
      } else if (url.startsWith('https://')) {
        success({statusCode: 200, data: JSON.parse(fs.readFileSync(CYL_SAMPLE, 'utf8'))})
      } else {
        fail({errMsg: 'request:fail'})
      }
    }, 5)
  },
  getFileSystemManager: () => ({
    readFileSync(filePath) {
      if (filePath === '/assets/home.json') {
        return fs.readFileSync(CYL_SAMPLE, 'utf8')
      }
      throw new Error('no such file')
    },
    writeFileSync(filePath, data, encoding) {
      cylFiles[filePath] = {data, encoding}
    },
  }),
  createOffscreenCanvas: () => cylCanvas('offscreen'),
}

/**
 * [EN] A canvas node with a 2D context whose every method is a no-op, and a frame callback on a timer.
 * [CN] 一个 canvas 节点：2D context 的所有方法都是空操作，帧回调由定时器驱动。
 */
function cylCanvas(name) {
  const calls = {draw: 0, frames: 0}
  const context = new Proxy({}, {
    get(target, key) {
      if (key in target) {
        return target[key]
      }
      if (key === 'canvas') {
        return undefined
      }
      return () => {
        calls.draw += 1
      }
    },
    set(target, key, value) {
      target[key] = value
      return true
    },
  })
  const canvas = {
    name,
    width: 300,
    height: 300,
    calls,
    getContext: () => context,
    requestAnimationFrame(callback) {
      return setTimeout(() => {
        calls.frames += 1
        callback(Date.now())
      }, 4)
    },
    cancelAnimationFrame: (id) => clearTimeout(id),
    createImage() {
      const image = {}
      let source = ''
      Object.defineProperty(image, 'src', {get: () => source, set: (value) => { source = value }})
      return image
    },
  }
  return canvas
}

const lottie = require('../miniprogram_dist/index.js')
const cylAnimationData = () => JSON.parse(fs.readFileSync(CYL_SAMPLE, 'utf8'))
const cylWait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function cylLoad(canvas, extra) {
  lottie.setup(canvas)
  return lottie.loadAnimation(Object.assign({
    loop: true,
    autoplay: true,
    animationData: cylAnimationData(),
    rendererSettings: {context: canvas.getContext('2d')},
  }, extra || {}))
}

test.after(() => setTimeout(() => process.exit(0), 10))

test('exports, default export and no eval in the bundle (#2, #51, #56)', () => {
  assert.deepEqual(Object.keys(lottie.default).sort(),
    ['destroy', 'freeze', 'loadAnimation', 'setFrameInterval', 'setup', 'unfreeze'])
  const bundle = fs.readFileSync(path.join(__dirname, '..', 'miniprogram_dist', 'index.js'), 'utf8')
  assert.equal(/\beval\(/.test(bundle), false)
})

test('setup rejects a missing node or a null context (#32)', () => {
  assert.throws(() => lottie.setup(null), /canvas type="2d"/)
  assert.throws(() => lottie.setup({getContext: () => null}), /returned null/)
})

test('an animation plays on its canvas and stops after destroy', async () => {
  const canvas = cylCanvas('a')
  const animation = cylLoad(canvas)
  await cylWait(80)
  assert.ok(canvas.calls.frames > 3)
  assert.ok(animation.currentFrame > 0)
  animation.destroy()
  const frames = canvas.calls.frames
  await cylWait(40)
  assert.ok(canvas.calls.frames - frames <= 1)
})

test('load again after destroy works (#58, #13, #1)', async () => {
  const canvas = cylCanvas('b')
  cylLoad(canvas).destroy()
  const again = cylLoad(canvas)
  await cylWait(60)
  assert.ok(again.currentFrame > 0)
  again.destroy()
})

test('several canvases play together, and destroying one keeps the other going (#16, #55)', async () => {
  const first = cylCanvas('first')
  const second = cylCanvas('second')
  const a = cylLoad(first)
  const b = cylLoad(second)
  await cylWait(60)
  const before = a.currentFrame
  b.destroy()
  await cylWait(80)
  assert.ok(a.currentFrame !== before, 'the first animation keeps playing after the second canvas is gone')
  a.destroy()
})

test('global destroy() empties wrappers first (PR #17)', () => {
  const canvas = cylCanvas('c')
  cylLoad(canvas, {name: 'named'})
  assert.doesNotThrow(() => lottie.destroy('named'))
})

test('path: package file, network URL, HTTP error, zip (#15, #42, #47)', async () => {
  const canvas = cylCanvas('d')
  const local = cylLoad(canvas, {animationData: undefined, path: '/assets/home.json'})
  assert.ok(local.totalFrames > 0 || local.cylAnimation)
  local.destroy()

  let ready = false
  const remote = cylLoad(canvas, {animationData: undefined, path: 'https://example.com/home.json', autoplay: false})
  remote.addEventListener('DOMLoaded', () => {
    ready = true
  })
  assert.equal(remote.isLoaded, false)
  await cylWait(40)
  assert.equal(ready, true)
  remote.destroy()

  let failure = null
  const missing = cylLoad(canvas, {animationData: undefined, path: 'https://example.com/missing.json'})
  missing.addEventListener('data_failed', (error) => {
    failure = error
  })
  await cylWait(30)
  assert.match(String(failure && failure.message), /404/)

  let zipError = null
  const zip = cylLoad(canvas, {animationData: undefined, path: 'https://example.com/a.zip'})
  zip.addEventListener('data_failed', (error) => {
    zipError = error
  })
  await cylWait(5)
  assert.match(String(zipError && zipError.message), /zip/)
})

test('setFrameInterval accepts positive numbers only (#28)', () => {
  assert.doesNotThrow(() => lottie.setFrameInterval(33))
  assert.doesNotThrow(() => lottie.setFrameInterval(-1))
})

const colors = require('../src/cyl-lottie/cyl_lottie_colors')

test('cyl-lottie colors: keypaths with * and **, invalid colors, input unchanged', () => {
  assert.deepEqual(colors.cylLottieColor('#FF0000'), [1, 0, 0, 1])
  assert.deepEqual(colors.cylLottieColor('#00f8'), null)
  assert.deepEqual(colors.cylLottieColor('#0000FF80').map((v) => Math.round(v * 100) / 100), [0, 0, 1, 0.5])
  assert.equal(colors.cylMatches(['**', 'Fill 1'], ['Layer', 'Group', 'Fill 1']), true)
  assert.equal(colors.cylMatches(['Layer', '*', 'Fill 1'], ['Layer', 'Group', 'Fill 1']), true)
  assert.equal(colors.cylMatches(['Layer', 'Fill 1'], ['Layer', 'Group', 'Fill 1']), false)
  const data = cylAnimationData()
  const recolored = colors.cylApplyLottieColors(data, {'**.Color': '#FF0000', '**': '#00FF00'})
  assert.notEqual(recolored, data)
  const fills = []
  const walk = (shapes) => (shapes || []).forEach((shape) => {
    if (shape.ty === 'fl' || shape.ty === 'st') fills.push(shape.c.k)
    if (shape.ty === 'gr') walk(shape.it)
  })
  recolored.layers.forEach((layer) => walk(layer.shapes))
  assert.ok(fills.length > 0)
  assert.ok(fills.every((value) => JSON.stringify(value) === JSON.stringify([0, 1, 0, 1])))
  assert.equal(colors.cylApplyLottieColors(data, {}), data)
  assert.equal(colors.cylApplyLottieColors(data, {'**': 'red'}), data)
})
