/**
 * [EN] The `tint` option of cyl-rive: after a frame, the drawn pixels are filled with one color (source-atop, identity
 *      transform, the whole canvas); no tint draws nothing. A fake 2D context records the calls.
 * [CN] cyl-rive 的 `tint` 选项：每帧之后用一种颜色填充已绘制的像素（source-atop、单位变换、整个画布）；没有 tint 时不绘制。
 *      伪造的 2D 上下文记录调用。
 */
const test = require('node:test')
const assert = require('node:assert')

function loadComponent() {
  let definition = null
  global.Component = (options) => { definition = options }
  global.wx = global.wx || { getSystemInfoSync: () => ({ platform: 'ios' }), getDeviceInfo: () => ({ platform: 'ios' }) }
  delete require.cache[require.resolve('../miniprogram_dist/cyl-rive/index.js')]
  require('../miniprogram_dist/cyl-rive/index.js')
  delete global.Component
  return definition
}

function fakeCanvas() {
  const calls = []
  const context = {
    save: () => calls.push(['save']),
    restore: () => calls.push(['restore']),
    setTransform: (...args) => calls.push(['setTransform', ...args]),
    fillRect: (...args) => calls.push(['fillRect', ...args, context.globalCompositeOperation, context.fillStyle]),
    globalCompositeOperation: 'source-over',
    fillStyle: '',
  }
  return { calls, canvas: { width: 84, height: 84, getContext: (type) => (type === '2d' ? context : null) } }
}

test('tint fills the drawn pixels with one color, source-atop, over the whole canvas', () => {
  const definition = loadComponent()
  assert.equal(definition.properties.tint.value, '')
  const { calls, canvas } = fakeCanvas()
  definition.methods.cyl_applyTint.call({ data: { tint: '#007AFF' } }, canvas)
  assert.deepEqual(calls, [['save'], ['setTransform', 1, 0, 0, 1, 0, 0], ['fillRect', 0, 0, 84, 84, 'source-atop', '#007AFF'], ['restore']])
})

test('no tint keeps the file colors: nothing is drawn', () => {
  const definition = loadComponent()
  const { calls, canvas } = fakeCanvas()
  definition.methods.cyl_applyTint.call({ data: { tint: '' } }, canvas)
  definition.methods.cyl_applyTint.call({ data: { tint: '  ' } }, canvas)
  definition.methods.cyl_applyTint.call({ data: { tint: '#FF0000' } }, { width: 1, height: 1 })
  assert.deepEqual(calls, [])
})
