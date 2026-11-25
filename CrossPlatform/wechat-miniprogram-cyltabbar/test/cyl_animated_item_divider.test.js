'use strict'

// [EN] The divider item and the stack-level tint of cyl-animated-item(-stack): table-driven, pure functions only (plus the stack component in a fake runtime).
// [CN] cyl-animated-item(-stack) 的分割线条目与堆叠级着色：表驱动，只测纯函数（外加模拟运行时中的堆叠组件）。
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')
const { cylAnimatedItemDividerColor, cylAnimatedItemDividerStyle, cylAnimatedItemModel: model, CYL_ANIMATED_ITEM_DIVIDER_LENGTH, cylAnimatedItemColorWithAlpha: withAlpha, cylAnimatedItemInherited: inherited } = require('../src/cyl-animated-item/cyl_animated_item_model')
const { cylStackModel, cylStackAppendDivider, cylStackSetDivider, cylStackRemoveDivider, cylStackHasDivider } = require('../src/cyl-animated-item-stack/cyl_animated_item_stack_model')

const color = (p) => cylAnimatedItemDividerColor({ ...p, cylDividerColor: p.dividerColor, iconTint: p.iconColor })
const SEP_LIGHT = 'rgba(60,60,67,0.29)'
const SEP_DARK = 'rgba(84,84,88,0.65)'

// [EN] Each row: [dividerColor, stack iconColor, userInterfaceStyle, expected]. [CN] 每行：[dividerColor, 堆叠 iconColor, userInterfaceStyle, 期望值]。
test('divider color table: dividerColor, icon color at alpha 0.3, separator; light and dark', () => {
  const rows = [
    ['#FF0000', '#00FF00', 'light', '#FF0000'], ['#FF0000', '#00FF00', 'dark', '#FF0000'], ['#FF000080', '', 'dark', '#FF000080'], [' red ', '', 'light', 'red'],
    ['', '#00FF00', 'light', 'rgba(0,255,0,0.3)'], ['', '#00FF00', 'dark', 'rgba(0,255,0,0.3)'], ['', '#0F08', 'light', 'rgba(0,255,0,0.3)'], ['', '#11223344', 'light', 'rgba(17,34,51,0.3)'],
    ['', 'rgb(1, 2, 3)', 'dark', 'rgba(1,2,3,0.3)'], ['', 'rgba(1,2,3,0.9)', 'light', 'rgba(1,2,3,0.3)'],
    ['', '', 'light', SEP_LIGHT], ['', '', 'dark', SEP_DARK], [null, undefined, 'light', SEP_LIGHT], ['  ', 'blue', 'dark', SEP_DARK], ['', 'nonsense', 'light', SEP_LIGHT],
  ]
  rows.forEach(([dividerColor, iconColor, userInterfaceStyle, expected]) => assert.equal(color({ dividerColor, iconColor, userInterfaceStyle }), expected, JSON.stringify([dividerColor, iconColor, userInterfaceStyle])))
  // system follows the theme
  assert.equal(color({ systemTheme: 'dark' }), SEP_DARK)
  assert.equal(color({ systemTheme: 'light' }), SEP_LIGHT)
  assert.equal(color({ userInterfaceStyle: 'light', systemTheme: 'dark' }), SEP_LIGHT, 'forced style wins')
  assert.equal(withAlpha('#abc', 0.3), 'rgba(170,187,204,0.3)')
  assert.equal(withAlpha('', 0.3), '')
})

const dividersOf = (m) => m.items.map((i) => i.dividerBefore)
const four = [{ title: 'a', key: 'a' }, { title: 'b', key: 'b' }, { title: 'c', key: 'c' }, { title: 'd', key: 'd' }]

