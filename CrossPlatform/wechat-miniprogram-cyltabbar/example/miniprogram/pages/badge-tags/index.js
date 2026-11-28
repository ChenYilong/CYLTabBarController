/**
 * [EN] docs/Animated-Item-Badge-CrossPlatform.md: badges on tags that are a cyl-animated-item. A tag only passes badge-value and
 *      badge-attributes; nothing is stacked on the icon by this page. RollingOnce has no CSS class in the mini program, so that
 *      badge stays still; the component does not read the system's Reduce Motion setting.
 * [CN] docs/Animated-Item-Badge-CrossPlatform.md：本身为 cyl-animated-item 的 Tag 上的角标。Tag 只传 badge-value 与 badge-attributes；
 *      本页面不在图标上叠加任何组件。小程序中 RollingOnce 没有 CSS 类，因此该角标保持静止；组件不读取系统的"减弱动态效果"设置。
 */
const cylImage = (theme) => `/shared/skins/2.1.0/${theme === 'dark' ? 'dark' : 'light'}/home@3x.png`;
// [EN] The value of the component's cylAnimatedItemCornerRadiusCapsule; CSS limits it to half the height. [CN] 与组件的 cylAnimatedItemCornerRadiusCapsule 相同；CSS 将其限制为高度的一半。
const CAPSULE = 1000;

// [EN] The first nine badge samples, as on HarmonyOS. [CN] 前九个角标示例，与鸿蒙相同。
const SAMPLES = [
  ['3', 'Scale', false],
  ['3', 'Shake', false],
  ['3', 'Bounce', false],
  ['', 'Breathe', false],
  ['3', 'Shake', true],
  ['new', 'RollingOnce', false],
  ['3', 'ScaleOnce', false],
  ['8', 'None', false],
  ['100', 'None', false],
];

Page({
  data: {
    image: cylImage('light'),
    capsule: CAPSULE,
    shows: true,
    tags: SAMPLES.map(([value, animation, reduce], index) => ({
      id: `cyl-badge-tag-${index + 1}`,
      title: `${index + 1}. ${animation}${reduce ? ', Reduce Motion' : ''}`,
      value,
      attributes: { animation, respectsReduceMotion: reduce },
    })),
  },
  // [EN] The mini program tints no static image by itself, so the dark theme takes the dark skin's icon. [CN] 小程序不会自动着色静态图片，因此深色主题使用深色皮肤的图标。
  onLoad() {
    if (typeof wx === 'undefined') return;
    const info = wx.getAppBaseInfo ? wx.getAppBaseInfo() : wx.getSystemInfoSync();
    this.setData({ image: cylImage(info.theme) });
    this.cylThemeListener = ({ theme }) => this.setData({ image: cylImage(theme) });
    if (wx.onThemeChange) wx.onThemeChange(this.cylThemeListener);
  },
  onUnload() {
    if (typeof wx !== 'undefined' && wx.offThemeChange && this.cylThemeListener) wx.offThemeChange(this.cylThemeListener);
  },
  cylToggleBadges() {
    this.setData({ shows: !this.data.shows });
  },
});
