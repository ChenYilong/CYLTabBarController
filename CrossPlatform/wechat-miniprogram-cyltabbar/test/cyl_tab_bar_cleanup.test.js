/**
 * [EN] Tests of the cleanup of cyl-tab-bar: each resource (the theme listener, the live-bar entry, the tap animation timer) registers
 *      its own keyed dealloc callback (CYLDeallocBlockExecutor) where it is created, and `detached` runs them once. Run: `npm test`.
 * [CN] cyl-tab-bar 清理逻辑的测试：每个资源（主题监听、存活 TabBar 记录、点击动画定时器）在创建处注册各自带 key 的 willDealloc 回调
 *      （CYLDeallocBlockExecutor），`detached` 时运行一次。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylDefinition() {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  return definition
}

function cylMount(definition, model) {
  const bar = { cylModel: model, sent: [], data: { selectedIdentifier: 'home', loggedIn: true, cylSlots: [{ key: 'home' }, { key: 'message' }] } }
  Object.assign(bar, definition.methods)
  bar.setData = (patch, callback) => { bar.sent.push(patch); Object.assign(bar.data, patch); if (callback) callback() }
  bar.cyl_render = () => {}
  bar.cyl_playTabButtonTapFeedback = () => {}
  bar.triggerEvent = () => {}
  bar.cylLongPressed = false
  definition.lifetimes.attached.call(bar)
  return bar
}

test('detached removes the theme listener once, and the controller is then detached', () => {
  const listeners = []
  global.wx = {
    getSystemInfoSync: () => ({ theme: 'light' }),
    getAppBaseInfo: () => ({ theme: 'light' }),
    onThemeChange: (fn) => listeners.push(fn),
    offThemeChange: (fn) => listeners.splice(listeners.indexOf(fn), 1),
  }
  const definition = cylDefinition()
  const bar = cylMount(definition, { context: 'cleanup', items: [{ identifier: 'home' }], loginRequiredIdentifiers: [] })
  assert.equal(listeners.length, 1)
  assert.equal(listeners[0], bar.cylThemeListener)
  definition.lifetimes.detached.call(bar)
  assert.equal(listeners.length, 0, 'the theme listener is removed')
  definition.lifetimes.detached.call(bar)
  assert.equal(listeners.length, 0, 'a second detached does nothing')
  assert.equal(bar.cylLifecycle.isDetached, true, 'the controller is detached: new cleanups are not registered')
  delete global.wx
})

test('detached takes the bar out of the live bars: a tap on another bar no longer selects in it', () => {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  const definition = cylDefinition()
  const model = { context: 'live-cleanup', items: [{ identifier: 'home' }, { identifier: 'message' }], loginRequiredIdentifiers: [] }
  const shown = cylMount(definition, model)
  const detached = cylMount(definition, model)
  definition.lifetimes.detached.call(detached)
  shown.cyl_onTap({ type: 'tap', currentTarget: { dataset: { key: 'message' } } })
  assert.equal(detached.data.selectedIdentifier, 'home')
  definition.lifetimes.detached.call(shown)
  delete global.wx
})

test('detached clears the tap animation timer; a new timer replaces the keyed cleanup', () => {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  const definition = cylDefinition()
  const model = { context: 'timer-cleanup', tapAnimation: 'bounce', animationDuration: 300, items: [{ identifier: 'home' }], loginRequiredIdentifiers: [] }
  const bar = cylMount(definition, model)
  const realSet = global.setTimeout
  const realClear = global.clearTimeout
  const cleared = []
  let next = 100
  global.setTimeout = () => ++next
  global.clearTimeout = (handle) => { cleared.push(handle) }
  try {
    bar.cyl_playTapAnimation('home')
    bar.cyl_playTapAnimation('home')
    assert.equal(bar.cylAnimationTimer, 102)
    cleared.length = 0
    definition.lifetimes.detached.call(bar)
    assert.deepEqual(cleared, [102], 'only the current timer is cleared, once')
  } finally {
    global.setTimeout = realSet
    global.clearTimeout = realClear
  }
  delete global.wx
})
