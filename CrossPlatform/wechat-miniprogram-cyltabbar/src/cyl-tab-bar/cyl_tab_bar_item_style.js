/**
 * [EN] CYLTabBarItemStyle: the look of a tab item, one enum for cyl-tab-bar-item and cyl-tab-bar. `flat` is the item as
 *      it always was (icon and title, the iOS CYLFlatDesignTabBarItem); `liquidGlass` puts the selected item on a
 *      frosted glass lens (translucent tint, blur and saturation, a light rim and an inner highlight) that springs in
 *      when the tab is selected and presses in on touch, and the bar becomes a floating glass capsule. cyl-tab-bar
 *      takes the style at initialization (`item-style`, or from CYLTabBarControllerStyleType when it is not set),
 *      gives it to every item, and switches it at run time (`cyl_setItemStyle`). The glass look follows the design
 *      ideas of tyfuser/chatnote-miniprogram, Akenaiai/sports-checkin-miniprogram and 1994Umbrella/mirror-landing; no
 *      code was copied.
 * [CN] CYLTabBarItemStyle：Tab Item 的外观，cyl-tab-bar-item 与 cyl-tab-bar 共用这一个枚举。`flat` 为 Item 原有的样子
 *      （图标与标题，对应 iOS 的 CYLFlatDesignTabBarItem）；`liquidGlass` 让选中的 Item 位于磨砂玻璃透镜上（半透明底色、
 *      模糊与饱和度、亮边与内高光），Tab 被选中时透镜弹入，按下时内缩，TabBar 变为悬浮的玻璃胶囊。cyl-tab-bar 在初始化
 *      时接收样式（`item-style`，未设置时由 CYLTabBarControllerStyleType 推出），交给每个 Item，并可在运行时切换
 *      （`cyl_setItemStyle`）。玻璃外观参考 tyfuser/chatnote-miniprogram、Akenaiai/sports-checkin-miniprogram 与
 *      1994Umbrella/mirror-landing 的设计思路；未复制代码。
 */
const CYLTabBarItemStyle = Object.freeze({
  flat: 'flat',
  liquidGlass: 'liquidGlass',
});

/**
 * [EN] The item style for a value: a CYLTabBarItemStyle name or number (0 flat, 1 liquidGlass); anything else is flat.
 * [CN] 某个值对应的 Item 样式：CYLTabBarItemStyle 的名称或数字（0 flat，1 liquidGlass）；其他值为 flat。
 */
function cylTabBarItemStyle(value) {
  const names = Object.values(CYLTabBarItemStyle);
  const name = typeof value === 'number' ? names[value] : value;
  return names.includes(name) ? name : CYLTabBarItemStyle.flat;
}

/**
 * [EN] The item style a bar style type implies: liquidGlass for "liquidGlass", flat for the others.
 * [CN] 某个 TabBar 样式对应的 Item 样式："liquidGlass" 为 liquidGlass，其他为 flat。
 */
function cylTabBarItemStyleForStyleType(styleType) {
  return styleType === 'liquidGlass' ? CYLTabBarItemStyle.liquidGlass : CYLTabBarItemStyle.flat;
}

/**
 * [EN] CYLGlassLensStyle: the two looks of the Liquid Glass lens (CYLTabBarItemStyle liquidGlass only; flat shows no
 *      lens). `regular` (default, "liquid"): a nearly opaque tint, the color measured on the reference lens, so the
 *      lens looks the same on any bar. `skeuomorphic` ("skeuomorphic liquid"): a see-through tint that takes the color
 *      of what is behind it, like real glass, so it looks lighter on a white bar and warmer on a colored one.
 * [CN] CYLGlassLensStyle：液态玻璃透镜的两种外观（仅 CYLTabBarItemStyle liquidGlass；flat 不显示透镜）。`regular`
 *      （默认，"液态"）：接近不透明的底色，取自参考透镜测得的颜色，透镜在任何 TabBar 上看起来一致。`skeuomorphic`
 *      （"拟物风液态"）：透出背后颜色的半透明底色，像真实的玻璃，在白色 TabBar 上更浅，在彩色 TabBar 上更暖。
 */
const CYLGlassLensStyle = Object.freeze({
  regular: 'regular',
  skeuomorphic: 'skeuomorphic',
});

/**
 * [EN] The lens style for a value: a CYLGlassLensStyle name or number (0 regular, 1 skeuomorphic); anything else is
 *      regular.
 * [CN] 某个值对应的透镜样式：CYLGlassLensStyle 的名称或数字（0 regular，1 skeuomorphic）；其他值为 regular。
 */
function cylGlassLensStyle(value) {
  const names = Object.values(CYLGlassLensStyle);
  const name = typeof value === 'number' ? names[value] : value;
  return names.includes(name) ? name : CYLGlassLensStyle.regular;
}

module.exports = {
  CYLTabBarItemStyle, cylTabBarItemStyle, cylTabBarItemStyleForStyleType, CYLGlassLensStyle, cylGlassLensStyle,
};
