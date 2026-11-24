/**
 * [EN] Regression (WeChat DevTools UI test 16, "played once on the selected tab"): the data path of the tap animation without a
 *      device. The selected key is what plays; a selection write by the bar itself renders once, not twice; a bar that first
 *      renders an empty configuration keeps its key for the real one.
 * [CN] 回归（微信开发者工具 UI 测试 16，“在选中的 Tab 上播放一次”）：点击动画的数据路径，无需设备。播放的是选中的 key；
 *      TabBar 自己写入选中项只渲染一次而不是两次；先渲染空配置的 TabBar 为真实配置保留其 key。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const TABS = [
  { CYLTabBarItemIdentifier: 'home', CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'h.png' },
  { CYLTabBarItemIdentifier: 'me', CYLTabBarItemTitle: 'Me', CYLTabBarItemImage: 'm.png' },
]
const CONFIG = { CYLTabBarControllerTabBarItemsAttributes: TABS, CYLTabBarControllerTabButtonTapAnimation: 'bounceWithFireworks' }

function mount(configuration) {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  Object.assign(data, { configuration, loggedIn: true })
  const observed = Object.keys(definition.observers)[0].split(',').map((key) => key.trim())
  const bar = {
    data, renders: 0, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {}, selectComponent: () => null, triggerEvent() {},
    setData(patch, callback) {
      Object.assign(this.data, patch)
      if (observed.some((key) => key in patch)) definition.observers[Object.keys(definition.observers)[0]].call(this)
      if (callback) callback()
    },
    ...definition.methods,
  }
  const render = bar.cyl_render
  bar.cyl_render = function () { bar.renders += 1; return render.call(bar) }
  bar.cyl_syncLottie = () => {}
  bar.cyl_playTabButtonTapFeedback = () => {}
  bar.cyl_recordTap = () => {}
  bar.cylLongPressed = false
  definition.lifetimes.attached.call(bar)
  return bar
}

test('selecting a tab renders once: the mirrored selectedIdentifier / selectedIndex do not re-run the render', () => {
  const bar = mount(CONFIG)
  const before = bar.renders
  bar.cyl_select(bar.data.cylSlots[1].key)
  assert.equal(bar.renders, before, 'cyl_select writes the mirror without a render')
  assert.equal(bar.data.selectedIdentifier, 'me')
  bar.setData({ selectedIdentifier: 'home' })
  assert.equal(bar.renders, before + 1, 'a parent write is still an input and renders')
  assert.equal(bar.data.cylSlots[0].selected, true)
})

test('cyl_playSelectedTapAnimation plays on the selected key, also after a configuration rebuild', () => {
  const bar = mount(CONFIG)
  bar.cyl_select(bar.data.cylSlots[1].key)
  bar.setData({ configuration: { ...CONFIG, CYLTabBarControllerTabButtonTapAnimationDuration: 500 } })
  bar.cyl_playSelectedTapAnimation()
  assert.equal(bar.data.cylAnimatingIdentifier, 'me')
  assert.equal(bar.data.cylAnimatingName, 'bounceWithFireworks')
  assert.ok(bar.data.cylFireworks)
  clearTimeout(bar.cylAnimationTimer)
})

test('a bar that first renders an empty configuration plays on the tapped key once the real one arrives', () => {
  const bar = mount({})
  bar.cylSelectedKey = 'me'
  bar.setData({ configuration: CONFIG })
  assert.equal(bar.cylSelectedKey, 'me')
  bar.cyl_playSelectedTapAnimation()
  assert.equal(bar.data.cylAnimatingIdentifier, 'me')
  clearTimeout(bar.cylAnimationTimer)
})
