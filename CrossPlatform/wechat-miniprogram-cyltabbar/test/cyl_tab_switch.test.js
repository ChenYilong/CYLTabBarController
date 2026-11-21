/**
 * [EN] Tests of the tab switch contract (the iOS `CYLTabBar` / `CYLAnimatedItemView` behaviour): a switch stops and resets every other
 *      tab first, then the selected tab plays, so a tab switched away from mid-animation never plays next to the new one and exactly one
 *      tab looks selected. Item level: cyl-animated-item (an engine that keeps playing on a seek, like SVGA and PAG). Container level:
 *      cyl-tab-bar `cyl_syncLottie` in a small fake of the mini program `Component()` runtime. Run: `npm test`.
 * [CN] Tab 切换约定的测试（iOS 的 `CYLTabBar` / `CYLAnimatedItemView` 行为）：切换时先停止并重置其他所有 Tab，再播放选中的 Tab，
 *      因此动画途中被切走的 Tab 不会与新 Tab 同时播放，且只有一个 Tab 看起来是选中的。条目层：cyl-animated-item（使用跳转后仍继续播放的
 *      引擎，如 SVGA 与 PAG）。容器层：在模拟的小程序 `Component()` 运行时中测试 cyl-tab-bar 的 `cyl_syncLottie`。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylDefinition(relative) {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, relative)
  delete require.cache[file]
  require(file)
  delete global.Component
  return definition
}

function cylMountItem(properties, engine) {
  const definition = cylDefinition('../src/cyl-animated-item/index.js')
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
    selectComponent(id) { return id === '#cyl-animated-item-engine' ? engine : null },
    triggerEvent() {},
    set(patch) {
      this.setData(patch)
      observers.filter((o) => o.keys.some((k) => k in patch)).forEach((o) => o.fn.apply(this, o.keys.map((k) => this.data[k])))
    },
  }
  Object.assign(item, definition.methods)
  item.set(properties)
  return item
}

/** [EN] An engine like SVGA: a seek (`cyl_setProgress`) does not stop playing, only `cyl_pause` does. [CN] 类似 SVGA 的引擎：跳转不会停止播放，只有 `cyl_pause` 会。 */
function cylSeekKeepsPlayingEngine() {
  const engine = { calls: [], playing: false }
  engine.cyl_playFromStart = () => { engine.calls.push('playFromStart'); engine.playing = true }
  engine.cyl_pause = () => { engine.calls.push('pause'); engine.playing = false }
  engine.cyl_setProgress = (progress) => { engine.calls.push(`setProgress ${progress}`) }
  return engine
}

test('a tab that is no longer selected stops mid-animation and shows its resting frame', () => {
  const engine = cylSeekKeepsPlayingEngine()
  const item = cylMountItem({ animationUrl: 'a.svga', animationType: 'svga', autoplay: false, restingProgress: 0, selected: true }, engine)
  item.cyl_onAnimationReady()
  item.playAnimation()
  assert.equal(engine.playing, true)
  item.set({ selected: false })
  assert.equal(engine.playing, false, 'the engine is stopped, a seek alone would have left it playing')
  assert.deepEqual(engine.calls.slice(-2), ['pause', 'setProgress 0'], 'stopped first, then the resting frame')
})

test('a play still waiting for the file is cancelled when the tab is deselected', () => {
  const engine = cylSeekKeepsPlayingEngine()
  const item = cylMountItem({ animationUrl: 'a.svga', animationType: 'svga', autoplay: false, selected: true }, engine)
  item.playAnimation()
  assert.equal(item.cylPendingPlay, true)
  item.set({ selected: false })
  assert.equal(item.cylPendingPlay, false)
  item.cyl_onAnimationReady()
  assert.equal(engine.calls.includes('playFromStart'), false, 'the late `ready` of a deselected tab plays nothing')
})

test('a tab that loops while unselected keeps looping (autoplay)', () => {
  const engine = cylSeekKeepsPlayingEngine()
  const item = cylMountItem({ animationUrl: 'a.svga', animationType: 'svga', autoplay: true, loop: true, selected: true }, engine)
  item.cyl_onAnimationReady()
  item.set({ selected: false })
  assert.equal(engine.calls.includes('pause'), false)
})

