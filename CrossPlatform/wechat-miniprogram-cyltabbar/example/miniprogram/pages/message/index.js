/**
 * [EN] Message: a tab page of the configuration. Its CYLTabBarItemPlatforms is "ios,android", so the bar leaves it out
 *      in the mini program; the page stays in app.json for configurations that show it.
 * [CN] 消息：配置中的一个 Tab 页面。它的 CYLTabBarItemPlatforms 为 "ios,android"，因此小程序中的 TabBar 不显示它；
 *      页面保留在 app.json 中，供显示它的配置使用。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylFeedRows } = require('../../utils/cyl_feed_rows');
const { t } = require('../../utils/cyl_demo_localization');

Component({
  behaviors: [cylTabPage],
  data: {
    // [EN] The Liquid Glass gallery's panels (pages/glass). [CN] 液态玻璃画廊的面板（pages/glass）。
    discoverHidden: false,
    tabBarHidden: false,
    feedRows: [],
    galleryRows: [
      { panel: 'checkin', title: 'Liquid Glass gallery: Check-in' },
      { panel: 'feed', title: 'Navigation bar, search and feed' },
      { panel: 'cards', title: 'Collection view' },
      { panel: 'landing', title: 'Landing, tap animations and item styles' },
    ],
  },
  lifetimes: {
    attached() {
      // [EN] CYLMessageViewController: rows 0 and 1 push tab bar controllers, the others the other plus button.
      // [CN] CYLMessageViewController：第 0、1 行 push TabBarController，其余 push 另一个 PlusButton。
      const rows = cylFeedRows();
      rows[0] = { ...rows[0], title: t('Push a tab bar controller of the same context (same plus button class)'), subtitle: rows[0].title };
      rows[1] = { ...rows[1], title: t('Push a tab bar controller of a new context (plus button with a tappable X, issue #202)'), subtitle: t('Tap the X at the top right of the plus button: the X changes color, the plus button does not respond') };
      this.setData({ feedRows: rows });
    },
  },
  pageLifetimes: {
    show() {
      this.setData({ discoverHidden: (getApp().globalData.cylTabBarState.hiddenIdentifiers || []).includes('city') });
    },
  },
  methods: {
    /**
     * [EN] Hides Discover in every bar, as an app does for a user role (cyl-tab-bar hiddenIdentifiers).
     * [CN] 在所有 TabBar 中隐藏「发现」，如同 App 按用户角色所做的那样（cyl-tab-bar 的 hiddenIdentifiers）。
     */
    cyl_hideDiscover(event) {
      const hidden = Boolean(event.detail.value);
      const others = (getApp().globalData.cylTabBarState.hiddenIdentifiers || []).filter((identifier) => identifier !== 'city');
      this.setData({ discoverHidden: hidden });
      getApp().cyl_updateTabBarState({ hiddenIdentifiers: hidden ? others.concat('city') : others });
    },

    /**
     * [EN] Hides this page's bar only (cyl-tab-bar cylSetTabBarHidden, iOS -setTabBarHidden:).
     * [CN] 只隐藏本页面的 TabBar（cyl-tab-bar 的 cylSetTabBarHidden，iOS -setTabBarHidden:）。
     */
    cyl_hideTabBar(event) {
      const hidden = Boolean(event.detail.value);
      this.setData({ tabBarHidden: hidden });
      if (typeof this.getTabBar === 'function' && this.getTabBar()) {
        this.getTabBar().cylSetTabBarHidden(hidden);
      }
    },

    cyl_onFeedRow(event) {
      const index = Number(event.currentTarget.dataset.index);
      const bar = ['same', 'close'][index] || 'other';
      const notes = { same: 'Same context, same plus button class', close: 'New context: the plus button has a tappable X', other: 'The other plus button' };
      wx.navigateTo({ url: `/pages/pushed/index?bar=${bar}&color=orange&note=${encodeURIComponent(notes[bar])}` });
    },

    cyl_openGallery(event) {
      wx.navigateTo({ url: `/pages/glass/index?panel=${event.currentTarget.dataset.panel}` });
    },
  },
});
