/**
 * [EN] The mini program's custom tab bar (app.json: "tabBar": {"custom": true}). It passes the example's configuration
 *      to cyl-tab-bar, switches pages on `select`, and follows the app's tab bar state (badges, skin, overrides,
 *      login). Tab pages call cyl_syncWithRoute() in onShow so the selection follows the page.
 * [CN] 小程序的自定义 TabBar（app.json："tabBar": {"custom": true}）。它把示例配置传给 cyl-tab-bar，在 `select` 时切换
 *      页面，并跟随 App 的 TabBar 状态（角标、皮肤、覆盖项、登录）。Tab 页面在 onShow 中调用 cyl_syncWithRoute()，
 *      使选中状态跟随页面。
 */
const { cylDemoConfiguration } = require('../utils/cyl_demo_configuration');
const { t, cylConfigurationTable } = require('../utils/cyl_demo_localization');
const cylSymbolsByTheme = require('../shared/symbols');

/**
 * [EN] The page path of a page identifier: pages/<pageIdentifier>/index.
 * [CN] 页面标识对应的页面路径：pages/<页面标识>/index。
 */
function cylPagePath(pageIdentifier) {
  return `pages/${pageIdentifier}/index`;
}

Component({
  data: {
    configuration: {},
    strings: {},
    symbolsByTheme: cylSymbolsByTheme,
    selectedIdentifier: '',
    loggedIn: false,
  },

  lifetimes: {
    attached() {
      const app = getApp();
      this.setData({ strings: cylConfigurationTable() });
      this.cyl_apply(app.globalData.cylTabBarState);
      this.cylUnsubscribe = app.cyl_subscribe((state) => this.cyl_apply(state));
    },
    detached() {
      if (this.cylUnsubscribe) {
        this.cylUnsubscribe();
      }
    },
  },

  methods: {
    /**
     * [EN] Applies the app's tab bar state to this instance.
     * [CN] 把 App 的 TabBar 状态应用到本实例。
     */
    cyl_apply(state) {
      this.setData({
        configuration: cylDemoConfiguration(state.overrides),
        loggedIn: state.loggedIn,
        itemStyle: state.itemStyle || '',
        glassLensStyle: state.glassLensStyle || 'regular',
        animationSpeed: state.animationSpeed || 1,
        animationLoop: Boolean(state.animationLoop),
      }, () => {
        const tabBar = this.selectComponent('#cyl-tab-bar');
        if (!tabBar) {
          return;
        }
        tabBar.cyl_setThemeIdentifier(state.themeIdentifier);
        Object.keys(state.badges).forEach((identifier) => {
          const value = state.badges[identifier];
          if (value === '' || value === null || value === undefined) {
            tabBar.cyl_removeBadge(identifier);
          } else {
            tabBar.cyl_showBadgeValue(identifier, value);
          }
        });
      });
    },

    /**
     * [EN] Selects the tab whose page is the current page.
     * [CN] 选中页面为当前页面的 Tab。
     */
    cyl_syncWithRoute(route) {
      const configuration = this.data.configuration;
      const items = (configuration.CYLTabBarControllerTabBarItemsAttributes || [])
        .concat(configuration.CYLTabBarControllerPlusButton ? [configuration.CYLTabBarControllerPlusButton] : []);
      const item = items.find((attributes) => cylPagePath(attributes.CYLTabBarItemPageIdentifier
        || attributes.CYLTabBarItemIdentifier) === route);
      if (item) {
        this.setData({ selectedIdentifier: item.CYLTabBarItemIdentifier }, () => {
          // [EN] Each tab page has its own tab bar, so the page that appears plays the selected Lottie icon.
          // [CN] 每个 Tab 页面都有自己的 TabBar，因此由出现的页面播放选中 Tab 的 Lottie 图标。
          const tabBar = this.selectComponent('#cyl-tab-bar');
          if (tabBar) {
            tabBar.cyl_playLottie(item.CYLTabBarItemIdentifier);
          }
        });
      }
    },

    /**
     * [EN] A horizontal swipe on a page (cyl_swipe_behavior.js): the next or previous tab, when the configuration
     *      allows it (CYLTabBarControllerSwipeToSwitchTab).
     * [CN] 页面上的水平滑动（cyl_swipe_behavior.js）：在配置允许时（CYLTabBarControllerSwipeToSwitchTab）切换到下一个
     *      或上一个 Tab。
     */
    cyl_swipe(step) {
      const tabBar = this.selectComponent('#cyl-tab-bar');
      return tabBar ? tabBar.cyl_selectAdjacent(step) : false;
    },

    /**
     * [EN] A page scrolls (cyl_scroll_behavior.js, WeChat DevTools only): the animated icons go back into the bar.
     * [CN] 页面滚动（cyl_scroll_behavior.js，仅微信开发者工具）：动画图标回到 TabBar 内。
     */
    cyl_refreshAnimationLayout() {
      const tabBar = this.selectComponent('#cyl-tab-bar');
      if (tabBar) {
        tabBar.cyl_refreshAnimationLayout();
      }
    },

    cyl_onSelect(event) {
      wx.switchTab({ url: `/${cylPagePath(event.detail.pageIdentifier)}` });
    },

    cyl_onReselect() {
      wx.pageScrollTo({ scrollTop: 0, duration: 200 });
    },

    cyl_onPlusTap() {
      wx.showToast({ title: t('Post'), icon: 'none' });
    },

    /**
     * [EN] A tab that needs login: asks the user to log in, then opens the tab.
     * [CN] 需要登录的 Tab：请用户登录，然后打开该 Tab。
     */
    cyl_onLoginRequired(event) {
      const pageIdentifier = event.detail.pageIdentifier;
      wx.showModal({
        title: t('Login'),
        content: t('Log in to open this tab'),
        confirmText: t('Log in'),
        cancelText: t('Cancel'),
        success: (result) => {
          if (result.confirm) {
            getApp().cyl_updateTabBarState({ loggedIn: true });
            wx.switchTab({ url: `/${cylPagePath(pageIdentifier)}` });
          }
        },
      });
    },
  },
});
