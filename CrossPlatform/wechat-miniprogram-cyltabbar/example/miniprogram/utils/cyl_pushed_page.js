/**
 * [EN] The page an iOS tab pushes from its feed (CYLBaseViewController): a colored page, its own back button since the
 *      iOS page hides the navigation bar (`-cyl_setNavigationBarHidden:`), and, for the Message rows, a live tab bar
 *      like the tab bar controller iOS pushes. Options: color, note (a string key), bar ('same' | 'close' | 'other'),
 *      toMe ('1': a tap on the page goes to Me and runs its push, as CYLDetailsViewController). pages/pushed/index
 *      keeps the pop gesture, pages/pushed/locked turns it off (`-cyl_setDisablePopGestureRecognizer:YES`).
 * [CN] iOS Tab 从信息流 push 的页面（CYLBaseViewController）：带颜色的页面；iOS 页面隐藏导航栏（`-cyl_setNavigationBarHidden:`），
 *      因此有自己的返回按钮；消息页的行还带有实时 TabBar，与 iOS push 的 TabBarController 相同。参数：color、note（字符串键）、
 *      bar（'same' | 'close' | 'other'）、toMe（'1'：点击页面跳到「我的」并执行其 push，与 CYLDetailsViewController 相同）。
 *      pages/pushed/index 保留返回手势，pages/pushed/locked 关闭它（`-cyl_setDisablePopGestureRecognizer:YES`）。
 */
const { t } = require('./cyl_demo_localization');
const { cylDemoConfiguration } = require('./cyl_demo_configuration');

const CYL_PUSHED_COLORS = { orange: '#FF9500', red: '#FF3B30' };
// [EN] "The other plus button" (CYLPlusButtonSubclass alternatePlusButtonClassForOwner:). [CN] 「另一个 PlusButton」。
const CYL_OTHER_PLUS = { CYLTabBarItemTitle: 'Camera', CYLTabBarItemImage: 'system:camera.circle', CYLTabBarItemSelectedImage: 'system:camera.circle.fill' };

function cylRandomColor() {
  return `#${Math.floor(Math.random() * 0xFFFFFF).toString(16).padStart(6, '0')}`;
}

function cylPushedPage() {
  return {
    data: { color: CYL_PUSHED_COLORS.orange, note: '', bar: '', toMe: false, configuration: null, closeColor: '#FF3B30', texts: {} },
    onLoad(options) {
      const bar = options.bar || '';
      let configuration = null;
      if (bar) {
        configuration = cylDemoConfiguration(Object.assign({}, getApp().globalData.cylTabBarState.overrides,
          bar === 'other' ? { cylDemoPlusAttributes: CYL_OTHER_PLUS } : {}));
      }
      this.setData({
        color: CYL_PUSHED_COLORS[options.color] || CYL_PUSHED_COLORS.orange,
        note: options.note ? t(decodeURIComponent(options.note)) : '',
        bar,
        toMe: options.toMe === '1',
        configuration,
        texts: { Back: t('Back'), close: t('Close button of the plus button') },
      });
    },
    cyl_back() {
      wx.navigateBack();
    },
    // [EN] CYLDetailsViewController: a tap goes to Me and runs its testPush. [CN] 点击跳到「我的」并执行 testPush。
    cyl_tapPage() {
      if (!this.data.toMe) {
        return;
      }
      wx.switchTab({
        url: '/pages/me/index',
        success: () => wx.navigateTo({ url: '/pages/pushed/locked?color=red&note=Pushed%20by%20Me%3A%20the%20pop%20gesture%20is%20off' }),
      });
    },
    // [EN] Issue #202: the X changes color, the plus button does not respond. [CN] Issue #202：X 随机变色，PlusButton 不响应。
    cyl_tapClose() {
      this.setData({ closeColor: cylRandomColor() });
    },
    cyl_plusTap() {
      wx.showToast({ title: this.data.configuration.CYLTabBarControllerPlusButton.CYLTabBarItemTitle, icon: 'none' });
    },
  };
}

module.exports = { cylPushedPage };
