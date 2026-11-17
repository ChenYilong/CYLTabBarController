/**
 * [EN] The Rive loop (docs/Animated-Item.md, "the Rive engine has no loop logic"): a play always plays again (a held input,
 *      a state machine whose input is missing, a trigger), and `loop` repeats every kind. The pure helpers, then the
 *      component's play and loop with a fake Rive runtime (no mini program runtime, no WebAssembly).
 * [CN] Rive 循环（docs/Animated-Item.md，"Rive 引擎没有循环逻辑"）：每次播放都会再次播放（保持的输入、缺少输入的状态机、trigger），`loop` 会重复每种
 *      播放方式。先测试纯函数，再用伪造的 Rive 运行时测试组件的播放与循环（不需要小程序运行时与 WebAssembly）。
 */
const test = require('node:test')
const assert = require('node:assert')
const { cylRivePlayKind, cylRiveLoopDelay, CYL_RIVE_LOOP_SECONDS } = require('../miniprogram_dist/cyl-rive/cyl_rive_options')

test('what a play does: trigger, view model trigger, input off then on, else a restart', () => {
  assert.equal(cylRivePlayKind({ hasTriggerInput: true, hasBoolInput: true }), 'trigger')
  assert.equal(cylRivePlayKind({ hasViewModelTrigger: true }), 'viewModelTrigger')
  assert.equal(cylRivePlayKind({ hasBoolInput: true }), 'input')
  assert.equal(cylRivePlayKind({}), 'restart', 'a missing or absent input restarts the state machine')
})

test('the loop delay: after the input goes back to false, else the animation, else a fixed pass; by speed', () => {
  assert.equal(cylRiveLoopDelay({ kind: 'input', duration: 1, speed: 1 }), 1400)
  assert.equal(cylRiveLoopDelay({ kind: 'input', duration: 0, speed: 1 }), CYL_RIVE_LOOP_SECONDS * 1000, 'a held input')
  assert.equal(cylRiveLoopDelay({ kind: 'restart', animationSeconds: 2, speed: 2 }), 1000)
  assert.equal(cylRiveLoopDelay({ kind: 'trigger', duration: 1, speed: 1 }), 1400)
  assert.equal(cylRiveLoopDelay({ kind: 'restart', duration: 0 }), CYL_RIVE_LOOP_SECONDS * 1000)
})

/** [EN] Loads cyl-rive's Component definition with stubs for the mini program globals. [CN] 用小程序全局对象的桩加载 cyl-rive 的 Component 定义。 */
function loadComponent() {
  let definition = null
  global.Component = (options) => { definition = options }
  global.wx = global.wx || { getSystemInfoSync: () => ({ platform: 'ios' }), getDeviceInfo: () => ({ platform: 'ios' }) }
  delete require.cache[require.resolve('../miniprogram_dist/cyl-rive/index.js')]
  require('../miniprogram_dist/cyl-rive/index.js')
  delete global.Component
  return definition
}

/** [EN] A component instance over a fake state (inputs by name, state machine instances counted). [CN] 基于伪造状态的组件实例。 */
function makeItem(definition, { inputs = {}, isStateMachine = true, duration = 1, loop = false, options = {} }) {
  const created = []
  const makeInstance = () => {
    const instance = {
      deleted: false,
      inputCount: () => Object.keys(inputs).length,
      input: (index) => inputs[Object.keys(inputs)[index]],
      advance: () => {},
      delete() { this.deleted = true },
      time: 3,
    }
    created.push(instance)
    return instance
  }
  const rive = { StateMachineInstance: function () { return makeInstance() } }
  const item = { data: { loop, speed: 1 }, events: [], triggerEvent(name) { this.events.push(name) } }
  Object.assign(item, definition.methods)
  item.cylState = { rive, artboard: {}, machine: isStateMachine ? {} : null, isStateMachine, instance: makeInstance(),
    options: { duration, ...options }, playing: true, animationSeconds: 0 }
  item.setLoop = (value) => { item.data.loop = value; definition.observers.loop.call(item, value) }
  return { item, created }
}

function boolInput(name) {
  const input = { name, history: [], value: false }
  input.asBool = () => ({ set value(v) { input.value = v; input.history.push(v) }, get value() { return input.value } })
  return input
}

test('a held input (duration 0) plays again: each play turns it off, then on', () => {
  const definition = loadComponent()
  const isOpen = boolInput('isOpen')
  const { item } = makeItem(definition, { inputs: { isOpen }, duration: 0, options: { input: 'isOpen' } })
  item.cyl_playFromStart()
  item.cyl_playFromStart()
  assert.deepEqual(isOpen.history, [false, true, false, true], 'two plays, two transitions to true')
})

test('a state machine without the named input restarts on every play (house.riv: no "active")', () => {
  const definition = loadComponent()
  const { item, created } = makeItem(definition, { inputs: {}, options: { input: 'active' } })
  const first = item.cylState.instance
  item.cyl_playFromStart()
  assert.notEqual(item.cylState.instance, first, 'a new state machine instance')
  assert.equal(first.deleted, true, 'the old one is released')
  item.cyl_playFromStart()
  assert.equal(created.length, 3)
})

test('a linear animation goes back to its start', () => {
  const definition = loadComponent()
  const { item } = makeItem(definition, { isStateMachine: false })
  item.cyl_playFromStart()
  assert.equal(item.cylState.instance.time, 0)
})

test('loop repeats a trigger, a restart and an input; turning it off stops the next pass', (t) => {
  t.mock.timers.enable({ apis: ['setTimeout'] })
  const definition = loadComponent()
  let fired = 0
  const check = { name: 'Check', asTrigger: () => ({ fire: () => { fired += 1 } }) }
  const { item } = makeItem(definition, { inputs: { Check: check }, options: { triggerInput: 'Check' }, duration: 1 })
  item.setLoop(true)
  assert.equal(fired, 1, 'turning loop on plays at once')
  t.mock.timers.tick(1400)
  t.mock.timers.tick(1400)
  assert.equal(fired, 3, 'a trigger loops (it used to fire once)')
  item.setLoop(false)
  t.mock.timers.tick(5000)
  assert.equal(fired, 3, 'no pass after loop is off')

  const machine = makeItem(definition, { inputs: {}, duration: 0 })
  machine.item.data.loop = true
  machine.item.cyl_playFromStart()
  t.mock.timers.tick(CYL_RIVE_LOOP_SECONDS * 1000)
  t.mock.timers.tick(CYL_RIVE_LOOP_SECONDS * 1000)
  assert.equal(machine.created.length, 4, 'a state machine without input restarts every pass')

  const active = boolInput('active')
  const held = makeItem(definition, { inputs: { active }, options: { input: 'active' }, duration: 1 })
  held.item.data.loop = true
  held.item.cyl_playFromStart()
  t.mock.timers.tick(1400)
  assert.deepEqual(active.history, [false, true, false, false, true], 'on, off after the duration, then on again')
})
