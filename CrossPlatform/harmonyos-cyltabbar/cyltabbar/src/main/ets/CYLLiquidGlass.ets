/**
 * [EN] Liquid Glass of the HarmonyOS CYLTabBarController (`CYLTabBarStyleTypeLiquidGlass`), a one-to-one copy of the iOS
 *      library on iOS 26 (measured on the iOS Objective-C example, iPhone 17 Pro): a glass capsule floating over the pages,
 *      21 vp from the sides and from the screen's bottom, 61 vp high; a neutral glass lens behind the selected tab that slides
 *      on a spring, stretches in flight, lifts when touched and follows a drag; the plus button raised in its slot; minimized
 *      on scroll (`tabBarMinimizeBehavior`) into a ball with the selected tab. API 12 to 21 have no system glass material, so the
 *      glass is a blur with a light or dark tint, a soft shadow and a light rim.
 * [CN] 鸿蒙 CYLTabBarController 的液态玻璃（`CYLTabBarStyleTypeLiquidGlass`），一比一复刻 iOS 26 上的 iOS 版本（在 iOS Objective-C 示例、
 *      iPhone 17 Pro 上测得）：悬浮在页面之上的玻璃胶囊，距两侧与屏幕底部各 21 vp，高 61 vp；选中 Tab 后的中性玻璃镜片，以弹簧曲线滑动、
 *      飞行中拉伸、触摸时抬起并跟随拖动；加号按钮在其槽位中凸起；滚动时（`tabBarMinimizeBehavior`）缩小成只含选中 Tab 的球。API 12 到 21
 *      没有系统玻璃材质，因此玻璃使用模糊加浅色或深色着色、柔和阴影与浅色描边。
 */

/**
 * [EN] Every Liquid Glass size in one place, measured on iOS 26 (vp = pt). [CN] 液态玻璃的全部尺寸，在 iOS 26 上测得（vp = pt）。
 */
export class CYLLiquidGlassTokens {
  /**
   * [EN] The capsule's distance from the bottom of the screen. [CN] 胶囊距屏幕底部的距离。
   */
  static readonly BAR_BOTTOM_MARGIN: number = 21;
  /**
   * [EN] The expanded capsule's distance from the screen's sides. [CN] 展开态胶囊距屏幕两侧的距离。
   */
  static readonly BAR_SIDE_MARGIN: number = 21;
  /**
   * [EN] The expanded capsule's height (at least; a taller `tabBarHeight` wins). [CN] 展开态胶囊高度（至少；更高的 `tabBarHeight` 优先）。
   */
  static readonly ROW_HEIGHT_EXPANDED: number = 61;
  /**
   * [EN] The minimized bar: a ball of this diameter. [CN] 缩小后的 TabBar：直径为此值的球。
   */
  static readonly ROW_HEIGHT_COLLAPSED: number = 42;
  /**
   * [EN] The minimized ball's distance from the leading edge. [CN] 缩小后的球距起始边的距离。
   */
  static readonly COLLAPSED_EDGE_MARGIN: number = 21;
  /**
   * [EN] How far the selected icon moves down once its title has faded, to sit on the ball's center (half a title line).
   * [CN] 标题淡出后，选中图标下移的距离（半个标题行高），使其落在球心。
   */
  static readonly COLLAPSED_ICON_DY: number = 8;
  /**
   * [EN] The icon size inside the minimized ball. [CN] 球内图标尺寸。
   */
  static readonly COLLAPSED_ICON_SIZE: number = 21;
  /**
   * [EN] The duration of the minimize / expand morph (ms). [CN] 缩小 / 展开形变的时长（毫秒）。
   */
  static readonly MORPH_DURATION: number = 300;
}

/**
 * [EN] The glass material and the glass capsule are part of the base library `cylliquidglass` now (the tab bar depends on it);
 *      re-exported here so that the tab bar's imports stay as they were.
 * [CN] 玻璃材质与玻璃胶囊现在属于基础库 `cylliquidglass`（TabBar 依赖它）；在此重新导出，TabBar 的导入保持不变。
 */
export { CYLLiquidGlassMaterial, CYLLiquidGlassCapsuleModifier } from 'cylliquidglass';

/**
 * [EN] The bar container of Liquid Glass floats over the pages: out of the column's flow, pinned to the bottom, so the pages
 *      reach under the capsule and the glass blurs them. The other styles keep the bar below the pages.
 * [CN] 液态玻璃的 TabBar 容器悬浮在页面之上：脱离 Column 布局、固定在底部，页面延伸到胶囊下方，玻璃模糊的是页面。其他样式的 TabBar 仍在页面下方。
 */
export class CYLLiquidGlassContainerModifier implements AttributeModifier<ColumnAttribute> {
  floating: boolean;

  constructor(floating: boolean) {
    this.floating = floating;
  }

  applyNormalAttribute(instance: ColumnAttribute): void {
    if (this.floating) {
      instance.position({ left: 0, bottom: 0 });
      instance.hitTestBehavior(HitTestMode.Transparent);
    }
  }
}
