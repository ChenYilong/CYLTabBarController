/**
 * [EN] The cyl-tab-bar-item playground: the item component on its own, one tile per group of the iOS
 *      CYLFlatDesignTabBarItem API (docs/WeChat-Mini-Program.md, "cyl-tab-bar-item and CYLFlatDesignTabBarItem").
 * [CN] cyl-tab-bar-item 演示页：单独使用 Item 组件，每格对应 iOS CYLFlatDesignTabBarItem 的一组 API
 *      （docs/WeChat-Mini-Program.md「cyl-tab-bar-item and CYLFlatDesignTabBarItem」）。
 */
const L = '/shared/lottie/';
const S = '/shared/skins/2.1.0/light/';

Page({
  data: {
    tiles: [
      { caption: 'title, image, selectedImage', props: { title: 'Home', image: `${S}home@3x.png`, selectedImage: `${S}home_selected@3x.png`, selected: true } },
      { caption: 'lottieFilePath, lottieSizeValue', props: { title: 'Lottie', lottieFilePath: `${L}green_lottie_tab_home.json`, lottieSizeValue: '{36, 36}', selected: true } },
      { caption: 'badgeValue, badgeColor', props: { title: 'Badge', image: `${S}message@3x.png`, badgeValue: '8', badgeColor: '#34C759' } },
      { caption: 'badgeSize, badgePositionAdjustment', props: { title: 'Dot', image: `${S}me@3x.png`, badgeSize: '{10, 10}', badgePositionAdjustment: '{4, -2}' } },
      { caption: 'badgeContentInset, badgeTextAttributes', props: { title: 'Inset', image: `${S}discover@3x.png`, badgeValue: 'NEW', badgeContentInset: '{2, 8, 2, 8}', badgeTextAttributes: { normal: { color: '#FFFF00', font: 'bold:9' } } } },
      { caption: 'titleTextAttributes', props: { title: 'Styled', image: `${S}home@3x.png`, selected: true, titleTextAttributes: { normal: { color: '#8E8E93' }, selected: { color: '#FF2D55', font: 'bold:12' } } } },
      { caption: 'titlePositionAdjustment, imagePositionAdjustment', props: { title: 'Offset', image: `${S}home@3x.png`, titlePositionAdjustment: '{0, 4}', imagePositionAdjustment: '{0, -4}' } },
      { caption: 'imageInsets', props: { title: 'Insets', image: `${S}home@3x.png`, imageInsets: '{6, 0, -6, 0}' } },
      { caption: 'layoutCentered (no image)', props: { title: 'Centered', layoutCentered: true } },
      { caption: 'backgroundColor, selectedBackgroundColor', props: { title: 'Bg', image: `${S}home@3x.png`, selected: true, backgroundColor: '#F2F2F7', selectedBackgroundColor: '#E5F1FF' } },
      { caption: 'standardAppearance', props: { title: 'Appear', image: `${S}home@3x.png`, selected: true, standardAppearance: { stackedLayoutAppearance: { selected: { iconColor: '#AF52DE', titleTextAttributes: { color: '#AF52DE' }, badgeBackgroundColor: '#AF52DE' } } }, badgeValue: '2' } },
      { caption: 'enabled = NO', props: { title: 'Disabled', image: `${S}home@3x.png`, enabled: false } },
    ],
  },
  cyl_itemTap(event) {
    wx.showToast({ title: `itemtap ${event.detail.index}`, icon: 'none' });
  },
});
