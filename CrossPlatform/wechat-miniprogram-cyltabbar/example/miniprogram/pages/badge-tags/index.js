/**
 * [EN] docs/Animated-Item-Badge-CrossPlatform.md: badges on tags that are a cyl-animated-item. A tag only passes badge-value and
 *      badge-attributes; nothing is stacked on the icon by this page. RollingOnce has no CSS class in the mini program, so that
 *      badge stays still; the component does not read the system's Reduce Motion setting.
 * [CN] docs/Animated-Item-Badge-CrossPlatform.md：本身为 cyl-animated-item 的 Tag 上的角标。Tag 只传 badge-value 与 badge-attributes；
 *      本页面不在图标上叠加任何组件。小程序中 RollingOnce 没有 CSS 类，因此该角标保持静止；组件不读取系统的"减弱动态效果"设置。
 */
const IMAGE = '/shared/skins/2.1.0/light/home@3x.png';

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
    image: IMAGE,
    shows: true,
    tags: SAMPLES.map(([value, animation, reduce], index) => ({
      id: `cyl-badge-tag-${index + 1}`,
      title: `${index + 1}. ${animation}${reduce ? ', Reduce Motion' : ''}`,
      value,
      attributes: { animation, respectsReduceMotion: reduce },
    })),
  },
  cylToggleBadges() {
    this.setData({ shows: !this.data.shows });
  },
});
