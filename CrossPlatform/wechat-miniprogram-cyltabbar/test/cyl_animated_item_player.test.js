/**
 * [EN] The engine contract of HarmonyOS in the mini program (docs/Animated-Item.md, "Engine API across platforms"): the player
 *      (`cyl_animated_item_player.js`, a pure class) with a fake host, then `cyl_player()` of cyl-animated-item over fake engine
 *      components in a small fake of the mini program `Component()` runtime: the members, host-driven mode
 *      (`drivesAnimationPlayback` false applies none of the default rules) and `restartToken`. Run: `npm test`.
 * [CN] 鸿蒙的引擎约定在小程序中的实现（docs/Animated-Item.md「Engine API across platforms」）：先用模拟宿主测试播放器
 *      （`cyl_animated_item_player.js`，纯类），再在模拟的小程序 `Component()` 运行时中，用模拟的引擎组件测试 cyl-animated-item 的
 *      `cyl_player()`：各成员、宿主驱动模式（`drivesAnimationPlayback` 为 false 时不应用任何默认规则）与 `restartToken`。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { CYLAnimatedItemPlayer, cylPlayerColors } = require('../src/cyl-animated-item/cyl_animated_item_player')

function cylFakeHost(type, extra) {
  const state = { speed: 1, loop: false, colors: null }
  const log = []
  const host = {
    state,
    log,
    engine: () => null,
    type: () => type,
    usesLoop: () => type !== 'gif',
    isPlaying: () => false,
    get: (name) => state[name],
    set: (patch) => { Object.assign(state, patch); log.push(['set', patch]) },
    play: () => log.push(['play']),
    stopAtProgress: (progress) => log.push(['stopAtProgress', progress]),
    ...extra,
  }
  return host
}

test('what each type supports, before any engine is ready', () => {
  const answers = (type) => {
    const player = new CYLAnimatedItemPlayer(cylFakeHost(type))
    return [player.supportsSpeed, player.supportsLoops, player.supportsProgress, player.supportsColors]
  }
  assert.deepEqual(answers('lottie'), [true, true, true, true])
  assert.deepEqual(answers('pag'), [true, true, true, false])
  assert.deepEqual(answers('svga'), [true, true, true, false])
  assert.deepEqual(answers('rive'), [true, true, false, true], 'Rive has no seek')
  assert.deepEqual(answers('gif'), [false, false, false, false], 'a GIF with no stills cannot loop')
  assert.deepEqual(answers(''), [false, true, false, false], 'no animation: only the item decides loops')
})

test('speed reads and writes the item, 0 or less is 1, and a GIF has none', () => {
  const host = cylFakeHost('svga')
  const player = new CYLAnimatedItemPlayer(host)
  assert.equal(player.speed, 1)
  player.speed = 2.5
  assert.equal(player.speed, 2.5)
  player.speed = 0
  assert.equal(host.state.speed, 1)
  const gif = cylFakeHost('gif')
  const gifPlayer = new CYLAnimatedItemPlayer(gif)
  gifPlayer.speed = 3
  assert.deepEqual(gif.log, [], 'a no-op without supportsSpeed')
})

test('loops reads and writes the item `loop`, and is a no-op where the item cannot loop', () => {
  const host = cylFakeHost('pag')
  const player = new CYLAnimatedItemPlayer(host)
  assert.equal(player.loops, false)
  player.loops = true
  assert.equal(host.state.loop, true)
  assert.equal(player.loops, true)
  const gif = cylFakeHost('gif')
  new CYLAnimatedItemPlayer(gif).loops = true
  assert.deepEqual(gif.log, [])
})

test('play and stopAtProgress go to the item; progress is clamped, nonsense is 0', () => {
  const host = cylFakeHost('lottie')
  const player = new CYLAnimatedItemPlayer(host)
  player.play()
  player.stopAtProgress(0.4)
  player.stopAtProgress(7)
  player.stopAtProgress(-1)
  player.stopAtProgress('x')
  assert.deepEqual(host.log, [['play'], ['stopAtProgress', 0.4], ['stopAtProgress', 1], ['stopAtProgress', 0], ['stopAtProgress', 0]])
})

test('isPlaying is the item\'s', () => {
  let playing = false
  const player = new CYLAnimatedItemPlayer(cylFakeHost('pag', { isPlaying: () => playing }))
  assert.equal(player.isPlaying, false)
  playing = true
  assert.equal(player.isPlaying, true)
})

test('onEnded: one callback, replaced by the next, removable, cleared by null and destroy', () => {
  const player = new CYLAnimatedItemPlayer(cylFakeHost('pag'))
  const calls = []
  const remove = player.onEnded(() => calls.push('a'))
  player.didEnd()
  player.onEnded(() => calls.push('b'))
  remove()
  player.didEnd()
  assert.deepEqual(calls, ['a', 'b'], 'a removed callback that was already replaced does not remove the new one')
  player.onEnded(null)
  player.didEnd()
  player.onEnded(() => calls.push('c'))
  player.destroy()
  player.didEnd()
  assert.deepEqual(calls, ['a', 'b'])
})

test('applyColors takes a Map or an object, undefined restores, and PAG ignores it', () => {
  const host = cylFakeHost('rive')
  const player = new CYLAnimatedItemPlayer(host)
  player.applyColors(new Map([['Shape.Fill 1', '#FF0000']]))
  assert.deepEqual(host.state.colors, { 'Shape.Fill 1': '#FF0000' })
  player.applyColors({ a: '#00FF00' })
  assert.deepEqual(host.state.colors, { a: '#00FF00' })
  player.applyColors(undefined)
  assert.equal(host.state.colors, null)
  assert.equal(cylPlayerColors(new Map()), null)
  const pag = cylFakeHost('pag')
  new CYLAnimatedItemPlayer(pag).applyColors({ a: '#FFFFFF' })
  assert.deepEqual(pag.log, [])
})

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
    events: [],
    setData(patch, callback) {
      Object.entries(patch).forEach(([key, value]) => {
        if (key.startsWith('m.')) this.data.m = { ...this.data.m, [key.slice(2)]: value }
        else this.data[key] = value
      })
      if (callback) callback()
    },
    selectComponent: (id) => (id === '#cyl-animated-item-engine' ? engine : null),
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

function cylEngine(names) {
  const calls = []
  const engine = { calls }
  names.forEach((name) => { engine[name] = (...args) => calls.push([name.replace(/^cyl_/, '').replace(/^cyl([A-Z])/, (match, letter) => letter.toLowerCase()), ...args]) })
  return engine
}

const cylSeekEngine = () => cylEngine(['cylPlayFromStart', 'cylPause', 'cylSetProgress', 'cylStop', 'cylSetSpeed'])

test('cyl_player() is one object per item and plays through the engine once ready', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, selected: false }, engine)
  const player = item.cyl_player()
  assert.equal(item.cyl_player(), player)
  assert.equal(player.type, 'svga')
  player.play()
  assert.equal(player.isPlaying, true, 'a play waiting for the file counts')
  assert.deepEqual(engine.calls, [])
  item.cylOnAnimationReady()
  assert.deepEqual(engine.calls, [['playFromStart']])
})

test('stopAtProgress pauses first, then seeks, and isPlaying turns false (SVGA and PAG keep playing on a seek alone)', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.pag', autoplay: false }, engine)
  item.cylOnAnimationReady()
  const player = item.cyl_player()
  player.play()
  engine.calls.length = 0
  player.stopAtProgress(0.5)
  assert.deepEqual(engine.calls, [['pause'], ['setProgress', 0.5]])
  assert.equal(player.isPlaying, false)
  assert.equal(player.supportsProgress, true)
})

test('Lottie seeks through cylGoToAndStop, Rive rests through cylStop', () => {
  const lottie = cylEngine(['cylPause', 'cylGoToAndStop'])
  lottie.cyl_animation = () => ({ totalFrames: 11 })
  const a = cylMount({ animationData: { v: '5', layers: [] }, autoplay: false }, lottie)
  a.item.cylOnAnimationReady()
  lottie.calls.length = 0
  a.item.cyl_player().stopAtProgress(0.3)
  assert.deepEqual(lottie.calls, [['pause'], ['goToAndStop', 3, true]])
  const rive = cylEngine(['cylPause', 'cylStop'])
  const b = cylMount({ animationUrl: 'a.riv', autoplay: false }, rive)
  b.item.cylOnAnimationReady()
  rive.calls.length = 0
  assert.equal(b.item.cyl_player().supportsProgress, false)
  b.item.cyl_player().stopAtProgress(0.3)
  assert.deepEqual(rive.calls, [['pause'], ['stop']])
})

test('speed, loops and colors go to the item properties that the engine receives', () => {
  const { item } = cylMount({ animationUrl: 'a.json', autoplay: false }, cylSeekEngine())
  const player = item.cyl_player()
  player.speed = 2
  player.loops = true
  player.applyColors(new Map([['k', '#112233']]))
  assert.equal(item.data.speed, 2)
  assert.equal(item.data.loop, true)
  assert.deepEqual(item.data.colors, { k: '#112233' })
  assert.equal(player.speed, 2)
  assert.equal(player.loops, true)
  player.applyColors(undefined)
  assert.equal(item.data.colors, null)
})

test('onEnded runs when a play-once pass completes, with animationcomplete still forwarded; a looping pass does not end', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false }, engine)
  item.cylOnAnimationReady()
  const player = item.cyl_player()
  let ended = 0
  player.onEnded(() => { ended++ })
  player.play()
  assert.equal(player.isPlaying, true)
  item.cylOnAnimationComplete({ detail: { type: 'svga' } })
  assert.equal(ended, 1)
  assert.equal(player.isPlaying, false)
  assert.deepEqual(item.events.filter(([name]) => name === 'animationcomplete' || name === 'animationend'), [['animationcomplete', { type: 'svga' }], ['animationend', { type: 'svga' }]])
  player.play()
  item.cylOnAnimationLoopComplete({ detail: {} })
  assert.equal(ended, 1)
  assert.equal(player.isPlaying, true)
})

test('a timed GIF pass ends through the player too, and a GIF has no speed', () => {
  const { item } = cylMount({ animationUrl: 'a.gif', gifFirstFrame: 'f.png', gifLastFrame: 'l.png', gifDuration: 10, autoplay: false }, null)
  const player = item.cyl_player()
  assert.equal(player.type, 'gif')
  assert.equal(player.supportsSpeed, false)
  assert.equal(player.supportsLoops, true)
  return new Promise((resolve) => {
    player.onEnded(() => { assert.equal(player.isPlaying, false); resolve() })
    player.play()
    assert.equal(player.isPlaying, true)
  })
})

test('the default rules still play and rest through the same item (drivesAnimationPlayback on)', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, selected: false }, engine)
  item.cylOnAnimationReady()
  engine.calls.length = 0
  item.set({ selected: true })
  assert.deepEqual(engine.calls, [['setProgress', 1]])
})

test('restartToken restarts when it grows, not at creation, when lower or while it stays the same', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, restartToken: 5 }, engine)
  item.cylOnAnimationReady()
  engine.calls.length = 0
  item.set({ restartToken: 5 })
  item.set({ restartToken: 3 })
  assert.deepEqual(engine.calls, [])
  item.set({ restartToken: 6 })
  assert.deepEqual(engine.calls, [['playFromStart']])
  item.set({ restartToken: 6 })
  item.set({ restartToken: 9 })
  assert.deepEqual(engine.calls, [['playFromStart'], ['playFromStart']])
})

test('restartToken from the default 0 restarts at 1 (the first change after creation counts)', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false }, engine)
  item.cylOnAnimationReady()
  engine.calls.length = 0
  item.set({ restartToken: 1 })
  assert.deepEqual(engine.calls, [['playFromStart']])
})

test('animationRestartToken is the same as restartToken: growth of either one restarts', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false }, engine)
  item.cylOnAnimationReady()
  engine.calls.length = 0
  item.set({ animationRestartToken: 1 })
  assert.deepEqual(engine.calls, [['playFromStart']])
  item.set({ animationRestartToken: 1 })
  item.set({ animationRestartToken: 0 })
  assert.deepEqual(engine.calls, [['playFromStart']])
  item.set({ restartToken: 1 })
  assert.deepEqual(engine.calls, [['playFromStart'], ['playFromStart']])
})

test('host-driven: a selection change, the ready of the engine and restartToken apply none of the default rules', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, drivesAnimationPlayback: false, selected: false }, engine)
  item.cylOnAnimationReady()
  item.set({ selected: true })
  item.set({ selected: false })
  item.set({ restingProgress: 0.7 })
  item.set({ restartToken: 4 })
  assert.deepEqual(engine.calls, [], 'no engine call at all')
  assert.equal(item.data.m.restingFrame, 'first', 'the engine\'s own resting frame does not follow `selected` either')
})

test('host-driven: loop and speed from the host reach the engine, play and stop work, and a pending play is kept', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: true, drivesAnimationPlayback: false, selected: true }, engine)
  const player = item.cyl_player()
  player.play()
  item.cylOnAnimationReady()
  assert.deepEqual(engine.calls, [['playFromStart']], 'the host\'s own play waited for the file and ran; nothing else did')
  engine.calls.length = 0
  player.stopAtProgress(1)
  assert.deepEqual(engine.calls, [['pause'], ['setProgress', 1]])
  assert.equal(item.data.m.restingFrame, 'last', 'the resting frame follows the progress the host stopped at')
  player.stopAtProgress(0)
  assert.equal(item.data.m.restingFrame, 'first')
})

test('host-driven: playAnimation(), restartAnimation() and stopAnimation() still do what they are called for', () => {
  const engine = cylSeekEngine()
  const { item } = cylMount({ animationUrl: 'a.svga', autoplay: false, drivesAnimationPlayback: false }, engine)
  item.cylOnAnimationReady()
  item.restartAnimation()
  assert.deepEqual(engine.calls, [['playFromStart']])
})

test('the engine never autoplays by itself in host-driven mode (wxml)', () => {
  const wxml = fs.readFileSync(path.join(__dirname, '../src/cyl-animated-item/index.wxml'), 'utf8')
  const engines = wxml.match(/<cyl-(lottie|pag|rive|svga)-view [^>]*>/g)
  assert.equal(engines.length, 4)
  engines.forEach((tag) => assert.match(tag, /autoplay="\{\{autoplay && drivesAnimationPlayback\}\}"/))
})

test('detach drops the onEnded callback', () => {
  const engine = cylSeekEngine()
  const { item, detach } = cylMount({ animationUrl: 'a.svga', autoplay: false }, engine)
  item.cylOnAnimationReady()
  let ended = 0
  item.cyl_player().onEnded(() => { ended++ })
  detach()
  item.cylOnAnimationComplete({})
  assert.equal(ended, 0)
})
