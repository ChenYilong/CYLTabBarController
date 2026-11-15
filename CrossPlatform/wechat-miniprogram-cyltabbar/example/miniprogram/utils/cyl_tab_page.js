/**
 * [EN] A behavior for the tab pages: keeps the custom tab bar's selection on the page, gives the page its texts
 *      (`texts[key]` in WXML, t(key) in JS) and swipes between tabs.
 * [CN] Tab 页面的 behavior：让自定义 TabBar 的选中状态跟随页面，为页面提供文字（WXML 中为 `texts[key]`，JS 中为 t(key)），
 *      并支持滑动切换 Tab。
 */
const { t } = require('./cyl_demo_localization');
const cylDemoStrings = require('./cyl_demo_strings');
const cylSwipeBehavior = require('cyl-tabbar-miniprogram/cyl-tab-bar/cyl_swipe_behavior');

module.exports = Behavior({
  behaviors: [cylSwipeBehavior],
  data: {
    texts: {},
    // [EN] The view was unloaded on a memory warning; it is built again when the page shows. [CN] 视图因内存警告被卸载；页面显示时重新创建。
    cylUnloaded: false,
  },
  lifetimes: {
    detached() {
      const app = getApp();
      if (app.cylLoadedTabPages && app.cylLoadedTabPages[this.route] === this) {
        delete app.cylLoadedTabPages[this.route];
      }
    },
    attached() {
      // [EN] The loaded pages, for the memory warning report (app.js cyl_simulateMemoryWarning). [CN] 已加载的页面，用于内存警告报告。
      const app = getApp();
      app.cylLoadedTabPages = app.cylLoadedTabPages || {};
      app.cylLoadedTabPages[this.route] = this;
      const texts = {};
      Object.keys(cylDemoStrings.en).forEach((key) => {
        texts[key] = t(key);
      });
      this.setData({ texts });
    },
  },
  pageLifetimes: {
    show() {
      if (this.data.cylUnloaded) {
        this.setData({ cylUnloaded: false });
      }
      if (typeof this.getTabBar === 'function' && this.getTabBar()) {
        this.getTabBar().cyl_syncWithRoute(this.route);
      }
    },
  },
  methods: {
    t,
    /**
     * [EN] Unloads the page's view (-[UIViewController setView:nil]): its whole tree goes until the page shows again.
     *      Returns whether there was a view to unload.
     * [CN] 卸载页面视图（-[UIViewController setView:nil]）：整个视图树移除，直到页面再次显示。返回是否有可卸载的视图。
     */
    cyl_unloadView() {
      if (this.data.cylUnloaded) {
        return false;
      }
      this.setData({ cylUnloaded: true });
      return true;
    },
  },
});