test('the stack hands its divider item the stack values; the item draws the line (1 px x length, sides swapped, own dark flag)', () => {
  const d = cylStackModel({ axis: 'horizontal', items: four, dividerColor: ' #123456 ', iconColor: '#FF0000', userInterfaceStyle: 'dark', animationTint: 'title' }).divider
  assert.deepEqual([d.color, d.length, d.vertical, d.iconTint, d.userInterfaceStyle, d.animationTint], ['#123456', 20, true, '#FF0000', 'dark', 'title'])
  const v = cylStackModel({ items: four, dividerLength: 30 }).divider
  assert.deepEqual([v.length, v.vertical, v.color], [30, false, ''])
  assert.equal(cylStackModel({ items: four, dividerLength: -5 }).divider.length, 20)
  assert.equal(CYL_ANIMATED_ITEM_DIVIDER_LENGTH, 20)
  assert.match(cylAnimatedItemDividerStyle({}), /^width: 1px; height: 20px;/)
  assert.match(cylAnimatedItemDividerStyle({ cylDividerLength: 12 }), /^width: 1px; height: 12px;/)
  assert.match(cylAnimatedItemDividerStyle({ cylDividerVertical: false, cylDividerLength: 30 }), /^width: 30px; height: 1px;/)
})

test('the internal divider mode: no icon, title, animation or badge, hidden from screen readers, own dark flag', () => {
  const props = { cylInternalDivider: true, title: 'T', image: 'a.png', animationUrl: 'a.riv', accessoryText: '!', selected: true }
  const m = model(props)
  assert.equal(m.isDivider, true)
  assert.equal(m.showsIcon, false)
  assert.equal(m.usesEngine, false)
  assert.equal(m.title, '')
  assert.equal(m.hasAccessory, false)
  assert.equal(m.ariaHidden, true)
  assert.match(m.dividerStyle, /rgba\(60,60,67,0\.29\)/)
  assert.match(model({ ...props, systemTheme: 'dark' }).dividerStyle, /rgba\(84,84,88,0\.65\)/)
  assert.match(model({ ...props, userInterfaceStyle: 'dark' }).dividerStyle, /rgba\(84,84,88,0\.65\)/)
  assert.match(model({ ...props, iconTint: '#FF0000' }).dividerStyle, /rgba\(255,0,0,0\.3\)/)
  assert.match(model({ ...props, cylDividerColor: '#123456', systemTheme: 'dark' }).dividerStyle, /background-color: #123456;/)
  assert.equal(model({ title: 'T' }).isDivider, undefined, 'a normal item is unchanged')
})

// [EN] The gap math (G3): a gap with a divider is before + 1 + after. Each row: [stack props, owner's dividerAfter, next item's spacingBefore, expected [before, after]].
test('gap math: before and after fall back stepwise; the next item margin is never added on top', () => {
  const rows = [
    [{ spacing: 12 }, { spacingBefore: 8, spacingAfter: 8 }, undefined, [8, 8]],
    [{ spacing: 12 }, true, undefined, [12, 12]],
    [{ spacing: 12 }, true, 5, [12, 5]],
    [{ spacing: 12, dividerSpacingBefore: 3 }, true, 5, [3, 5]],
    [{ spacing: 12, dividerSpacingAfter: 4 }, true, 5, [12, 4]],
    [{ spacing: 12, dividerSpacingBefore: 3, dividerSpacingAfter: 4 }, { spacingBefore: 9 }, 5, [9, 4]],
    [{ spacing: 12, dividerSpacingBefore: 3, dividerSpacingAfter: 4 }, { spacingAfter: 0, spacingBefore: 0 }, 5, [0, 0]],
    [{ spacing: 12, dividerSpacingBefore: -1, dividerSpacingAfter: -1 }, { spacingAfter: 7 }, undefined, [12, 7]],
    [{ spacing: 12, showsDividers: true }, undefined, 6, [12, 6]],
  ]
  rows.forEach(([stack, own, nextBefore, [b, a]]) => {
    const m = cylStackModel({ axis: 'horizontal', ...stack, items: [{ key: 'o', title: 'o', dividerAfter: own }, { key: 'n', title: 'n', spacingBefore: nextBefore }] })
    assert.equal(m.items[1].dividerBefore, true, JSON.stringify(rows.indexOf(own)))
    assert.equal(m.items[1].dividerStyle, `margin-left: ${b}px; margin-right: ${a}px;`, JSON.stringify([stack, own, nextBefore]))
    assert.equal(m.items[1].wrapperStyle, '', 'the next item adds nothing on top')
  })
  const vertical = cylStackModel({ spacing: 12, items: [{ title: 'o', dividerAfter: { spacingBefore: 8, spacingAfter: 8 } }, { title: 'n' }] })
  assert.equal(vertical.items[1].dividerStyle, 'margin-top: 8px; margin-bottom: 8px;')
  // the worked example: 8 + 1 + 8 = 17 instead of 12 + 8 + 1 + 8 + 12
  assert.equal(8 + 1 + 8, 17)
})

test('appendDivider: after the current last item, a no-op on an empty list; set / remove / has', () => {
  assert.deepEqual(cylStackAppendDivider([], 8, 8), [])
  assert.deepEqual(cylStackAppendDivider(undefined), [])
  const camera = { key: 'camera', title: 'camera' }
  const search = { key: 'search', title: 'search' }
  let items = cylStackAppendDivider([camera], 8, 8)
  assert.deepEqual(items[0].dividerAfter, { spacingBefore: 8, spacingAfter: 8 })
  assert.deepEqual(camera, { key: 'camera', title: 'camera' }, 'the input is not mutated')
  items = [...items, search]
  const m = cylStackModel({ spacing: 12, items })
  assert.equal(m.items[1].dividerStyle, 'margin-left: 8px; margin-right: 8px;'.replace(/left/, 'top').replace(/right/, 'bottom'))
  assert.equal(cylStackAppendDivider([camera]).at(-1).dividerAfter, true, 'no values: the fallbacks')
  assert.equal(cylStackHasDivider(m, 0), true)
  assert.equal(cylStackHasDivider(m, 1), false, 'the last item has none after it')
  assert.equal(cylStackHasDivider(m, 9), false)
  // set / remove: remove turns a gap off even with showsDividers
  const plain = [camera, search, { key: 'x', title: 'x' }]
  const set = cylStackSetDivider(plain, 1, 2, 3)
  assert.deepEqual(set[1].dividerAfter, { spacingBefore: 2, spacingAfter: 3 })
  assert.equal(cylStackSetDivider(plain, 5, 1, 1), plain, 'out of range: unchanged')
  const all = cylStackModel({ showsDividers: true, items: plain })
  assert.deepEqual([cylStackHasDivider(all, 0), cylStackHasDivider(all, 1)], [true, true])
  const off = cylStackModel({ showsDividers: true, items: cylStackRemoveDivider(plain, 0) })
  assert.deepEqual([cylStackHasDivider(off, 0), cylStackHasDivider(off, 1)], [false, true], 'one gap off')
})

test('showsDividers: one between every two items, none before the first or after the last; off by default', () => {
  assert.deepEqual(dividersOf(cylStackModel({ items: four })), [false, false, false, false])
  assert.deepEqual(dividersOf(cylStackModel({ items: four, showsDividers: true })), [false, true, true, true])
  assert.deepEqual(dividersOf(cylStackModel({ items: [four[0]], showsDividers: true })), [false])
  assert.deepEqual(dividersOf(cylStackModel({ items: [], showsDividers: true })), [])
})

test('dividerAfter true / false overrides its own gap, with showsDividers on and off', () => {
  const on = cylStackModel({ showsDividers: true, items: [{ ...four[0], dividerAfter: false }, four[1], { ...four[2], dividerAfter: true }, four[3]] })
  assert.deepEqual(dividersOf(on), [false, false, true, true], 'a/b off, b/c on (default), c/d on')
  const off = cylStackModel({ items: [four[0], { ...four[1], dividerAfter: true }, { ...four[2], dividerAfter: false }, { ...four[3], dividerAfter: true }] })
  assert.deepEqual(dividersOf(off), [false, false, true, false], 'only b/c; the last item has none after it')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: [{ ...four[0], dividerAfter: null }, four[1]] })), [false, true], 'null inherits')
})

