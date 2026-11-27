/**
 * [EN] Tests of cyl-animated-item's playback methods (src/cyl-animated-item/index.js) in a small fake of the mini program
 *      `Component()` runtime: `playAnimation()` on the engine node (pending until `ready`), the resting frame through
 *      `cylSetProgress` / `cylGoToAndStop`, Lottie data copied per item, and GIF stills timed by `gifDuration`.
 *      Run: `npm test`.
 * [CN] 在模拟的小程序 `Component()` 运行时中测试 cyl-animated-item 的播放方法：引擎节点上的 `playAnimation()`（`ready` 前延后），
 *      通过 `cylSetProgress` / `cylGoToAndStop` 显示静止帧，每个条目复制一份 Lottie 数据，以及按 `gifDuration` 计时的 GIF 静帧。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylMount(properties, engine, extra) {
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
  Object.assign(item, definition.methods, extra || {})
  item.set(properties)
  definition.lifetimes.attached.call(item)
  return { item, detach: () => definition.lifetimes.detached.call(item) }
}

function cylEngine(extra) {
  const calls = []
  const record = (name) => (...args) => calls.push([name, ...args])
  return { calls, cylPlayFromStart: record('playFromStart'), ...extra(record) }
}

test('playAnimation waits for ready, then plays the engine from the start', () => {
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.pag', autoplay: false }, engine)
  item.playAnimation()
  assert.deepEqual(engine.calls, [])
  item.cylOnAnimationReady()
  assert.deepEqual(engine.calls, [['playFromStart']])
})

test('without autoplay the engine rests at restingProgress, and at 1 while selected', () => {
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, restingProgress: 0.5 }, engine)
  item.cylOnAnimationReady()
  item.set({ selected: true })
  assert.deepEqual(engine.calls, [['setProgress', 0.5], ['setProgress', 1]])
})

test('Lottie rests through cylGoToAndStop on its frames, and plays its own copy of the data', () => {
  const engine = cylEngine((r) => ({ cylGoToAndStop: r('goToAndStop'), cyl_animation: () => ({ totalFrames: 11 }) }))
  const data = { v: '5.7', layers: [] }
  const { item } = cylMount({ animationData: data, autoplay: false, restingProgress: 0.3 }, engine)
  assert.notEqual(item.data.lottieData, data)
  assert.deepEqual(item.data.lottieData, data)
  item.cylOnAnimationReady()
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

test('showsImageWhenAnimationEnds: an ended play-once animation gives way to the still image until the next play', () => {
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress'), cylPause: r('pause') }))
  const { item } = cylMount({ animationUrl: 'success.json', image: 'ok.png', showsImageWhenAnimationEnds: true }, engine)
  item.cylOnAnimationReady()
  assert.equal(item.data.m.fallbackHidden, true)
  assert.equal(item.data.m.animationHidden, false)
  item.cylOnAnimationComplete({ detail: {} })
  assert.equal(item.data.animationEnded, true)
  assert.equal(item.data.m.animationHidden, true)
  assert.equal(item.data.m.fallbackHidden, false)
  assert.equal(item.data.m.fallbackImage, 'ok.png')
  assert.equal(item.data.m.usesEngine, true, 'the engine stays mounted, hidden, so the next play needs no reload')
  assert.deepEqual(item.events.map((e) => e[0]), ['animationready', 'animationcomplete', 'animationend'])
  item.playAnimation()
  assert.equal(item.data.animationEnded, false)
  assert.equal(item.data.m.animationHidden, false)
  assert.equal(item.data.m.fallbackHidden, true)
  assert.deepEqual(engine.calls.slice(-1), [['playFromStart']])
  item.cylOnAnimationComplete({ detail: {} })
  item.stopAnimation()
  assert.equal(item.data.m.animationHidden, false)
  item.cylOnAnimationComplete({ detail: {} })
  item.set({ showsImageWhenAnimationEnds: false })
  assert.equal(item.data.m.animationHidden, false)
})

test('showsImageWhenAnimationEnds: off by default, looping, or without an image (the placeholder shows)', () => {
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress') }))
  const plain = cylMount({ animationUrl: 'success.json', image: 'ok.png' }, engine).item
  plain.cylOnAnimationReady()
  plain.cylOnAnimationComplete({ detail: {} })
  assert.equal(plain.data.m.animationHidden, false)
  assert.equal(plain.data.m.fallbackHidden, true)
  const looping = cylMount({ animationUrl: 'success.json', image: 'ok.png', loop: true, showsImageWhenAnimationEnds: true }, engine).item
  looping.cylOnAnimationReady()
  looping.cylOnAnimationComplete({ detail: {} })
  assert.equal(looping.data.m.animationHidden, false)
  const bare = cylMount({ animationUrl: 'success.json', showsImageWhenAnimationEnds: true }, engine).item
  bare.cylOnAnimationReady()
  assert.equal(bare.data.m.fallbackImage, '')
  bare.cylOnAnimationComplete({ detail: {} })
  assert.equal(bare.data.m.animationHidden, true)
  assert.notEqual(bare.data.m.fallbackImage, '', 'the placeholder')
})

test('showsImageWhenAnimationEnds: a timed GIF pass ends with the still image and an animationcomplete event', async () => {
  const { item, detach } = cylMount({ animationUrl: 'star.gif', gifFirstFrame: 'f.png', gifLastFrame: 'l.png', gifDuration: 20, image: 'ok.png', showsImageWhenAnimationEnds: true }, null)
  item.playAnimation()
  assert.equal(item.data.m.gifPath, 'star.gif')
  await new Promise((resolve) => setTimeout(resolve, 60))
  assert.equal(item.data.m.gifPath, '')
  assert.equal(item.data.m.fallbackImage, 'ok.png')
  assert.equal(item.data.m.fallbackHidden, false)
  assert.deepEqual(item.events.slice(-2), [['animationcomplete', { type: 'gif' }], ['animationend', { type: 'gif' }]])
  item.playAnimation()
  assert.equal(item.data.m.gifPath, 'star.gif')
  detach()
})

test('engine ready, complete, loop complete and error are forwarded as item events', () => {
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress') }))
  const { item } = cylMount({ animationUrl: 'a.json' }, engine)
  item.cylOnAnimationReady({ detail: { duration: 1.5 } })
  item.cylOnAnimationComplete({ detail: {} })
  item.cylOnAnimationLoopComplete({ detail: {} })
  item.cylOnAnimationError({ detail: { message: 'bad file' } })
  assert.deepEqual(item.events, [
    ['animationready', { duration: 1.5 }],
    ['animationcomplete', {}],
    ['animationend', {}],
    ['animationloopcomplete', {}],
    ['animationerror', { message: 'bad file' }],
    ['resourcemissing', { resource: 'a.json', reason: 'decode failed' }],
  ])
})

test('the title switches to titleDarkColor when the system theme changes, and stops listening once detached', () => {
  let listener = null
  global.wx = {
    getAppBaseInfo: () => ({ theme: 'light' }),
    onThemeChange: (fn) => { listener = fn },
    offThemeChange: (fn) => { if (listener === fn) listener = null },
  }
  try {
    const { item, detach } = cylMount({ title: 'A', titleColor: '#333333', titleDarkColor: '#EEEEEE', titleFontWeight: 600 }, null)
    assert.equal(item.data.m.titleStyle, 'color: #333333;font-weight: 600;')
    listener({ theme: 'dark' })
    assert.equal(item.data.m.titleStyle, 'color: #EEEEEE;font-weight: 600;')
    item.set({ userInterfaceStyle: 'light' })
    assert.equal(item.data.m.titleStyle, 'color: #333333;font-weight: 600;')
    detach()
    assert.equal(listener, null)
  } finally {
    delete global.wx
  }
})

test('a GIF image rests on its first frame (a canvas), plays one pass when played, then rests again', async () => {
  const gif = Buffer.from('R0lGODlhBAAEAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQECgAAACwAAAAABAAEAAAICQABCBxIsCCAgAAh+QQFFAABACwAAAAABAAEAIEA/wAAAAAAAAAAAAAICQABCBxIsCCAgAAh+QQFHgABACwAAAAABAAEAIEAAP8AAAAAAAAAAAAICQABCBxIsCCAgAA7', 'base64')
  const read = []
  global.wx = {
    getAppBaseInfo: () => ({ theme: 'light' }),
    getFileSystemManager: () => ({ readFile: ({ filePath, success }) => { read.push(filePath); success({ data: gif.buffer.slice(gif.byteOffset, gif.byteOffset + gif.byteLength) }) } }),
  }
  const drawn = []
  const canvas = { width: 0, height: 0, getContext: () => ({
    createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }),
    clearRect() {},
    fillRect() {},
    putImageData: (pixels) => drawn.push(Array.from(pixels.data.slice(0, 4))),
  }) }
  const query = { select: () => query, fields: () => query, exec: (callback) => callback([{ node: canvas }]) }
  const { item, detach } = cylMount({ image: '/shared/tab_fire.gif' }, null, { createSelectorQuery: () => query })
  assert.deepEqual(read, ['/shared/tab_fire.gif'])
  assert.deepEqual(drawn, [[255, 0, 0, 255]], 'the first frame (red) is drawn')
  assert.equal(item.data.m.gifImage, '/shared/tab_fire.gif')
  assert.equal(item.data.m.gifImageStill, true, 'rests on the still')
  assert.equal(item.data.m.fallbackHidden, true, 'the looping <image> is hidden')
  item.cylPlayFromStart(0)
  assert.equal(item.data.m.gifImageStill, false, 'plays the GIF')
  assert.equal(item.data.m.fallbackImage, '/shared/tab_fire.gif')
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(item.data.m.gifImageStill, true, 'one pass (600 ms), then the still')
  item.set({ loop: true })
  item.cylPlayFromStart(0)
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(item.data.m.gifImageStill, false, 'it repeats while looping')
  item.set({ selected: false })
  item.set({ selected: true })
  item.set({ selected: false })
  assert.equal(item.data.m.gifImageStill, true, 'another tab selected: it rests')
  detach()
  delete global.wx
})

test('a GIF image reports the end of its pass (animationcomplete, the player onEnded, showsImageWhenAnimationEnds), not when another tab rests it', async () => {
  const gif = Buffer.from('R0lGODlhBAAEAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQECgAAACwAAAAABAAEAAAICQABCBxIsCCAgAAh+QQFFAABACwAAAAABAAEAIEA/wAAAAAAAAAAAAAICQABCBxIsCCAgAAh+QQFHgABACwAAAAABAAEAIEAAP8AAAAAAAAAAAAICQABCBxIsCCAgAA7', 'base64')
  global.wx = {
    getAppBaseInfo: () => ({ theme: 'light' }),
    getFileSystemManager: () => ({ readFile: ({ success }) => success({ data: gif.buffer.slice(gif.byteOffset, gif.byteOffset + gif.byteLength) }) }),
  }
  const canvas = { width: 0, height: 0, getContext: () => ({
    createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }), clearRect() {}, fillRect() {}, putImageData() {},
  }) }
  const query = { select: () => query, fields: () => query, exec: (callback) => callback([{ node: canvas }]) }
  const { item, detach } = cylMount({ image: '/shared/tab_fire.gif', drivesAnimationPlayback: false }, null, { createSelectorQuery: () => query })
  const player = item.cyl_player()
  let ended = 0
  player.onEnded(() => { ended += 1 })
  assert.equal(player.supportsLoops, true)
  player.play()
  assert.equal(player.isPlaying, true)
  assert.equal(item.data.m.gifImageStill, false, 'plays the GIF')
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(item.data.m.gifImageStill, true, 'one pass (600 ms), then the still')
  assert.equal(ended, 1, 'onEnded ran once')
  assert.equal(player.isPlaying, false)
  assert.deepEqual(item.events.filter(([name]) => name === 'animationcomplete' || name === 'animationend'), [['animationcomplete', { type: 'gif' }], ['animationend', { type: 'gif' }]])
  // Resting it by hand (stopAtProgress) or by another tab is not an end.
  player.play()
  player.stopAtProgress(0)
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(ended, 1, 'stopAtProgress is not an end')
  // Looping never ends a pass.
  player.loops = true
  player.play()
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(ended, 1, 'a looping GIF image reports no end')
  assert.equal(item.data.m.gifImageStill, false)
  item.set({ loop: false }) // the fake setData runs no observers: the property change does
  await new Promise((resolve) => setTimeout(resolve, 700))
  assert.equal(ended, 2, 'loop turned off: the pass in progress ends and reports')
  detach()
  delete global.wx
})

test('the item posts the animation moments, pauses and resumes through the engine, and stop reports once', () => {
  const { AnimationEvents } = require('../src/cyl-dealloc-block-executor/index')
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress'), cylPause: r('pause'), cylPlay: r('play') }))
  const { item } = cylMount({ animationUrl: 'a.pag', autoplay: false }, engine)
  const seen = []
  const registry = item.cylLifecycle.registry
  for (const name of Object.values(AnimationEvents)) {
    registry.addCustomCallback(name, (o, id, info) => seen.push(`${name}${info.userInfo && 'finished' in info.userInfo ? ' finished=' + info.userInfo.finished : ''}`))
  }
  item.cylOnAnimationReady()
  item.playAnimation()
  assert.equal(item.pauseAnimation(), true)
  assert.equal(item.pauseAnimation(), false, 'a second pause does nothing')
  assert.equal(item.resumeAnimation(), true)
  assert.deepEqual(engine.calls.map((c) => c[0]).filter((n) => n === 'pause' || n === 'play'), ['pause', 'play'])
  item.stopAnimation()
  item.stopAnimation()
  assert.deepEqual(seen, [
    'cyl.animation.didStart', 'cyl.animation.didPause', 'cyl.animation.didResume', 'cyl.animation.didStop finished=false',
  ])
})

test('pausesAnimationsWhileUserScrolls pauses a playing item while a scroll source is dragged and resumes it afterwards', () => {
  const { LifecycleRegistry, LifecycleCenter } = require('../src/cyl-dealloc-block-executor/index')
  const { cylPausesAnimationsWhileUserScrolls } = require('../src/cyl-animated-item/cyl_animation_events')
  const engine = cylEngine((r) => ({ cylSetProgress: r('setProgress'), cylPause: r('pause'), cylPlay: r('play') }))
  const { item } = cylMount({ animationUrl: 'a.pag', autoplay: false }, engine)
  item.cylOnAnimationReady()
  item.playAnimation()
  const page = {}
  const scroller = LifecycleRegistry.of(page)
  scroller.hookInstalled = true
  cylPausesAnimationsWhileUserScrolls(true)
  try {
    scroller.fireAutomatic('scrollWillBeginDragging', 'afterSuper')
    assert.equal(item.cylPausedByUser, true)
    scroller.fireAutomatic('scrollDidEndScrolling', 'afterSuper')
    assert.equal(item.cylPausedByUser, false)
    assert.deepEqual(engine.calls.map((c) => c[0]).filter((n) => n === 'pause' || n === 'play'), ['pause', 'play'])
  } finally {
    cylPausesAnimationsWhileUserScrolls(false)
    LifecycleCenter.reset()
    item.stopAnimation()
  }
})

test('resourcemissing names the file as configured and the reason, once per resource per item', () => {
  const engine = cylEngine(() => ({}))
  const { item } = cylMount({ animationUrl: 'icons.riv#artboard=CHAT&input=active' }, engine)
  item.cylOnAnimationError({ detail: { message: 'cyl-tab-bar: no animation component for icons.riv; install its package' } })
  item.cylOnAnimationError({ detail: { message: 'bad file' } })
  assert.deepEqual(item.events.filter(([name]) => name === 'resourcemissing'), [
    ['resourcemissing', { resource: 'icons.riv', reason: 'engine library missing' }],
  ])
  item.set({ animationUrl: 'other.riv' })
  item.cylOnAnimationError({ detail: { message: 'request:fail 404' } })
  assert.deepEqual(item.events.filter(([name]) => name === 'resourcemissing').slice(1), [
    ['resourcemissing', { resource: 'other.riv', reason: 'not found' }],
  ])
})

test('a file of no known type is reported as decode failed, inline Lottie data has no file to report', () => {
  const engine = cylEngine(() => ({}))
  const { item } = cylMount({ animationUrl: 'home.xyz' }, engine)
  assert.deepEqual(item.events, [['resourcemissing', { resource: 'home.xyz', reason: 'decode failed' }]])
  const inline = cylMount({ animationData: { v: '5.7', layers: [] } }, engine).item
  inline.cylOnAnimationError({ detail: { message: 'bad' } })
  assert.deepEqual(inline.events.filter(([name]) => name === 'resourcemissing'), [])
})

test('the drawn glass has the default tint of the current mode: white 0.04 in dark mode, frosted (225, 222, 220) 0.10 in light mode, and follows a theme change', () => {
  const { cylAnimatedItemLiquidGlassSetActiveOverride } = require('../src/cyl-animated-item/cyl_animated_item_model')
  let listener = null
  global.wx = {
    getAppBaseInfo: () => ({ theme: 'light' }),
    onThemeChange: (fn) => { listener = fn },
    offThemeChange: (fn) => { if (listener === fn) listener = null },
  }
  cylAnimatedItemLiquidGlassSetActiveOverride(true)
  try {
    const { item, detach } = cylMount({ title: 'A', itemBackgroundStyle: 'liquidGlass' }, null)
    assert.match(item.data.itemBackgroundCss, /background-color:rgba\(225,222,220,0.10\);/)
    listener({ theme: 'dark' })
    assert.match(item.data.itemBackgroundCss, /background-color:rgba\(255,255,255,0.04\);/)
    item.set({ userInterfaceStyle: 'light' })
    assert.match(item.data.itemBackgroundCss, /background-color:rgba\(225,222,220,0.10\);/, 'an explicit light style wins over the dark system theme')
    item.set({ userInterfaceStyle: 'dark' })
    assert.match(item.data.itemBackgroundCss, /background-color:rgba\(255,255,255,0.04\);/)
    detach()
  } finally {
    cylAnimatedItemLiquidGlassSetActiveOverride(false)
    delete global.wx
  }
})
