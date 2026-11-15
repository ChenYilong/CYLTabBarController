/**
 * [EN] The tab bar styles (iOS `CYLTabBarStyleType`, CYLConstants.h) and the FlatDesign look (iOS `CYLFlatDesignTabBar`,
 *      Android `CYLFlatDesignTabBarStyle`): a strong blur of the pages behind the bar under a near-opaque system background
 *      (`UIBlurEffectStyleProminent`), the bar tint on top, a thin top line, blue when selected and gray otherwise.
 * [CN] TabBar 样式（iOS `CYLTabBarStyleType`，CYLConstants.h）与扁平样式外观（iOS `CYLFlatDesignTabBar`，Android
 *      `CYLFlatDesignTabBarStyle`）：TabBar 后面页面的强模糊，上面是接近不透明的系统背景色（`UIBlurEffectStyleProminent`），再叠加
 *      TabBar 着色，顶部细线，选中为蓝色，否则为灰色。
 */

/**
 * [EN] `CYLTabBarStyleType`: the values of iOS, in the same order. [CN] 与 iOS 相同的取值与顺序。
 */
export enum CYLTabBarStyleType {
  /**
   * [EN] `CYLTabBarStyleTypeDefault`: the classic tab bar. [CN] 经典 TabBar。
   */
  Default = 0,
  /**
   * [EN] `CYLTabBarStyleTypeSystem`: the system look; the classic tab bar on HarmonyOS. [CN] 系统外观；鸿蒙上即经典 TabBar。
   */
  System = 1,
  /**
   * [EN] `CYLTabBarStyleTypeFlatDesign`: the FlatDesign tab bar. [CN] 扁平样式 TabBar。
   */
  FlatDesign = 2,
  /**
   * [EN] `CYLTabBarStyleTypeLiquidGlass`: Liquid Glass; drawn as the classic tab bar until demo 8 lands. [CN] 液态玻璃；在第 8 项完成前按经典 TabBar 绘制。
   */
  LiquidGlass = 3
}

/**
 * [EN] FlatDesign's selected tint (`systemBlueColor`). [CN] 扁平样式的选中色（`systemBlueColor`）。
 */
export const CYLFlatDesignTintColor: ResourceColor = '#007AFF';

/**
 * [EN] FlatDesign's unselected tint (`systemGrayColor`). [CN] 扁平样式的未选中色（`systemGrayColor`）。
 */
export const CYLFlatDesignUnselectedColor: ResourceColor = '#8E8E93';

/**
 * [EN] The bar of the FlatDesign style: the blur and the near-opaque background, then `barTintColor` when the app sets one.
 * [CN] 扁平样式的 TabBar：模糊与接近不透明的背景，App 设置了 `barTintColor` 时再叠加它。
 */
export class CYLFlatDesignTabBarModifier implements AttributeModifier<RowAttribute> {
  barTintColor: ResourceColor | undefined;

  constructor(barTintColor: ResourceColor | undefined) {
    this.barTintColor = barTintColor;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    instance.backgroundBlurStyle(BlurStyle.COMPONENT_THICK);
    instance.backgroundColor(this.barTintColor ?? '#BFF9F9F9');
  }
}

/**
 * [EN] Leaves the classic bar as it is. [CN] 保持经典 TabBar 不变。
 */
export class CYLDefaultTabBarModifier implements AttributeModifier<RowAttribute> {
  applyNormalAttribute(instance: RowAttribute): void {
    // [EN] Nothing: the controller already drew the classic bar. [CN] 无操作：控制器已绘制经典 TabBar。
  }
}

/**
 * [EN] The modifier of the bar for `style`; `barTintColor` is the app's bar color, undefined for the style's own.
 * [CN] `style` 对应的 TabBar modifier；`barTintColor` 为 App 设置的 TabBar 颜色，未设置时使用样式自己的颜色。
 */
export function cyl_tabBarStyleModifier(style: CYLTabBarStyleType, barTintColor?: ResourceColor): AttributeModifier<RowAttribute> {
  return style === CYLTabBarStyleType.FlatDesign ? new CYLFlatDesignTabBarModifier(barTintColor) : new CYLDefaultTabBarModifier();
}
