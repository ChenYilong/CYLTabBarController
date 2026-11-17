/**
 * [EN] Tests of cyl-animated-item's playback methods (src/cyl-animated-item/index.js) in a small fake of the mini program
 *      `Component()` runtime: `playAnimation()` on the engine node (pending until `ready`), the resting frame through
 *      `cyl_setProgress` / `cyl_goToAndStop`, Lottie data copied per item, and GIF stills timed by `gifDuration`.
 *      Run: `npm test`.
 * [CN] 在模拟的小程序 `Component()` 运行时中测试 cyl-animated-item 的播放方法：引擎节点上的 `playAnimation()`（`ready` 前延后），
 *      通过 `cyl_setProgress` / `cyl_goToAndStop` 显示静止帧，每个条目复制一份 Lottie 数据，以及按 `gifDuration` 计时的 GIF 静帧。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylMount(properties, engine) {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-animated-item/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  const observers = Object.entries(definition.observers).map(([keys, fn]) => ({ keys: keys.split(',').map((k) => k.trim()), fn }))
  const item = {
    data,
    setData(patch, callback) {
      Object.entries(patch).forEach(([key, value]) => {
        if (key.startsWith('m.')) this.data.m = { ...this.data.m, [key.slice(2)]: value }
        else this.data[key] = value
      })
      if (callback) callback()
    },
    selectComponent(id) {
      return id === '#cyl-animated-item-engine' ? engine : null
    },
    events: [],
    triggerEvent(name, detail) { this.events.push([name, detail]) },
    set(patch) {
      this.setData(patch)
      observers.filter((o) => o.keys.some((k) => k in patch)).forEach((o) => o.fn.apply(this, o.keys.map((k) => this.data[k])))
    },
  }
  Object.assign(item, definition.methods)
  item.set(properties)
  definition.lifetimes.attached.call(item)
  return { item, detach: () => definition.lifetimes.detached.call(item) }
}

function cylEngine(extra) {
  const calls = []
  const record = (name) => (...args) => calls.push([name, ...args])
  return { calls, cyl_playFromStart: record('playFromStart'), ...extra(record) }
}

test('playAnimation waits for ready, then plays the engine from the start', () => {
  const engine = cylEngine((r) => ({ cyl_setProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.pag', autoplay: false }, engine)
  item.playAnimation()
  assert.deepEqual(engine.calls, [])
  item.cyl_onAnimationReady()
  assert.deepEqual(engine.calls, [['playFromStart']])
})

test('without autoplay the engine rests at restingProgress, and at 1 while selected', () => {
  const engine = cylEngine((r) => ({ cyl_setProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, restingProgress: 0.5 }, engine)
  item.cyl_onAnimationReady()
  item.set({ selected: true })
  assert.deepEqual(engine.calls, [['setProgress', 0.5], ['setProgress', 1]])
})

test('Lottie rests through cyl_goToAndStop on its frames, and plays its own copy of the data', () => {
  const engine = cylEngine((r) => ({ cyl_goToAndStop: r('goToAndStop'), cyl_animation: () => ({ totalFrames: 11 }) }))
  const data = { v: '5.7', layers: [] }
  const { item } = cylMount({ animationData: data, autoplay: false, restingProgress: 0.3 }, engine)
  assert.notEqual(item.data.lottieData, data)
  assert.deepEqual(item.data.lottieData, data)
  item.cyl_onAnimationReady()
  assert.deepEqual(engine.calls, [['goToAndStop', 3, true]])
})

test('a GIF with stills plays one pass, then shows its last still while selected', async () => {
  const { item, detach } = cylMount({ animationUrl: 'star.gif', gifFirstFrame: 'f.png', gifLastFrame: 'l.png', gifDuration: 20, selected: true }, null)
  assert.equal(item.data.m.gifPath, 'l.png')
  item.playAnimation()
  assert.equal(item.data.m.gifPath, 'star.gif')
  await new Promise((resolve) => setTimeout(resolve, 40))
  assert.equal(item.data.m.gifPath, 'l.png')
  detach()
})

test('engine ready, complete, loop complete and error are forwarded as item events', () => {
  const engine = cylEngine((r) => ({ cyl_setProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.json' }, engine)
  item.cyl_onAnimationReady({ detail: { duration: 1.5 } })
  item.cyl_onAnimationComplete({ detail: {} })
  item.cyl_onAnimationLoopComplete({ detail: {} })
  item.cyl_onAnimationError({ detail: { message: 'bad file' } })
  assert.deepEqual(item.events, [
    ['animationready', { duration: 1.5 }],
    ['animationcomplete', {}],
    ['animationloopcomplete', {}],
    ['animationerror', { message: 'bad file' }],
  ])
})
