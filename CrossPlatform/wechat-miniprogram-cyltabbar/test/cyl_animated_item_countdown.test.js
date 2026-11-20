/**
 * [EN] Tests of the countdown of cyl-animated-item: the state machine (src/cyl-animated-item/cyl_animated_item_countdown.js)
 *      on a clock the tests move, the render model, and the component in a small fake of the mini program `Component()`
 *      runtime. The same cases as iOS `CYLAnimatedItemCountdownTests` and Android `CYLAnimatedItemCountdownTest`. Run: `npm test`.
 * [CN] cyl-animated-item 倒计时的测试：在由测试拨动的时钟上测试状态机、渲染模型，以及在模拟的小程序 `Component()` 运行时中测试组件。
 *      用例与 iOS 的 `CYLAnimatedItemCountdownTests`、Android 的 `CYLAnimatedItemCountdownTest` 相同。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')
const { CYLAnimatedItemCountdown, cylCountdownText } = require('../src/cyl-animated-item/cyl_animated_item_countdown')
const { cylAnimatedItemModel, cylAnimatedItemCountdownTitleWidth } = require('../src/cyl-animated-item/cyl_animated_item_model')

function cylClock(seconds) {
  const clock = { ms: seconds * 1000, now: () => clock.ms, set(s) { clock.ms = s * 1000 } }
  return clock
}

function cylStorage() {
  const values = new Map()
  return { values, get: (n) => values.get(n), set: (n, v) => values.set(n, v), remove: (n) => values.delete(n) }
}

function cylCountdown(clock, storage, key) {
  const events = []
  const countdown = new CYLAnimatedItemCountdown({
    now: clock.now,
    storage,
    onStart: () => events.push('start'),
    onTick: (s) => events.push(`tick ${s}`),
    onFinish: () => events.push('finish'),
  })
  if (key) countdown.setCacheKey(key)
  return { countdown, events }
}

test('the text replaces %ld and %d', () => {
  assert.equal(cylCountdownText('%ld s left', 14), '14 s left')
  assert.equal(cylCountdownText('还剩%d秒', 9), '还剩9秒')
})

test('the seconds spent in the background count (issue #1)', () => {
  const clock = cylClock(1000)
  const { countdown, events } = cylCountdown(clock)
  countdown.startFor(10)
  assert.equal(countdown.state, 'running')
  assert.equal(countdown.remainingSeconds, 10)
  clock.set(1004)
  countdown.refresh()
  assert.equal(countdown.shown, 6)
  clock.set(1020)
  countdown.refresh()
  assert.equal(countdown.state, 'finished')
  assert.deepEqual(events, ['start', 'tick 10', 'tick 6', 'finish'])
})

test('it ticks once per second and finishes exactly', () => {
  const clock = cylClock(500)
  const { countdown, events } = cylCountdown(clock)
  countdown.startFor(3)
  clock.set(500.4); countdown.refresh()
  clock.set(500.9); countdown.refresh()
  assert.equal(countdown.shown, 3)
  clock.set(501.1); countdown.refresh()
  assert.equal(countdown.shown, 2)
  clock.set(503); countdown.refresh()
  assert.equal(countdown.state, 'finished')
  countdown.refresh()
  assert.deepEqual(events, ['start', 'tick 3', 'tick 2', 'finish'])
})

test('a clock set back to before the start closes the countdown', () => {
  const clock = cylClock(10000)
  const { countdown } = cylCountdown(clock)
  countdown.startFor(60)
  clock.set(5000)
  countdown.refresh()
  assert.equal(countdown.state, 'finished')
  countdown.startFor(60)
  assert.equal(countdown.state, 'running', 'a new countdown can start')
})

test('a reset is not a finish', () => {
  const clock = cylClock(0)
  const { countdown, events } = cylCountdown(clock)
  countdown.startFor(30)
  countdown.reset()
  assert.equal(countdown.state, 'idle')
  assert.equal(events.includes('finish'), false)
})

test('a cached countdown is taken up again by a new countdown, with no start event', () => {
  const clock = cylClock(1000)
  const storage = cylStorage()
  cylCountdown(clock, storage, 'sms-code').countdown.startFor(60)
  clock.set(1042)
  const { countdown, events } = cylCountdown(clock, storage, 'sms-code')
  assert.equal(countdown.state, 'running')
  assert.equal(countdown.shown, 18)
  assert.deepEqual(events, ['tick 18'])
})

test('an expired, finished, reset or future cache is not taken up', () => {
  const storage = cylStorage()
  const clock = cylClock(1000)
  cylCountdown(clock, storage, 'k').countdown.startFor(60)
  clock.set(2000)
  assert.equal(cylCountdown(clock, storage, 'k').countdown.state, 'idle')
  assert.equal(storage.values.size, 0, 'the expired cache is dropped')

  clock.set(3000)
  const second = cylCountdown(clock, storage, 'k').countdown
  second.startFor(60)
  second.reset()
  assert.equal(cylCountdown(clock, storage, 'k').countdown.state, 'idle')

  const third = cylCountdown(clock, storage, 'k').countdown
  third.startFor(60)
  clock.set(3061)
  third.refresh()
  assert.equal(cylCountdown(clock, storage, 'k').countdown.state, 'idle')

  clock.set(10000)
  cylCountdown(clock, storage, 'k').countdown.startFor(60)
  clock.set(2000)
  assert.equal(cylCountdown(clock, storage, 'k').countdown.state, 'idle', 'the clock was set back')
})

test('the model: titles, icon, disabled while running, one width for every title', () => {
  const base = {
    itemStyle: 'countdown', countdownIdleTitle: 'Get code', countdownRunningTitleFormat: '%ld s left', countdownFinishedTitle: 'Resend',
    image: 'envelope.png', countdownImage: 'clock.png', countdownDuration: 60,
  }
  const idle = cylAnimatedItemModel({ ...base, countdownState: 'idle' })
  assert.equal(idle.title, 'Get code')
  assert.equal(idle.fallbackImage, 'envelope.png')
  assert.equal(idle.ariaDisabled, false)
  assert.match(idle.axisClass, /cyl-animated-item-countdown/)

  const running = cylAnimatedItemModel({ ...base, countdownState: 'running', countdownSeconds: 14 })
  assert.equal(running.title, '14 s left')
  assert.equal(running.fallbackImage, 'clock.png')
  assert.equal(running.ariaDisabled, true)
  assert.equal(running.ariaLabel, '14 s left')
  assert.match(running.titleStyle, /color: #999999/)

  const finished = cylAnimatedItemModel({ ...base, countdownState: 'finished' })
  assert.equal(finished.title, 'Resend')
  assert.equal(finished.fallbackImage, 'envelope.png')

  const width = cylAnimatedItemCountdownTitleWidth(base)
  assert.ok(width > 0)
  for (const m of [idle, running, finished]) assert.ok(m.titleStyle.includes(`min-width: ${width}px`))
  assert.equal(cylAnimatedItemCountdownTitleWidth({ ...base, itemStyle: 'plain' }), 0)
  assert.equal(cylAnimatedItemModel({ title: 'Home' }).title, 'Home', 'the plain style is unchanged')
})

function cylMount(properties, clock, storage) {
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
    selectComponent: () => null,
    triggerEvent(name, detail) { this.events.push([name, detail]) },
    set(patch) {
      this.setData(patch)
      observers.filter((o) => o.keys.some((k) => k in patch)).forEach((o) => o.fn.apply(this, o.keys.map((k) => this.data[k])))
    },
  }
  Object.assign(item, definition.methods)
  const listeners = []
  global.wx = {
    onAppShow: (f) => listeners.push(f),
    offAppShow: () => {},
    getStorageSync: (n) => storage.get(n),
    setStorageSync: (n, v) => storage.set(n, v),
    removeStorageSync: (n) => storage.remove(n),
    getAppBaseInfo: () => ({ theme: 'light' }),
  }
  const realNow = Date.now
  Date.now = clock.now
  item.set(properties)
  definition.lifetimes.attached.call(item)
  return { item, showApp: () => listeners.forEach((f) => f()), detach: () => { definition.lifetimes.detached.call(item); Date.now = realNow; delete global.wx } }
}

test('the component: a tap starts the countdown, the app shown again reads the clock, the item is usable again at the end', () => {
  const clock = cylClock(1000)
  const { item, showApp, detach } = cylMount({ itemStyle: 'countdown', startsCountdownOnTap: true, countdownDuration: 60, countdownCacheKey: 'sms' }, clock, cylStorage())
  assert.equal(item.data.m.title, 'Get code')
  item.cyl_onTap()
  assert.equal(item.data.countdownState, 'running')
  assert.equal(item.data.m.title, '60 s left')
  assert.equal(item.data.m.ariaDisabled, true)
  item.cyl_onTap()
  assert.deepEqual(item.events.map((e) => e[0]), ['itemtap', 'countdownstart', 'countdowntick'], 'a running countdown takes no tap')

  clock.set(1046)
  showApp()
  assert.equal(item.data.m.title, '14 s left')
  clock.set(1060)
  showApp()
  assert.equal(item.data.countdownState, 'finished')
  assert.equal(item.data.m.title, 'Resend')
  assert.equal(item.data.m.ariaDisabled, false)
  assert.equal(item.events.at(-1)[0], 'countdownfinish')
  detach()
})

test('the component: a new item with the same cache key continues after a restart', () => {
  const clock = cylClock(1000)
  const storage = cylStorage()
  const first = cylMount({ itemStyle: 'countdown', countdownCacheKey: 'sms' }, clock, storage)
  first.item.startCountdown(60)
  first.detach()
  clock.set(1042)
  const second = cylMount({ itemStyle: 'countdown', countdownCacheKey: 'sms' }, clock, storage)
  assert.equal(second.item.data.countdownState, 'running')
  assert.equal(second.item.data.m.title, '18 s left')
  second.item.resetCountdown()
  second.detach()
})