test('hidden neighbours: a divider only between two visible items, none left for a hidden one', () => {
  const hide = (list, ...keys) => list.map((i) => (keys.includes(i.key) ? { ...i, visible: false } : i))
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: hide(four, 'b') })), [false, false, true, true], 'a|c, c|d')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: hide(four, 'a') })), [false, false, true, true], 'none before the first visible')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: hide(four, 'd') })), [false, true, true, false], 'none after the last visible')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: hide(four, 'a', 'd') })), [false, false, true, false])
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: hide(four, 'a', 'b', 'c', 'd') })), [false, false, false, false])
  // the divider after the item before a hidden one is the one that counts: a|c takes a's setting
  const m = cylStackModel({ showsDividers: true, items: hide([{ ...four[0], dividerAfter: false }, four[1], four[2]], 'b') })
  assert.deepEqual(dividersOf(m), [false, false, false])
})

test('append, remove, reorder and hide update the dividers by themselves; the items list never holds a divider', () => {
  const a = { ...four[0], dividerAfter: false }
  const [, b, c, d] = four
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: [a, b] })), [false, false])
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: [a, b, c] })), [false, false, true], 'appended c')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: [a, c] })), [false, false], 'removed b: a|c is a`s gap (off)')
  assert.deepEqual(dividersOf(cylStackModel({ showsDividers: true, items: [b, a, c] })), [false, true, false], 'reordered: b|a on, a|c off')
  const m = cylStackModel({ showsDividers: true, items: [a, b, c, d] })
  assert.deepEqual(m.items.map((i) => i.key), ['a', 'b', 'c', 'd'])
  assert.equal(m.items.some((i) => 'isDivider' in i || 'dividerAxis' in i), false)
})

