/**
 * [EN] Message: a tab page of the configuration. Its CYLTabBarItemPlatforms is "ios,android", so the bar leaves it out
 *      in the mini program; the page stays in app.json for configurations that show it.
 * [CN] 消息：配置中的一个 Tab 页面。它的 CYLTabBarItemPlatforms 为 "ios,android"，因此小程序中的 TabBar 不显示它；
 *      页面保留在 app.json 中，供显示它的配置使用。
 */
const cylTabPage = require('../../utils/cyl_tab_page');

Component({
  behaviors: [cylTabPage],
  data: {
    // [EN] The Liquid Glass gallery's panels (pages/glass). [CN] 液态玻璃画廊的面板（pages/glass）。
    discoverHidden: false,
    tabBarHidden: false,
    galleryRows: [
      { panel: 'checkin', title: 'Liquid Glass gallery: Check-in' },
      { panel: 'feed', title: 'Navigation bar, search and feed' },
      { panel: 'cards', title: 'Collection view' },
      { panel: 'landing', title: 'Landing, tap animations and item styles' },
    ],
  },
  pageLifetimes: {
    show() {
      this.setData({ discoverHidden: (getApp().globalData.cylTabBarState.hiddenIdentifiers || []).includes('discover') });
    },
  },
  methods: {
    /**
     * [EN] Hides Discover in every bar, as an app does for a user role (cyl-tab-bar hiddenIdentifiers).
     * [CN] 在所有 TabBar 中隐藏「发现」，如同 App 按用户角色所做的那样（cyl-tab-bar 的 hiddenIdentifiers）。
     */
    cyl_hideDiscover(event) {
      const hidden = Boolean(event.detail.value);
      const others = (getApp().globalData.cylTabBarState.hiddenIdentifiers || []).filter((identifier) => identifier !== 'discover');
      this.setData({ discoverHidden: hidden });
      getApp().cyl_updateTabBarState({ hiddenIdentifiers: hidden ? others.concat('discover') : others });
    },

    /**
     * [EN] Hides this page's bar only (cyl-tab-bar cyl_setTabBarHidden, iOS -setTabBarHidden:).
     * [CN] 只隐藏本页面的 TabBar（cyl-tab-bar 的 cyl_setTabBarHidden，iOS -setTabBarHidden:）。
     */
    cyl_hideTabBar(event) {
      const hidden = Boolean(event.detail.value);
      this.setData({ tabBarHidden: hidden });
      if (typeof this.getTabBar === 'function' && this.getTabBar()) {
        this.getTabBar().cyl_setTabBarHidden(hidden);
      }
    },

    cyl_openGallery(event) {
      wx.navigateTo({ url: `/pages/glass/index?panel=${event.currentTarget.dataset.panel}` });
    },
  },
});
