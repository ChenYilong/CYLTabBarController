/**
 * [EN] Selection by position: an icon-only bar, two tabs with the same title, and an identifier that differs from the
 *      page identifier. iOS selects by index; the bar holds the selection as a unique key per position.
 * [CN] 按位置选中：只有图标的 TabBar、标题相同的两个 Tab、标识与页面标识不同。iOS 按 index 选中；TabBar 以每个位置唯一的 key
 *      保存选中项。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylBar(configuration, properties) {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  Object.assign(data, { configuration, loggedIn: true }, properties)
  const observed = Object.keys(definition.observers)[0].split(',').map((key) => key.trim())
  const events = []
  const bar = {
    data, events, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {},
    setData(patch, callback) {
      Object.assign(this.data, patch)
      if (observed.some((key) => key in patch)) this.cyl_render()
      if (callback) callback()
    },
    selectComponent: () => null,
    triggerEvent(name, detail) { events.push({ name, detail }) },
    ...definition.methods,
  }
  bar.cyl_syncLottie = () => {}
  bar.cyl_playTapAnimation = () => {}
  bar.cyl_playTabButtonTapFeedback = () => {}
  bar.cyl_recordTap = () => {}
  bar.cylLongPressed = false
  definition.lifetimes.attached.call(bar)
  return bar
}

const selected = (bar) => bar.data.cylSlots.map((slot) => Boolean(slot.selected))
const tap = (bar, position) => bar.cyl_onTap({ type: 'tap', currentTarget: { dataset: { key: bar.data.cylSlots[position].key } } })

test('an icon-only bar (no titles, no identifiers) selects the tapped tab, not the first one', () => {
  const bar = cylBar({ CYLTabBarControllerTabBarItemsAttributes: [
    { CYLTabBarItemImage: 'a.png' }, { CYLTabBarItemImage: 'b.png' }, { CYLTabBarItemImage: 'c.png' } ] })
  assert.deepEqual(selected(bar), [true, false, false])
  assert.equal(new Set(bar.data.cylSlots.map((slot) => slot.key)).size, 3, 'every tab has its own key')
  tap(bar, 2)
  assert.deepEqual(selected(bar), [false, false, true])
  assert.equal(bar.data.selectedIndex, 2, 'the selection is a position')
  assert.equal(bar.events.find((event) => event.name === 'select').detail.index, 2)
  tap(bar, 1)
  assert.deepEqual(selected(bar), [false, true, false])
  tap(bar, 1)
  assert.equal(bar.events[bar.events.length - 1].name, 'reselect', 'the same position is a reselect')
})

test('two tabs with the same title are told apart by position', () => {
  const bar = cylBar({ CYLTabBarControllerTabBarItemsAttributes: [
    { CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'a.png' },
    { CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'b.png' } ] })
  tap(bar, 1)
  assert.deepEqual(selected(bar), [false, true])
  bar.cyl_selectIndex(0)
  assert.deepEqual(selected(bar), [true, false], 'selectedIndex selects by position')
  bar.setData({ selectedIndex: 1 })
  assert.deepEqual(selected(bar), [false, true])
})

test('an identifier that differs from the page identifier selects its own tab and reports both', () => {
  const bar = cylBar({ CYLTabBarControllerTabBarItemsAttributes: [
    { CYLTabBarItemIdentifier: 'a', CYLTabBarItemPageIdentifier: 'b', CYLTabBarItemImage: 'a.png' },
    { CYLTabBarItemIdentifier: 'b', CYLTabBarItemPageIdentifier: 'a', CYLTabBarItemImage: 'b.png' } ] })
  tap(bar, 1)
  assert.deepEqual(selected(bar), [false, true])
  const detail = bar.events.find((event) => event.name === 'select').detail
  assert.deepEqual([detail.index, detail.identifier, detail.pageIdentifier], [1, 'b', 'a'])
  assert.equal(bar.data.selectedIdentifier, 'b')
  assert.equal(bar.data.selectedIndex, 1)
  bar.setData({ selectedIdentifier: 'a' })
  assert.deepEqual(selected(bar), [true, false], 'selectedIdentifier still selects by identifier, not page identifier')
  assert.equal(bar.data.selectedIndex, 0)
})
