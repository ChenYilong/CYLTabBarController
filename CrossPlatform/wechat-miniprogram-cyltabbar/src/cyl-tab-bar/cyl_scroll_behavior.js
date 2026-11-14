/**
 * [EN] A page behavior for the animated tab icons in WeChat DevTools: while a page scrolls, DevTools leaves the
 *      <canvas type="2d"> of the custom tab bar's Lottie, PAG and Rive icons where they were, so they move with the
 *      gesture (their y changes, the titles stay) until the bar renders again. Add it to a tab page: it calls the custom
 *      tab bar's cyl_refreshAnimationLayout(true) on every scroll event, and cyl_refreshAnimationLayout(false) 100 ms after
 *      the last one (cyl-lottie shows still images in between, also for a looping icon); the custom tab bar forwards it
 *      to cyl-tab-bar. (Every 50 ms was not enough: the icons still lagged a few pixels behind.) Elsewhere (on a phone) it adds nothing, so the page does
 *      not pay for scroll events it does not need.
 * [CN] 用于微信开发者工具中 Tab 动画图标的页面 behavior：页面滚动时，开发者工具会把自定义 TabBar 中 Lottie、PAG、Rive
 *      图标的 <canvas type="2d"> 留在原处，使其随手势移动（y 坐标改变，标题不动），直到 TabBar 再次渲染。把它加到 Tab
 *      页面上：每个滚动事件都调用自定义 TabBar 的 cyl_refreshAnimationLayout(true)，最后一次滚动事件 100 ms 后调用
 *      cyl_refreshAnimationLayout(false)（期间 cyl-lottie 显示静态图片，循环播放的图标也一样）；
 *      自定义 TabBar 把它转给 cyl-tab-bar。（每 50 ms 一次不够：图标仍会落后几个像素。）在其他环境（真机）不添加任何内容，页面不为不需要的滚动事件付出代价。
 */
const CYL_SCROLL_SETTLE_MS = 100

/**
 * [EN] Whether the mini program runs in WeChat DevTools.
 * [CN] 小程序是否运行在微信开发者工具中。
 */
function cylIsDevTools() {
  try {
    const info = typeof wx.getDeviceInfo === 'function' ? wx.getDeviceInfo() : wx.getSystemInfoSync()
    return info.platform === 'devtools'
  } catch (error) {
    return false
  }
}

/**
 * [EN] Asks the page's custom tab bar to put its animated icons back.
 * [CN] 请页面的自定义 TabBar 让动画图标回到原位。
 */
function cylRefresh(page, scrolling) {
  const tabBar = typeof page.getTabBar === 'function' ? page.getTabBar() : null
  if (tabBar && typeof tabBar.cyl_refreshAnimationLayout === 'function') {
    tabBar.cyl_refreshAnimationLayout(scrolling)
  }
}

const cylMethods = {
  onPageScroll() {
    clearTimeout(this.cylScrollTimer)
    cylRefresh(this, true)
    this.cylScrollTimer = setTimeout(() => cylRefresh(this, false), CYL_SCROLL_SETTLE_MS)
  },
}

module.exports = Behavior({
  methods: typeof wx !== 'undefined' && cylIsDevTools() ? cylMethods : {},
  lifetimes: {
    detached() {
      clearTimeout(this.cylScrollTimer)
    },
  },
})