test('Rive, which has no seek, is stopped through cyl_stop', () => {
  const calls = []
  const engine = { cyl_pause: () => calls.push('pause'), cyl_stop: () => calls.push('stop'), cyl_playFromStart: () => calls.push('play') }
  const item = cylMountItem({ animationUrl: 'a.riv', animationType: 'rive', autoplay: false, selected: true }, engine)
  item.cyl_onAnimationReady()
  calls.length = 0
  item.set({ selected: false })
  assert.deepEqual(calls, ['pause', 'stop'])
})

function cylMountBar(identifiers, loopers) {
  const definition = cylDefinition('../src/cyl-tab-bar/index.js')
  const log = []
  const items = {}
  identifiers.forEach((id) => {
    items[`#cyl-item-${id}`] = {
      cyl_stopAnimation: () => log.push(`stop ${id}`),
      cyl_playAnimation: () => log.push(`play ${id}`),
    }
  })
  const bar = {
    cylModel: {
      context: 'test',
      items: identifiers.map((identifier) => ({ identifier, lottie: { loopsWhenUnselected: (loopers || []).includes(identifier) } })),
    },
    selectComponent: (id) => items[id] || null,
  }
  Object.assign(bar, definition.methods)
  return { bar, log }
}

test('tap A, then B during A\'s animation: A is stopped before B plays, and only B plays', () => {
  const { bar, log } = cylMountBar(['a', 'b', 'c'])
  bar.cyl_syncLottie('a')
  bar.cyl_syncLottie('b')
  assert.deepEqual(log, ['stop a', 'stop c', 'play b'], 'every other tab is stopped first, then the selected one plays')
})

test('two quick taps (A, B, A): the last selected tab plays and every other tab was stopped before each play', () => {
  const { bar, log } = cylMountBar(['a', 'b'])
  bar.cyl_syncLottie('a')
  bar.cyl_syncLottie('b')
  bar.cyl_syncLottie('a')
  assert.deepEqual(log, ['stop a', 'play b', 'stop b', 'play a'])
})

test('a tab that loops while unselected is not stopped by a switch', () => {
  const { bar, log } = cylMountBar(['a', 'b', 'c'], ['c'])
  bar.cyl_syncLottie('a')
  bar.cyl_syncLottie('b')
  assert.deepEqual(log, ['stop a', 'play b'])
})

test('exactly one slot is selected after a switch (selection comes from one identifier)', () => {
  const definition = cylDefinition('../src/cyl-tab-bar/index.js')
  assert.equal(typeof definition.methods.cyl_slot, 'function')
  const model = { isDark: false, items: ['a', 'b', 'c'].map((identifier) => ({ identifier, title: identifier, image: 'x.png', selectedImage: 'y.png' })) }
  const context = { cylModel: model, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {}, data: {}, ...definition.methods }
  const selectedCount = (selected) => model.items.filter((item) => context.cyl_slot(item, selected).selected === true).length
  assert.equal(selectedCount('b'), 1)
  assert.equal(selectedCount('a'), 1)
})

test('a bar shown after a tap draws the tapped tab at once, not its own stale selection', () => {
  const definition = cylDefinition('../src/cyl-tab-bar/index.js')
  assert.equal(typeof definition.pageLifetimes.show, 'function')
  const sent = []
  const model = { context: 'flicker', items: [{ identifier: 'a' }, { identifier: 'b' }] }
  const tapped = { cylModel: model, data: { selectedIdentifier: 'a' }, setData(patch) { sent.push(patch) }, ...definition.methods }
  tapped.cylLongPressed = false
  tapped.cyl_recordTap = () => {}
  tapped.cyl_playTapAnimation = () => {}
  tapped.cyl_playTabButtonTapFeedback = () => {}
  tapped.triggerEvent = () => {}
  tapped.data.cylSlots = [{ key: 'a' }, { key: 'b' }]
  tapped.data.loggedIn = true
  model.loginRequiredIdentifiers = []
  tapped.cyl_onTap({ type: 'tap', currentTarget: { dataset: { key: 'b' } } })
  const cached = { cylModel: model, data: { selectedIdentifier: 'a' }, setData(patch) { sent.push(patch) } }
  definition.pageLifetimes.show.call(cached)
  assert.deepEqual(sent[sent.length - 1], { selectedIdentifier: 'b' })
})
