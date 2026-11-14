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
  },
  lifetimes: {
    attached() {
      const texts = {};
      Object.keys(cylDemoStrings.en).forEach((key) => {
        texts[key] = t(key);
      });
      this.setData({ texts });
    },
  },
  pageLifetimes: {
    show() {
      if (typeof this.getTabBar === 'function' && this.getTabBar()) {
        this.getTabBar().cyl_syncWithRoute(this.route);
      }
    },
  },
  methods: {
    t,
  },
});
