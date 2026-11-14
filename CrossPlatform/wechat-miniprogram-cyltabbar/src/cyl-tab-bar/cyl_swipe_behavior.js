/**
 * [EN] A page behavior for CYLTabBarControllerSwipeToSwitchTab: add it to a tab page and bind its handlers on the
 *      page's root view (bindtouchstart="cyl_onSwipeStart" bindtouchend="cyl_onSwipeEnd"); a horizontal swipe of more
 *      than 60 px asks the custom tab bar for the next (swipe left) or previous (swipe right) tab. The custom tab bar
 *      forwards it to cyl-tab-bar's cyl_selectAdjacent(), which does nothing when the key is off.
 * [CN] 用于 CYLTabBarControllerSwipeToSwitchTab 的页面 behavior：加到 Tab 页面上，并在页面根视图上绑定处理函数
 *      （bindtouchstart="cyl_onSwipeStart" bindtouchend="cyl_onSwipeEnd"）；超过 60 px 的水平滑动会请自定义 TabBar
 *      切换到下一个（向左滑）或上一个（向右滑）Tab。自定义 TabBar 把它转给 cyl-tab-bar 的 cyl_selectAdjacent()，
 *      该键关闭时不做任何事。
 */
const CYL_SWIPE_DISTANCE = 60

module.exports = Behavior({
  methods: {
    cyl_onSwipeStart(event) {
      const touch = event.touches && event.touches[0]
      this.cylSwipeStart = touch ? {x: touch.clientX, y: touch.clientY} : null
    },
    cyl_onSwipeEnd(event) {
      const start = this.cylSwipeStart
      const touch = event.changedTouches && event.changedTouches[0]
      this.cylSwipeStart = null
      if (!start || !touch) {
        return
      }
      const dx = touch.clientX - start.x
      const dy = touch.clientY - start.y
      if (Math.abs(dx) < CYL_SWIPE_DISTANCE || Math.abs(dx) < Math.abs(dy) * 2) {
        return
      }
      const tabBar = typeof this.getTabBar === 'function' ? this.getTabBar() : null
      if (tabBar && typeof tabBar.cyl_swipe === 'function') {
        tabBar.cyl_swipe(dx < 0 ? 1 : -1)
      }
    },
  },
})
