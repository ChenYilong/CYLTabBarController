/**
 * [EN] Home: what the tab bar below is made of (the configuration in use).
 * [CN] 首页：说明下方 TabBar 的组成（当前使用的配置）。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylDemoConfiguration } = require('../../utils/cyl_demo_configuration');
const { cylIsItemEligible } = require('../../components/cyl-tab-bar/cyl_configuration');

Component({
  behaviors: [cylTabPage],
  data: { rows: [] },
  pageLifetimes: {
    show() {
      const configuration = cylDemoConfiguration(getApp().globalData.cylTabBarState.overrides);
      const titles = configuration.CYLTabBarControllerTabBarItemsAttributes
        .filter((item) => cylIsItemEligible(item, {}))
        .map((item) => this.t(item.CYLTabBarItemTitle));
      this.setData({
        rows: [
          { label: this.t('Context'), value: configuration.CYLTabBarControllerContext },
          { label: this.t('Style type'), value: configuration.CYLTabBarControllerStyleType },
          { label: this.t('Skin'), value: getApp().globalData.cylTabBarState.themeIdentifier || configuration.CYLTabBarControllerThemeIdentifier },
          { label: this.t('Tabs'), value: titles.join(', ') },
          { label: this.t('Plus button'), value: this.t('Raised, with its own page') },
        ],
      });
    },
  },
});
