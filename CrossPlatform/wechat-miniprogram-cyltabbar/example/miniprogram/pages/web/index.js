/**
 * [EN] Discover: the page "web" with the tab's CYLTabBarItemPageParameters ({url}). A mini program opens a web page
 *      only from a business domain set in the WeChat admin console, so the page shows the link and copies it.
 * [CN] 发现：页面 "web"，带有该 Tab 的 CYLTabBarItemPageParameters（{url}）。小程序只能打开在微信后台配置的业务域名中的
 *      网页，因此本页显示链接并可复制。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylDemoConfiguration } = require('../../utils/cyl_demo_configuration');

Component({
  behaviors: [cylTabPage],
  data: { url: '' },
  lifetimes: {
    attached() {
      const item = cylDemoConfiguration().CYLTabBarControllerTabBarItemsAttributes
        .find((attributes) => attributes.CYLTabBarItemPageIdentifier === 'web');
      this.setData({ url: item && item.CYLTabBarItemPageParameters ? item.CYLTabBarItemPageParameters.url : '' });
    },
  },
  methods: {
    cyl_copyLink() {
      wx.setClipboardData({
        data: this.data.url,
        success: () => wx.showToast({ title: this.t('Link copied'), icon: 'none' }),
      });
    },
  },
});
