/**
 * [EN] Paint-level flicker hardening (Liquid Glass, static image icons): both static images stay mounted and a selection change
 *      only toggles their opacity (no node created, no `src` change), the glass lens springs in only for a tap on the same bar
 *      instance (never on a bar shown by a page switch), and a route sync keeps a remembered tap from being applied over it.
 *      Render data and templates are tested here; the frames are checked in WeChat DevTools (docs/WeChat-Mini-Program.md).
 * [CN] 绘制层面的闪动加固（液态玻璃、静态图片图标）：两张静态图片都保持挂载，选中变化只切换它们的不透明度（不创建节点、不改变
 *      `src`）；玻璃透镜只在同一 TabBar 实例上的点击时弹入（页面切换后显示的 TabBar 从不弹入）；路由同步之后，已记住的点击不会
 *      再覆盖它。这里测试渲染数据与模板；帧在微信开发者工具中检查（docs/WeChat-Mini-Program.md）。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { cylAnimatedItemModel } = require('../src/cyl-animated-item/cyl_animated_item_model')
const { cylItemModel } = require('../src/cyl-tab-bar-item/cyl_tab_bar_item_model')

const read = (file) => fs.readFileSync(path.join(__dirname, '../src', file), 'utf8')
const TABS = [
  { CYLTabBarItemIdentifier: 'home', CYLTabBarItemTitle: 'Home', CYLTabBarItemImage: 'home.png', CYLTabBarItemSelectedImage: 'home-s.png', CYLTabBarItemPageIdentifier: 'home' },
  { CYLTabBarItemIdentifier: 'message', CYLTabBarItemTitle: 'Message', CYLTabBarItemImage: 'message.png', CYLTabBarItemSelectedImage: 'message-s.png', CYLTabBarItemPageIdentifier: 'message' },
  { CYLTabBarItemIdentifier: 'me', CYLTabBarItemTitle: 'Me', CYLTabBarItemImage: 'me.png', CYLTabBarItemSelectedImage: 'me-s.png', CYLTabBarItemPageIdentifier: 'me' },
]
const CONFIG = { CYLTabBarControllerStyleType: 'liquidGlass', CYLTabBarControllerTabBarItemsAttributes: TABS }

function runtime() {
  global.wx = { getSystemInfoSync: () => ({ theme: 'light' }), getAppBaseInfo: () => ({ theme: 'light' }) }
  let definition
  global.Component = (d) => { definition = d }
  const file = path.join(__dirname, '../src/cyl-tab-bar/index.js')
  delete require.cache[file]
  require(file)
  delete global.Component
  const key = Object.keys(definition.observers)[0]
  return (properties) => {
    const data = { ...definition.data }
    Object.entries(definition.properties).forEach(([name, value]) => { data[name] = value.value })
    Object.assign(data, { loggedIn: true, itemStyle: 'liquidGlass' }, properties)
    const bar = {
      data, cylBadges: {}, cylCovers: {}, cylBadgeAttributes: {}, selectComponent: () => null, triggerEvent() {},
      setData(patch, callback) {
        Object.assign(this.data, patch)
        if (key.split(',').some((name) => name.trim() in patch)) definition.observers[key].call(this)
        if (callback) callback()
      },
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
}

const tap = (bar, position) => bar.cyl_onTap({ type: 'tap', currentTarget: { dataset: { key: bar.data.cylSlots[position].key } } })

test('static icons: both images are passed at every selection and the item model does not swap src', () => {
  const states = [false, true].map((selected) => cylItemModel({ image: 'a.png', selectedImage: 'a-s.png', selected }))
  assert.deepEqual(states.map((m) => [m.normalImage, m.selectedStillImage]), [['a.png', 'a-s.png'], ['a.png', 'a-s.png']])
})

test('cyl-animated-item keeps both static images mounted: only the hidden flags change with `selected`', () => {
  const base = { image: 'a.png', selectedImage: 'a-s.png', iconTint: '', selectedIconTint: '' }
  const off = cylAnimatedItemModel({ ...base, selected: false }).still
  const on = cylAnimatedItemModel({ ...base, selected: true }).still
  assert.equal(off.layered, true)
  assert.deepEqual([off.normalImage, off.selectedImage], [on.normalImage, on.selectedImage], 'no src changes')
  assert.deepEqual([off.normalHidden, off.selectedHidden], [false, true])
  assert.deepEqual([on.normalHidden, on.selectedHidden], [true, false])
})

test('each layer has its own tint, so the node type does not change when only one state has a tint', () => {
  const base = { image: 'a.png', selectedImage: 'a-s.png', iconTint: '#999999', selectedIconTint: '' }
  const off = cylAnimatedItemModel({ ...base, selected: false })
  const on = cylAnimatedItemModel({ ...base, selected: true })
  assert.deepEqual([off.still.normalTint, off.still.selectedTint], ['#999999', ''])
  assert.deepEqual([on.still.normalTint, on.still.selectedTint], ['#999999', ''])
  assert.equal(off.iconTint, '#999999')
  assert.equal(on.iconTint, '', 'the current tint (GIF stills) still follows the state')
})

test('an item without its own selected image, or with a GIF, is not layered (the old single image)', () => {
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selectedImage: '', selected: true }).still.layered, false)
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selectedImage: 'a.png', selected: true }).still.layered, false)
  assert.equal(cylAnimatedItemModel({ image: 'a.gif', selectedImage: 'b.gif', selected: true }).still.layered, false)
  assert.equal(cylAnimatedItemModel({ image: 'a.png', selected: true, iconTint: '#111' }).iconTint, '#111', 'selectedIconTint unset keeps iconTint')
})

test('templates: the item gets both images and the lens flag; no src binding depends on selection', () => {
  const item = read('cyl-tab-bar-item/index.wxml')
  assert.ok(item.includes('image="{{m.normalImage}}"') && item.includes('selected-image="{{m.selectedStillImage}}"'))
  assert.ok(item.includes('animated="{{lensAnimated}}"'))
  const animated = read('cyl-animated-item/index.wxml')
  assert.ok(animated.includes('src="{{m.still.normalImage}}"') && animated.includes('src="{{m.still.selectedImage}}"'))
  const bar = read('cyl-tab-bar/index.wxml')
  assert.ok(bar.includes('lens-animated="{{cylLensAnimated}}"') && bar.includes('animated="{{cylLensAnimated}}"'))
  assert.ok(read('cyl-glass-lens/index.wxml').includes('cyl-glass-lens-still'))
  assert.match(read('cyl-glass-lens/index.wxss'), /\.cyl-glass-lens-still\s*\{\s*animation: none;/)
})

test('slot keys do not change between selections (no node re-created by wx:key)', () => {
  const bar = runtime()({ configuration: CONFIG })
  const keys = bar.data.cylSlots.map((slot) => slot.key)
  tap(bar, 1)
  tap(bar, 2)
  tap(bar, 0)
  assert.deepEqual(bar.data.cylSlots.map((slot) => slot.key), keys)
  assert.deepEqual(bar.data.cylSlots.map((slot) => slot.item.image), ['home.png', 'message.png', 'me.png'])
  assert.deepEqual(bar.data.cylSlots.map((slot) => slot.item.selectedImage), ['home-s.png', 'message-s.png', 'me-s.png'])
})

test('the lens springs in only for a tap on the same instance', () => {
  const create = runtime()
  const first = create({ configuration: CONFIG })
  assert.equal(first.data.cylLensAnimated, false, 'the first render of an instance draws the lens at once')
  const cached = create({ configuration: CONFIG })
  tap(first, 1)
  assert.equal(first.data.cylLensAnimated, true, 'a tap on this instance')
  assert.equal(cached.data.cylLensAnimated, false, 'a followed tap (the page shown by switchTab)')
  const fresh = create({ configuration: {} })
  fresh.setData({ configuration: CONFIG })
  assert.equal(fresh.data.cylSlots[1].selected, true)
  assert.equal(fresh.data.cylLensAnimated, false, 'a new bar instance after the switch')
  first.setData({ selectedIdentifier: 'me' })
  assert.equal(first.data.cylLensAnimated, false, 'a parent-driven selection after a tap does not spring in')
  tap(first, 0)
  assert.equal(first.data.cylLensAnimated, true)
  assert.equal(first.cyl_selectPage('message'), true)
  assert.equal(first.data.cylLensAnimated, false, 'a route sync')
})

test('a route sync replaces the remembered tap, so a bar shown later cannot paint the previous tab', () => {
  const create = runtime()
  const bar = create({ configuration: CONFIG })
  tap(bar, 1)
  // [EN] A programmatic switch to `me` within 3 s of the tap on `message`: the route sync of that page is the newest truth.
  // [CN] 点击 `message` 后 3 秒内以编程方式切换到 `me`：该页面的路由同步是最新的事实。
  const synced = create({ configuration: CONFIG })
  synced.cyl_selectPage('me')
  const shown = create({ configuration: {} })
  shown.setData({ configuration: CONFIG })
  assert.deepEqual(shown.data.cylSlots.map((slot) => Boolean(slot.selected)), [false, false, true])
})
