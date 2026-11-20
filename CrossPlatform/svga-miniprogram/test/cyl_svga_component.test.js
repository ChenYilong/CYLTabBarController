// [EN] The cyl-svga component in Node: a fake wx, canvas node and selector query; checks loading, ready, playing to
//      complete, resting frames and a play request made while the file loads.
// [CN] 在 Node 中测试 cyl-svga 组件：模拟 wx、画布节点与选择器查询；检查加载、ready、播放到 complete、静止帧，以及文件加载期间的播放请求。
const test = require('node:test')
const assert = require('node:assert')
const fs = require('fs')
const path = require('path')

const CYL_FILE = path.resolve(__dirname, '../../../Example-SwiftUI-Rive/AnimatedApp/SVGAAssets/tab_home.svga')

function cylMakeComponent() {
  let definition
  global.Component = (value) => { definition = value }
  global.wx = {
    getSystemInfoSync: () => ({ platform: 'ios', pixelRatio: 2 }),
    getFileSystemManager: () => ({ readFileSync: (file) => { const b = fs.readFileSync(file); return b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength) } }),
    arrayBufferToBase64: (buffer) => Buffer.from(buffer).toString('base64'),
    env: { USER_DATA_PATH: 'wxfile://usr' },
  }
  delete require.cache[require.resolve('../miniprogram_dist/cyl-svga/index.js')]
  require('../miniprogram_dist/cyl-svga/index.js')
  const drawn = []
  const context = new Proxy({}, { get: (target, name) => (name in target ? target[name] : () => { if (name === 'drawImage') drawn.push(name) }), set: (target, name, value) => { target[name] = value; return true } })
  const canvas = {
    width: 0, height: 0,
    getContext: () => context,
    createImage: () => { const image = {}; Object.defineProperty(image, 'src', { set() { setTimeout(() => image.onload && image.onload(), 0) } }); return image },
    requestAnimationFrame: (callback) => setTimeout(callback, 5),
    cancelAnimationFrame: (id) => clearTimeout(id),
  }
  const component = { data: {}, events: [] }
  Object.keys(definition.properties).forEach((key) => { component.data[key] = definition.properties[key].value })
  Object.assign(component.data, definition.data)
  Object.assign(component, definition.methods)
  component.setData = (patch) => Object.assign(component.data, patch)
  component.triggerEvent = (name, detail) => component.events.push({ name, detail })
  component.createSelectorQuery = () => ({ select: () => ({ fields: () => ({ exec: (callback) => setTimeout(() => callback([{ node: canvas, width: 32, height: 32 }]), 0) }) }) })
  component.lifetimes = definition.lifetimes
  definition.lifetimes.created.call(component)
  definition.lifetimes.attached.call(component)
  return { component, drawn, definition }
}

const cylWait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
const cylWaitFor = async (check) => { for (let i = 0; i < 400 && !check(); i++) { await cylWait(10) } }

test('loads, sends ready, plays to complete without loop and rests on the last frame', async () => {
  const { component, drawn } = cylMakeComponent()
  Object.assign(component.data, { path: CYL_FILE, autoplay: false, restingFrame: 'last', speed: 4 })
  component.lifetimes.ready.call(component)
  await cylWaitFor(() => component.events.some((e) => e.name === 'ready'))
  const ready = component.events.find((e) => e.name === 'ready')
  assert.ok(ready && ready.detail.duration > 0)
  assert.strictEqual(component.cylFrame, component.cylMovie.frames - 1)
  assert.ok(drawn.length > 0)
  component.cyl_playFromStart()
  await cylWaitFor(() => component.events.some((e) => e.name === 'complete'))
  assert.ok(component.events.some((e) => e.name === 'complete'))
  assert.strictEqual(component.cylPlaying, false)
  component.cyl_stop()
  assert.strictEqual(component.cylFrame, component.cylMovie.frames - 1)
  component.lifetimes.detached.call(component)
})

test('a play request made while loading runs when ready; the first resting frame is 0', async () => {
  const { component } = cylMakeComponent()
  Object.assign(component.data, { path: CYL_FILE, autoplay: false, restingFrame: 'first', loop: true })
  component.lifetimes.ready.call(component)
  component.cyl_playFromStart(0)
  await cylWaitFor(() => component.cylPlaying)
  assert.strictEqual(component.cylPlaying, true)
  component.cyl_pause()
  assert.strictEqual(component.cylPlaying, false)
  component.cyl_stop()
  assert.strictEqual(component.cylFrame, 0)
  component.lifetimes.detached.call(component)
})

test('a broken file sends error', async () => {
  const { component } = cylMakeComponent()
  const broken = path.join(require('os').tmpdir(), 'cyl-broken.svga')
  fs.writeFileSync(broken, Buffer.from([1, 2, 3, 4]))
  Object.assign(component.data, { path: broken })
  component.lifetimes.ready.call(component)
  await cylWaitFor(() => component.events.some((e) => e.name === 'error'))
  assert.ok(component.events.some((e) => e.name === 'error'))
})

test('setting the same path again does not reload, so the file plays (bug B11)', async () => {
  const { component, definition } = cylMakeComponent()
  Object.assign(component.data, { path: CYL_FILE, autoplay: false, loop: true })
  component.lifetimes.ready.call(component)
  await cylWaitFor(() => component.events.some((e) => e.name === 'ready'))
  const token = component.cylLoadToken
  const movie = component.cylMovie
  // [EN] A host re-renders and sets the same inputs: WeChat runs the observer anyway. [CN] 宿主重新渲染并设置相同输入：微信仍会运行 observer。
  for (let i = 0; i < 5; i++) {
    definition.observers['path, fit'].call(component, component.data.path, component.data.fit)
  }
  assert.strictEqual(component.cylLoadToken, token)
  assert.strictEqual(component.cylMovie, movie)
  component.cyl_playFromStart(0)
  assert.strictEqual(component.cylPlaying, true)
  // [EN] A new path still reloads. [CN] 新路径仍会重新加载。
  component.data.path = CYL_FILE.replace('tab_home', 'tab_chat')
  definition.observers['path, fit'].call(component, component.data.path, component.data.fit)
  assert.strictEqual(component.cylLoadToken, token + 1)
  component.lifetimes.detached.call(component)
})

test('after a failed load the same path loads again (bug B11)', async () => {
  const { component, definition } = cylMakeComponent()
  const broken = path.join(require('os').tmpdir(), 'cyl-broken-again.svga')
  fs.writeFileSync(broken, Buffer.from([1, 2, 3, 4]))
  Object.assign(component.data, { path: broken })
  component.lifetimes.ready.call(component)
  await cylWaitFor(() => component.events.some((e) => e.name === 'error'))
  const token = component.cylLoadToken
  definition.observers['path, fit'].call(component, component.data.path, component.data.fit)
  assert.strictEqual(component.cylLoadToken, token + 1)
})
