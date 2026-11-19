/**
 * [EN] Discover: the page "web" with the tab's CYLTabBarItemPageParameters ({url}). A mini program opens a web page
 *      only from a business domain set in the WeChat admin console, so the page shows the link and copies it.
 * [CN] 发现：页面 "web"，带有该 Tab 的 CYLTabBarItemPageParameters（{url}）。小程序只能打开在微信后台配置的业务域名中的
 *      网页，因此本页显示链接并可复制。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylDemoConfiguration, cylReplacedPage } = require('../../utils/cyl_demo_configuration');
const { cylFeedRows } = require('../../utils/cyl_feed_rows');

Component({
  behaviors: [cylTabPage],
  data: { url: '', feedRows: [], replaced: null },
  lifetimes: {
    attached() {
      const item = cylDemoConfiguration().CYLTabBarControllerTabBarItemsAttributes
        .find((attributes) => attributes.CYLTabBarItemPageIdentifier === 'web');
      this.setData({ feedRows: cylFeedRows() });
      this.setData({ url: item?.CYLTabBarItemPageParameters ? item.CYLTabBarItemPageParameters.url : '' });
      this.cylUnsubscribe = getApp().cyl_subscribe(() => this.cyl_showReplaced());
      this.cyl_showReplaced();
    },
    detached() {
      if (this.cylUnsubscribe) {
        this.cylUnsubscribe();
      }
    },
  },
  methods: {
    /**
     * [EN] The Home row "Replace neighboring tabs": this tab shows a plain page with its title and color.
     * [CN] 首页「替换相邻 Tab 的页面」行：本 Tab 显示带标题与颜色的空白页面。
     */
    cyl_showReplaced() {
      const replaced = cylReplacedPage(getApp().globalData.cylTabBarState.overrides, 'city');
      if (JSON.stringify(replaced) !== JSON.stringify(this.data.replaced)) {
        this.setData({ replaced });
      }
      wx.setNavigationBarTitle({ title: replaced ? replaced.title : 'CYLTabBarController' });
    },

    // [EN] A parameter row: copies its value. [CN] 参数行：复制其值。
    cyl_copyValue(event) {
      wx.setClipboardData({ data: String(event.currentTarget.dataset.value) });
    },

    // [EN] CYLSameCityViewController: pushes CYLDetailsViewController (orange, no navigation bar, pop gesture off).
    // [CN] CYLSameCityViewController：push CYLDetailsViewController（橙色、无导航栏、关闭返回手势）。
    cyl_onFeedRow() {
      wx.navigateTo({ url: `/pages/pushed/locked?color=orange&toMe=1&note=${encodeURIComponent('Tap the screen to go to Me and run testPush')}` });
    },

    cyl_copyLink() {
      wx.setClipboardData({
        data: this.data.url,
        success: () => wx.showToast({ title: this.t('Link copied'), icon: 'none' }),
      });
    },
  },
});
