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
   * [EN] `CYLTabBarStyleTypeLiquidGlass`: Liquid Glass, a floating translucent capsule (CYLLiquidGlassTabBarModifier). [CN] 液态玻璃：悬浮的半透明胶囊。
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
 * [EN] Liquid Glass's selected tint (iOS 26 tab bar: `systemBlueColor`). [CN] 液态玻璃的选中色。
 */
export const CYLLiquidGlassTintColor: ResourceColor = '#007AFF';

/**
 * [EN] The capsule behind the selected tab of Liquid Glass (`cyl_liquidGlassSelectionColor`). [CN] 液态玻璃选中 Tab 后的胶囊。
 */
export const CYLLiquidGlassSelectionColor: ResourceColor = '#1F007AFF';

/**
 * [EN] The bar of Liquid Glass (iOS 26 `UITabBar`, Android `CYLLiquidGlass`): a capsule floating above the bottom edge,
 *      inset from the sides, a thin blur of the pages behind it under a translucent tint (`barTintColor`, white by
 *      default; `cyl_liquidGlassSurfaceOpacity`), a light rim and a soft shadow.
 * [CN] 液态玻璃 TabBar：悬浮在底边上方、两侧内缩的胶囊，后面页面的轻度模糊上叠加半透明着色（默认白色），浅色描边与柔和阴影。
 */
export class CYLLiquidGlassTabBarModifier implements AttributeModifier<RowAttribute> {
  barTintColor: ResourceColor | undefined;
  height: number;

  constructor(barTintColor: ResourceColor | undefined, height: number) {
    this.barTintColor = barTintColor;
    this.height = height;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    instance.backgroundBlurStyle(BlurStyle.Thin);
    instance.backgroundColor(this.barTintColor ?? '#66FFFFFF');
    // [EN] The insets (16 vp at the sides, 8 vp above the gesture bar) come from the controller's bar container.
    // [CN] 边距（两侧 16 vp，距手势条 8 vp）由控制器的 TabBar 容器提供。
    instance.borderRadius(this.height / 2);
    instance.border({ width: 0.5, color: '#80FFFFFF' });
    instance.shadow({ radius: 16, color: '#26000000', offsetY: 4 });
    instance.clip(false);
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
export function cyl_tabBarStyleModifier(style: CYLTabBarStyleType, barTintColor?: ResourceColor,
  height: number = 49): AttributeModifier<RowAttribute> {
  if (style === CYLTabBarStyleType.LiquidGlass) {
    return new CYLLiquidGlassTabBarModifier(barTintColor, height);
  }
  return style === CYLTabBarStyleType.FlatDesign ? new CYLFlatDesignTabBarModifier(barTintColor) : new CYLDefaultTabBarModifier();
}
