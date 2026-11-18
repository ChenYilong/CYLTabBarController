/**
 * [EN] Tests of cyl-animated-item-stack (src/cyl-animated-item-stack): the model (order, spacing, roles, wrapping) and
 *      the component's events in a small fake of the mini program `Component()` runtime, as the iOS and Android tests.
 *      Run: `npm test`.
 * [CN] cyl-animated-item-stack 的测试：模型（顺序、间距、角色、换行）以及在模拟的小程序 `Component()` 运行时中的组件事件，与 iOS、Android 测试一致。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')
const { cylStackModel, cylStackActionAt, cylStackIndexForAction } = require('../src/cyl-animated-item-stack/cyl_animated_item_stack_model')

function cylMountStack(properties) {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-animated-item-stack/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  Object.assign(data, properties)
  const events = []
  const stack = {
    data,
    setData(patch) { Object.assign(this.data, patch) },
    triggerEvent(name, detail) { events.push({ name, detail }) },
    ...definition.methods,
  }
  definition.observers['items, contentMargin, backgroundAction'].call(stack, data.items, data.contentMargin, data.backgroundAction)
  return { stack, events }
}

function cylTap(stack, index, timeStamp) {
  // [EN] A tap on an item bubbles from its wrapper to the container. [CN] 点击条目时事件从其包装视图冒泡到容器。
  if (index >= 0) stack.cyl_onItemTap({ currentTarget: { dataset: { index } }, timeStamp })
  stack.cyl_onBackgroundTap({ timeStamp })
}

test('items keep their order and every element is a vertical cyl-animated-item model', () => {
  const m = cylStackModel({ items: [{ title: 'No messages' }, { title: 'Pull to refresh' }] })
  assert.deepEqual(m.items.map((item) => item.title), ['No messages', 'Pull to refresh'])
  assert.equal(m.items[0].index, 0)
  assert.equal(m.containerStyle, 'padding: 16px;')
})

test('an empty or invalid list gives no items', () => {
  assert.deepEqual(cylStackModel({}).items, [])
  assert.deepEqual(cylStackModel({ items: [null, 3, 'x'] }).items, [])
})

test('spacing before an item, none before the first', () => {
  const m = cylStackModel({ items: [{ title: 'Empty', spacingBefore: 40 }, { title: 'Retry', spacingBefore: 24 }, { title: 'Help' }] })
  assert.equal(m.items[0].wrapperStyle, '')
  assert.equal(m.items[1].wrapperStyle, 'margin-top: 24px;')
  assert.equal(m.items[2].wrapperStyle, 'margin-top: 16px;')
})

test('titles wrap unless titleLines is given', () => {
  const m = cylStackModel({ items: [{ title: 'Long hint' }, { title: 'One line', titleLines: 1 }] })
  assert.equal(m.items[0].titleLines, 0)
  assert.equal(m.items[1].titleLines, 1)
})

test('actions: lookup by name and the action of a tap', () => {
  const m = cylStackModel({ items: [{ title: 'Empty' }, { title: 'Retry', action: 'retry' }] })
  assert.equal(cylStackActionAt(m, 1), 'retry')
  assert.equal(cylStackActionAt(m, 0), '')
  assert.equal(cylStackIndexForAction(m, 'retry'), 1)
  assert.equal(cylStackIndexForAction(m, 'missing'), -1)
})

test('screen reader roles: button, text, decoration, and the first item for the background action', () => {
  const items = [{ title: 'No connection' }, { title: 'Retry', action: 'retry' }, { image: '/line.png' }, { image: '/line.png', accessibilityLabel: 'Divider' }]
  let m = cylStackModel({ items })
  assert.deepEqual(m.items.map((item) => [item.role, item.hidden]), [['text', false], ['button', false], ['text', true], ['text', false]])
  m = cylStackModel({ items, backgroundAction: 'reload' })
  assert.equal(m.items[0].role, 'button')
})

test('a tap on an item with an action triggers that action, once', () => {
  const { stack, events } = cylMountStack({ items: [{ title: 'Empty' }, { title: 'Retry', action: 'retry' }], backgroundAction: 'reload' })
  cylTap(stack, 1, 100)
  assert.deepEqual(events, [{ name: 'action', detail: { action: 'retry', index: 1, background: false } }])
})

test('a tap on an item without an action, or on the empty space, triggers the background action', () => {
  const { stack, events } = cylMountStack({ items: [{ title: 'No connection' }, { title: 'Retry', action: 'retry' }], backgroundAction: 'reload' })
  cylTap(stack, 0, 100)
  cylTap(stack, -1, 200)
  assert.deepEqual(events.map((event) => [event.detail.action, event.detail.background]), [['reload', true], ['reload', true]])
})

test('no background action: a tap outside items with an action does nothing', () => {
  const { stack, events } = cylMountStack({ items: [{ title: 'No connection' }] })
  cylTap(stack, 0, 100)
  assert.deepEqual(events, [])
})

test('performAction and itemIndexForAction', () => {
  const { stack, events } = cylMountStack({ items: [{ title: 'Empty' }, { title: 'Retry', action: 'retry' }] })
  assert.equal(stack.performAction(''), false)
  assert.equal(stack.performAction('retry'), true)
  assert.deepEqual(events[0].detail, { action: 'retry', index: 1, background: false })
  assert.equal(stack.itemIndexForAction('retry'), 1)
})
