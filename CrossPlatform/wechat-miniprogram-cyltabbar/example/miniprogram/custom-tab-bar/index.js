/**
 * [EN] The mini program's custom tab bar (app.json: "tabBar": {"custom": true}). It passes the example's configuration
 *      to cyl-tab-bar, switches pages on `select`, and follows the app's tab bar state (badges, skin, overrides,
 *      login). Tab pages call cyl_syncWithRoute() in onShow so the selection follows the page.
 * [CN] 小程序的自定义 TabBar（app.json："tabBar": {"custom": true}）。它把示例配置传给 cyl-tab-bar，在 `select` 时切换
 *      页面，并跟随 App 的 TabBar 状态（角标、皮肤、覆盖项、登录）。Tab 页面在 onShow 中调用 cyl_syncWithRoute()，
 *      使选中状态跟随页面。
 */
const { cylDemoConfiguration } = require('../utils/cyl_demo_configuration');
const { cylEffectiveSkin } = require('../utils/cyl_demo_skins');
const { t, cylConfigurationTable, cylIsRightToLeft } = require('../utils/cyl_demo_localization');
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
    animationSpeed: 1,
  },

  lifetimes: {
    attached() {
      const app = getApp();
      // [EN] The configuration's table plus the Objective-C example's tab titles in the example's language.
      // [CN] 配置的本地化表，加上示例语言的 Objective-C 示例 Tab 标题。
      const titles = {};
      ['Home', 'Refresh', 'Nearby', 'Messages', 'Me', 'Post'].forEach((title) => {
        titles[title] = t(title);
      });
      this.setData({ strings: Object.assign({}, cylConfigurationTable(), titles), rtl: cylIsRightToLeft() });
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
      const skin = cylEffectiveSkin(state);
      this.setData({
        configuration: cylDemoConfiguration(state.overrides, skin),
        loggedIn: state.loggedIn,
        itemStyle: state.itemStyle || '',
        glassLensStyle: state.glassLensStyle || 'regular',
        animationSpeed: state.animationSpeed || 1,
        animationLoop: Boolean(state.animationLoop),
        hiddenIdentifiers: state.hiddenIdentifiers || [],
      }, () => {
        const tabBar = this.selectComponent('#cyl-tab-bar');
        if (!tabBar) {
          return;
        }
        // [EN] A skin with colors and a standardAppearance theme are skins the configuration selects (utils/cyl_demo_skins.js,
        //      utils/cyl_demo_updates.js). [CN] 带颜色的皮肤与 standardAppearance 主题都是配置所选的皮肤。
        const configured = String(this.data.configuration.CYLTabBarControllerThemeIdentifier || '').includes(':');
        tabBar.cyl_setThemeIdentifier(configured ? '' : state.themeIdentifier);
        tabBar.cyl_setTabBarHidden(Boolean(state.tabBarHidden));
        const attributes = this.cyl_badgeAttributesInSkin(state.badgeAttributes || {}, state.badges, skin);
        Object.keys(state.badges).forEach((identifier) => {
          const value = state.badges[identifier];
          if (value === '' || value === null || value === undefined) {
            tabBar.cyl_removeBadge(identifier);
          } else {
            tabBar.cyl_showBadgeValue(identifier, value, attributes[identifier]);
          }
        });
        const covers = state.covers || {};
        Object.keys(covers).forEach((identifier) => {
          const cover = covers[identifier];
          tabBar.cyl_setCoverImage(identifier, cover && cover.image, cover && cover.size);
        });
      });
    },

    /**
     * [EN] FlatDesign: a skin's tint colors the badges without a color of their own (`badgeBackgroundColor` of the skin's
     *      appearance); Liquid Glass keeps them red.
     * [CN] 扁平样式：皮肤的 tint 为没有自定颜色的角标着色（皮肤外观的 `badgeBackgroundColor`）；液态玻璃下仍为红色。
     */
    cyl_badgeAttributesInSkin(attributes, badges, skin) {
      if (!skin.tint || this.cyl_isLiquidGlass()) {
        return attributes;
      }
      const tinted = Object.assign({}, attributes);
      // [EN] The plus button's badge is the button's own, not a tab item's: it stays red. [CN] PlusButton 的角标属于按钮本身，不属于 Tab Item：保持红色。
      Object.keys(badges).filter((identifier) => identifier !== 'plus').forEach((identifier) => {
        if (!(tinted[identifier] || {}).color) {
          tinted[identifier] = Object.assign({}, tinted[identifier], { color: skin.tint });
        }
      });
      return tinted;
    },

    cyl_isLiquidGlass() {
      return this.data.itemStyle === 'liquidGlass'
        || (!this.data.itemStyle && this.data.configuration.CYLTabBarControllerStyleType === 'liquidGlass');
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
     * [EN] Hides or shows this page's bar (cyl-tab-bar cyl_setTabBarHidden, iOS -setTabBarHidden:).
     * [CN] 隐藏或显示本页面的 TabBar（cyl-tab-bar 的 cyl_setTabBarHidden，iOS -setTabBarHidden:）。
     */
    cyl_setTabBarHidden(hidden) {
      const tabBar = this.selectComponent('#cyl-tab-bar');
      if (tabBar) {
        tabBar.cyl_setTabBarHidden(hidden);
      }
    },

    cyl_onSelect(event) {
      if (event.detail.isPlusButton) {
        this.cyl_countPlusTap();
      } else {
        this.cyl_markBadge(event.detail.identifier);
      }
      wx.switchTab({ url: `/${cylPagePath(event.detail.pageIdentifier)}` });
    },

    /**
     * [EN] -[MainTabBarController tabBarController:didSelectControl:] (docs/ObjC-Example-Parity item 55): a tap that
     *      selects a tab updates its badge. On Liquid Glass the badge is on the tab's page, not its button, so the tap
     *      turns it into a dot in the badge's color; in the flat style a badge is cleared, and a tab without one gets a
     *      dot that scales once.
     * [CN] -[MainTabBarController tabBarController:didSelectControl:]（docs/ObjC-Example-Parity 第 55 项）：选中 Tab 的点击
     *      会更新其角标。液态玻璃下角标在 Tab 的页面上而不在按钮上，因此点击把它变为同色红点；扁平样式下清除角标，
     *      没有角标的 Tab 显示一个缩放一次的红点。
     */
    cyl_markBadge(identifier) {
      const app = getApp();
      const state = app.globalData.cylTabBarState;
      const badges = Object.assign({}, state.badges);
      const attributes = Object.assign({}, state.badgeAttributes);
      const current = attributes[identifier] || {};
      const hasBadge = badges[identifier] !== undefined && badges[identifier] !== '';
      if (!this.cyl_isLiquidGlass()) {
        badges[identifier] = hasBadge ? '' : '•';
        attributes[identifier] = hasBadge ? {} : { animation: 'scaleOnce' };
      } else {
        badges[identifier] = '•';
        attributes[identifier] = { color: current.color };
      }
      app.cyl_updateTabBarState({ badges, badgeAttributes: attributes });
    },

    /**
     * [EN] -[MainTabBarController cyl_demo_plusButtonDidTap] (item 5): each tap adds 1 to the plus button's badge; on
     *      Liquid Glass the Objective-C example does not count taps, and neither does this one.
     * [CN] -[MainTabBarController cyl_demo_plusButtonDidTap]（第 5 项）：每次点击 PlusButton 角标加 1；液态玻璃下
     *      Objective-C 示例不计数，这里也一样。
     */
    cyl_countPlusTap() {
      const liquidGlass = this.cyl_isLiquidGlass();
      const app = getApp();
      const state = app.globalData.cylTabBarState;
      if (liquidGlass || state.badges.plus === undefined || state.badges.plus === '') {
        return;
      }
      const count = (Number.parseInt(state.badges.plus, 10) || 0) + 1;
      app.cyl_updateTabBarState({ badges: Object.assign({}, state.badges, { plus: String(count) }) });
    },

    /**
     * [EN] The Home switch "Long press on tabs" (issue #535): a long press shows the identifier of the tab or plus button.
     * [CN] 首页「长按 Tab」开关（issue #535）：长按显示 Tab 或 PlusButton 的标识。
     */
    cyl_onLongPress(event) {
      if (getApp().globalData.cylTabBarState.longPressEnabled && event.detail) {
        wx.showToast({ title: String(event.detail.identifier), icon: 'none' });
      }
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
      const { pageIdentifier, identifier, title } = event.detail;
      // [EN] -[MainTabBarController cyl_demo_presentLoginForViewController:completion:]: the alert logs in, then
      //      selects the tapped tab (and updates its badge, as a tap would).
      // [CN] 弹窗登录后选中所点击的 Tab（并像点击一样更新其角标）。
      wx.showModal({
        title: t('Login required'),
        content: t('Log in to view “{title}”').replace('{title}', title || ''),
        confirmText: t('Log in'),
        cancelText: t('Cancel'),
        success: (result) => {
          if (result.confirm) {
            getApp().cyl_updateTabBarState({ loggedIn: true });
            this.cyl_markBadge(identifier);
            wx.switchTab({ url: `/${cylPagePath(pageIdentifier)}` });
          }
        },
      });
    },
  },
});