test('the color follows the stack through the divider item: derived from iconColor, explicit, light / dark', () => {
  const style = (p, extra) => cylAnimatedItemDividerStyle({ ...extra, cylDividerColor: cylStackModel({ items: four, ...p }).divider.color, iconTint: cylStackModel({ items: four, ...p }).divider.iconTint, userInterfaceStyle: cylStackModel({ items: four, ...p }).divider.userInterfaceStyle })
  assert.match(style({ iconColor: '#FF0000' }), /rgba\(255,0,0,0\.3\)/)
  assert.match(style({ iconColor: '#FF0000', dividerColor: '#123456' }), /background-color: #123456;/)
  assert.match(style({}), /rgba\(60,60,67,0\.29\)/)
  assert.match(style({}, { systemTheme: 'dark' }), /rgba\(84,84,88,0\.65\)/)
  assert.match(style({ userInterfaceStyle: 'dark' }), /rgba\(84,84,88,0\.65\)/)
})

test('inheritance: the item value wins when set, blank inherits', () => {
  assert.equal(inherited('#111111', '#222222'), '#111111')
  assert.equal(inherited('', '#222222'), '#222222')
  assert.equal(inherited(undefined, ' #222222 '), '#222222')
  assert.equal(inherited(null, ''), '')
})

test('stack inheritance: stack only, item wins, appended later, cleared, icon colors', () => {
  const stack = { animationTint: 'title', animationDarkTint: '#112233', iconColor: '#888888', selectedIconColor: '#007AFF' }
  const pick = (m) => m.items.map((i) => [i.animationTint, i.animationDarkTint])
  let m = cylStackModel({ ...stack, items: [{ title: 'a' }, { title: 'b', animationTint: '#FF0000', animationDarkTint: '#00FF00' }] })
  assert.deepEqual(pick(m), [['title', '#112233'], ['#FF0000', '#00FF00']])
  assert.deepEqual([m.items[0].animationIconTint, m.items[0].animationSelectedIconTint], ['#888888', '#007AFF'])
  // appended later
  m = cylStackModel({ ...stack, items: [{ title: 'a' }, { title: 'b' }, { title: 'c' }] })
  assert.deepEqual(pick(m)[2], ['title', '#112233'])
  // cleared: items without their own lose the value, their own stay
  m = cylStackModel({ items: [{ title: 'a' }, { title: 'b', animationTint: '#FF0000' }] })
  assert.deepEqual(pick(m), [['', ''], ['#FF0000', '']])
  // appearance: nothing is baked in, so the item re-resolves with its own dark flag (the effective values are plain strings)
  assert.equal(cylStackModel({ ...stack, items: [{}] }).items[0].animationDarkTint, '#112233')
})

test('contentMargin 0 leaves no padding; the default stays 16; hugsContent sizes by the items', () => {
  assert.equal(cylStackModel({ contentMargin: 0 }).containerStyle, 'padding: 0px;')
  assert.equal(cylStackModel({}).containerStyle, 'padding: 16px;')
  assert.equal(cylStackModel({ contentMargin: 0 }).containerClass, '')
  assert.equal(cylStackModel({ contentMargin: 0, hugsContent: true }).containerClass, 'cyl-stack-hug')
})

test('hidden items leave no spacing; the first visible item has none before it; alpha keeps its space', () => {
  const items = [{ title: 'a', visible: false }, { title: 'b' }, { title: 'c', visible: false }, { title: 'd' }]
  const m = cylStackModel({ items, axis: 'horizontal', spacing: 10 })
  assert.deepEqual(m.items.map((i) => i.wrapperStyle), ['display: none;', '', 'display: none;', 'margin-left: 10px;'])
  assert.equal(m.items[0].hidden, true)
  const faded = cylStackModel({ items: [{ title: 'a' }, { title: 'b', alpha: 0.5 }, { title: 'c', alpha: 7 }] })
  assert.deepEqual(faded.items.map((i) => i.wrapperStyle), ['', 'margin-top: 16px; opacity: 0.5;', 'margin-top: 16px;'])
})

test('append, remove and reorder: the model follows the list', () => {
  const a = { key: 'a', title: 'A' }, b = { key: 'b', title: 'B' }, c = { key: 'c', title: 'C' }
  const keys = (list) => cylStackModel({ items: list }).items.map((i) => i.key)
  assert.deepEqual(keys([a, b]), ['a', 'b'])
  assert.deepEqual(keys([a, b, c]), ['a', 'b', 'c'])
  assert.deepEqual(keys([a, c]), ['a', 'c'])
  assert.deepEqual(keys([c, a, b]), ['c', 'a', 'b'])
  const moved = cylStackModel({ items: [c, a, b], spacing: 4 })
  assert.deepEqual(moved.items.map((i) => i.wrapperStyle), ['', 'margin-top: 4px;', 'margin-top: 4px;'])
})

function mount(properties) {
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
  const stack = { data, setData(patch) { Object.assign(this.data, patch) }, triggerEvent(name, detail) { events.push({ name, detail }) }, ...definition.methods }
  return { stack, events, definition }
}

test('dispatchesItemTaps false: no item action, no background action, no performAction', () => {
  const { stack, events } = mount({ items: [{ title: 'a', action: 'a' }], backgroundAction: 'bg', dispatchesItemTaps: false })
  stack.cyl_onItemTap({ currentTarget: { dataset: { index: 0 } }, timeStamp: 1 })
  stack.cyl_onBackgroundTap({ timeStamp: 1 })
  assert.equal(stack.performAction('a'), false)
  assert.deepEqual(events, [])
})

test('the divider is an internal item instance: not in items, tap swallowed, hidden, its flags are internal-only', () => {
  const { definition } = mount({})
  assert.equal(typeof definition.methods.cyl_noop, 'function')
  const wxml = require('node:fs').readFileSync(path.join(__dirname, '../src/cyl-animated-item-stack/index.wxml'), 'utf8')
  assert.match(wxml, /class="cyl-stack-divider"[^>]*catchtap="cyl_noop"/)
  assert.match(wxml, /<cyl-animated-item\s+cyl-internal-divider/)
  assert.match(wxml, /accessibility-hidden="\{\{true\}\}"/)
  const itemJs = require('node:fs').readFileSync(path.join(__dirname, '../src/cyl-animated-item/index.js'), 'utf8')
  assert.equal(/\bisDivider\b|\bdividerAxis\b|\bdividerColor\b/.test(itemJs), false, 'no public divider property on the item')
  assert.match(itemJs, /\/\/ \[EN\] INTERNAL, not API/)
})

test('dispatchesItemTaps defaults to true and every stack property is observed', () => {
  const { definition } = mount({})
  assert.equal(definition.properties.dispatchesItemTaps.value, true)
  const keys = Object.keys(definition.observers)[0]
  ;['animationTint', 'animationDarkTint', 'dividerColor', 'dividerLength', 'dividerSpacingBefore', 'dividerSpacingAfter', 'showsDividers', 'hugsContent', 'userInterfaceStyle'].forEach((name) => assert.ok(keys.includes(name), name))
})
