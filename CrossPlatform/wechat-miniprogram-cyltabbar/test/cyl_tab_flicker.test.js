/**
 * [EN] The flicker after a tap (Liquid Glass, static image icons): every tab page has its own cyl-tab-bar, and the page that
 *      wx.switchTab shows next must draw the tapped tab in its FIRST painted frame. These tests record every setData of
 *      every bar and assert that no write after the tap ever selects the previous tab, not only the final state. They
 *      run in a fake of the Component() runtime: the frames on a device are checked in WeChat DevTools (docs/WeChat-Mini-Program.md).
 * [CN] 点击后的闪动（液态玻璃、静态图片图标）：每个 Tab 页面都有自己的 cyl-tab-bar，wx.switchTab 接下来显示的页面必须在
 *      首个绘制帧就绘制被点击的 Tab。这些测试记录每个 TabBar 的每次 setData，断言点击之后没有任何一次写入选中上一个 Tab，
 *      而不只检查最终状态。测试在模拟的 Component() 运行时中运行：真机帧在微信开发者工具中检查（docs/WeChat-Mini-Program.md）。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const CYL_TABS = [
  { CYLTabBarItemIdentifier: 'home', CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'home.png', CYLTabBarItemSelectedImage: 'home-s.png' },
  { CYLTabBarItemIdentifier: 'message', CYLTabBarItemTitle: 'Message', CYLTabBarItemImage: 'message.png', CYLTabBarItemSelectedImage: 'message-s.png' },
  { CYLTabBarItemIdentifier: 'me', CYLTabBarItemTitle: 'Me', CYLTabBarItemImage: 'me.png', CYLTabBarItemSelectedImage: 'me-s.png' },
]
const CYL_GLASS = { CYLTabBarControllerStyleType: 'liquidGlass', CYLTabBarControllerTabBarItemsAttributes: CYL_TABS }

function cylRuntime() {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const observed = Object.keys(definition.observers)[0].split(',').map((key) => key.trim())
  /** [EN] Mounts a bar; `frames` holds the selected positions of every render. [CN] 挂载 TabBar；`frames` 记录每次渲染的选中位置。 */
  function mount(properties) {
    const data = { ...definition.data }
    Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
    Object.assign(data, { loggedIn: true, itemStyle: 'liquidGlass' }, properties)
    const bar = {
      data, frames: [], cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {}, selectComponent: () => null, triggerEvent() {},
      setData(patch, callback) {
        const before = this.data.cylSlots
        Object.assign(this.data, patch)
        if (observed.some((key) => key in patch)) this.cylRender()
        if (this.data.cylSlots !== before) this.frames.push(this.data.cylSlots.map((slot) => Boolean(slot.selected)).indexOf(true))
        if (callback) callback()
      },
      ...definition.methods,
    }
    bar.cylSyncLottie = () => {}
    bar.cylPlayTapAnimation = () => {}
    bar.cylPlayTabButtonTapFeedback = () => {}
    bar.cylRecordTap = () => {}
    bar.cylLongPressed = false
    definition.lifetimes.attached.call(bar)
    return bar
  }
  return { definition, mount }
}

const tap = (bar, position) => bar.cylOnTap({ type: 'tap', currentTarget: { dataset: { key: bar.data.cylSlots[position].key } } })

test('a new page bar (first visit) that starts with an empty configuration still draws the tapped tab first', () => {
  const { mount } = cylRuntime()
  const tapped = mount({ configuration: CYL_GLASS })
  tap(tapped, 2)
  // [EN] The example's custom-tab-bar passes {} to cyl-tab-bar first, then the configuration from its own `attached`.
  // [CN] 示例的 custom-tab-bar 先把 {} 传给 cyl-tab-bar，再在自己的 `attached` 中传入配置。
  const fresh = mount({ configuration: {} })
  fresh.setData({ configuration: CYL_GLASS })
  assert.equal(fresh.frames[fresh.frames.length - 1], 2)
  assert.deepEqual(fresh.frames.filter((position) => position === 0), [], 'the first tab is never drawn selected')
})

test('no bar draws the previous tab after a tap: cached bar, new bar, parent re-render, route sync', () => {
  const { mount } = cylRuntime()
  const first = mount({ configuration: CYL_GLASS })
  const cached = mount({ configuration: CYL_GLASS })
  tap(first, 1)
  const afterTap = [first, cached].map((bar) => bar.frames.length)
  const fresh = mount({ configuration: {} })
  fresh.setData({ configuration: CYL_GLASS })
  // [EN] The parent re-renders with its own, stale selection (the custom-tab-bar binds selected-identifier).
  // [CN] 父组件以自己过期的选中项重新渲染（custom-tab-bar 绑定了 selected-identifier）。
  ;[first, cached, fresh].forEach((bar) => bar.setData({ selectedIdentifier: '' }))
  ;[first, cached, fresh].forEach((bar) => bar.setData({ configuration: { ...CYL_GLASS } }))
  ;[first, cached, fresh].forEach((bar) => assert.equal(bar.cylSelectPage('message'), true))
  assert.deepEqual(first.frames.slice(afterTap[0]).concat(cached.frames.slice(afterTap[1]), fresh.frames).filter((position) => position !== 1 && position !== -1), [],
    'every frame after the tap selects the tapped tab (-1: no tabs yet, nothing drawn)')
  assert.deepEqual([first, cached, fresh].map((bar) => bar.data.selectedIndex), [1, 1, 1])
})

test('fast taps A, B, C leave every bar on C, with no frame on a tab that was not tapped last', () => {
  const { mount } = cylRuntime()
  const bars = [mount({ configuration: CYL_GLASS }), mount({ configuration: CYL_GLASS })]
  tap(bars[0], 1)
  tap(bars[1], 2)
  assert.deepEqual(bars.map((bar) => bar.data.selectedIndex), [2, 2])
  assert.deepEqual(bars.map((bar) => bar.data.cylSlots.filter((slot) => slot.selected).length), [1, 1])
})

test('a page is selected by position, even with repeated titles and no identifiers (icon-only bar)', () => {
  const { mount } = cylRuntime()
  const bar = mount({ configuration: { CYLTabBarControllerTabBarItemsAttributes: [
    { CYLTabBarItemImage: 'a.png', CYLTabBarItemPageIdentifier: 'one' },
    { CYLTabBarItemImage: 'b.png', CYLTabBarItemPageIdentifier: 'two' } ] } })
  assert.equal(bar.cylSelectPage('two'), true)
  assert.equal(bar.data.selectedIndex, 1)
  assert.equal(bar.cylSelectPage('unknown'), false)
})
