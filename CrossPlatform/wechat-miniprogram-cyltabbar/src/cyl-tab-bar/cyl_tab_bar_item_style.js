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

module.exports = { CYLTabBarItemStyle, cylTabBarItemStyle, cylTabBarItemStyleForStyleType };
