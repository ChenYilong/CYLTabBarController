/**
 * [EN] The default bar height is the WeChat native tab bar's 48 px (docs/Cross-Platform-Components.md, "default tab bar
 *      height = the system tab bar's"), and `tabBarHeight` overrides it; the Liquid Glass capsule keeps its own height.
 *      cyl-tab-bar runs in a small fake of the mini program `Component()` runtime. Run: `npm test`.
 * [CN] 默认 TabBar 高度为微信原生 tabBar 的 48 px，`tabBarHeight` 可覆盖；液态玻璃胶囊保持自己的高度。cyl-tab-bar 运行在模拟的小程序
 *      `Component()` 运行时中。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

function cylBar(properties) {
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const data = { ...definition.data }
  Object.entries(definition.properties).forEach(([key, value]) => { data[key] = value.value })
  Object.assign(data, properties)
  const bar = {
    data, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {},
    setData(patch, callback) { Object.assign(this.data, patch); if (callback) callback() },
    selectComponent: () => null,
    triggerEvent() {},
    ...definition.methods,
  }
  bar.cylSyncLottie = () => {}
  bar.cylRender()
  return bar
}

const CONFIGURATION = {
  CYLTabBarControllerTabBarItemsAttributes: [
    { CYLTabBarItemTitle: 'A', CYLTabBarItemImage: 'a.png' },
    { CYLTabBarItemTitle: 'B', CYLTabBarItemImage: 'b.png' },
  ],
}

test('without tabBarHeight the bar is the WeChat native tab bar\'s 48 px', () => {
  assert.match(cylBar({ configuration: CONFIGURATION }).data.cylBarStyle, /--cyl-bar-height: 48px;/)
  assert.match(cylBar({ configuration: CONFIGURATION, tabBarHeight: 0 }).data.cylBarStyle, /--cyl-bar-height: 48px;/)
  assert.match(cylBar({ configuration: CONFIGURATION, tabBarHeight: -5 }).data.cylBarStyle, /--cyl-bar-height: 48px;/)
})

test('a tabBarHeight the app sets wins', () => {
  assert.match(cylBar({ configuration: CONFIGURATION, tabBarHeight: 64 }).data.cylBarStyle, /--cyl-bar-height: 64px;/)
})

test('the Liquid Glass bar keeps its own capsule height', () => {
  assert.doesNotMatch(cylBar({ configuration: CONFIGURATION, itemStyle: 'liquidGlass', tabBarHeight: 64 }).data.cylBarStyle, /--cyl-bar-height/)
})
