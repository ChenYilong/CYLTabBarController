import { CYLTabBarItemAttributes, CYLTitleOffset } from './CYLTabBarItem';
import { CYLPlusButton } from './CYLPlusButton';

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
  backgroundImage: ResourceStr | undefined;

  constructor(barTintColor: ResourceColor | undefined, backgroundImage?: ResourceStr) {
    this.barTintColor = barTintColor;
    this.backgroundImage = backgroundImage;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    // [EN] `backgroundImage` replaces the blur and is tiled to fit (iOS). [CN] `backgroundImage` 代替模糊并平铺（与 iOS 相同）。
    if (this.backgroundImage !== undefined) {
      // [EN] Reset the material a previous look left (the modifier is applied again to the same bar).
      // [CN] 重置之前外观留下的材质（同一个 TabBar 会再次应用 modifier）。
      instance.backgroundBlurStyle(BlurStyle.NONE);
      instance.backgroundImage(this.backgroundImage, ImageRepeat.XY);
      instance.backgroundColor(this.barTintColor ?? Color.Transparent);
      return;
    }
    // [EN] A tint (a skin's bar color) is drawn as is: the light `COMPONENT_THICK` material would wash a dark tint out and
    //      leave the bar a different color from the strip under the gesture bar. Without one, the blur and the
    //      near-opaque system background (`UIBlurEffectStyleProminent`).
    // [CN] 有着色（皮肤的 TabBar 颜色）时直接绘制：浅色的 `COMPONENT_THICK` 材质会冲淡深色着色，使 TabBar 与手势条下方区域颜色不一致。
    //      没有着色时使用模糊与接近不透明的系统背景（`UIBlurEffectStyleProminent`）。
    if (this.barTintColor !== undefined) {
      // [EN] Without this reset the light material of the default look stayed on the bar after a skin was chosen,
      //      washing its color out to gray above a strip of the real color (two tones, light titles on gray).
      // [CN] 不重置时，选择皮肤后默认外观的浅色材质仍留在 TabBar 上，把皮肤颜色冲淡成灰色，下方却是真实颜色（两种颜色、浅色标题在灰底上）。
      instance.backgroundBlurStyle(BlurStyle.NONE);
      instance.backgroundColor(this.barTintColor);
      return;
    }
    instance.backgroundBlurStyle(BlurStyle.COMPONENT_THICK);
    instance.backgroundColor('#BFF9F9F9');
  }
}

/**
 * [EN] Liquid Glass's selected tint (iOS 26 tab bar: `systemBlueColor`). [CN] 液态玻璃的选中色。
 */
export const CYLLiquidGlassTintColor: ResourceColor = '#007AFF';

/**
 * [EN] Liquid Glass's unselected tint: the system label color, dark in a light app and light in a dark one (iOS 26 tab bar).
 * [CN] 液态玻璃的未选中色：系统文字颜色，浅色 App 中为深色、深色 App 中为浅色（iOS 26 TabBar）。
 */
export const CYLLiquidGlassUnselectedColor: ResourceColor = $r('sys.color.font_primary');

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
  height: number = 49, backgroundImage?: ResourceStr): AttributeModifier<RowAttribute> {
  if (style === CYLTabBarStyleType.LiquidGlass) {
    return new CYLLiquidGlassTabBarModifier(barTintColor, height);
  }
  return style === CYLTabBarStyleType.FlatDesign ? new CYLFlatDesignTabBarModifier(barTintColor, backgroundImage) : new CYLDefaultTabBarModifier();
}

/**
 * [EN] `CYLFlatDesignTabBarItem`: on HarmonyOS a tab item is its attributes, the same type for every style (Android
 *      `typealias CYLFlatDesignTabBarItem = CYLTabBarItem`). [CN] 鸿蒙上 Tab item 即其属性，各样式共用同一类型（与 Android 的 typealias 相同）。
 */
export type CYLFlatDesignTabBarItem = CYLTabBarItemAttributes;

/**
 * [EN] `-[CYLFlatDesignTabBarItem initWithTitle:image:]` and `-initWithTitle:image:selectedImage:`: the attributes of a
 *      tab with a title and images; `selectedImage` defaults to `image`.
 * [CN] 带标题与图片的 Tab 属性；`selectedImage` 默认为 `image`。
 */
export function cyl_flatDesignTabBarItem(title: ResourceStr | undefined, image: ResourceStr | undefined,
  selectedImage?: ResourceStr): CYLFlatDesignTabBarItem {
  const item: CYLFlatDesignTabBarItem = { title: title, image: image, selectedImage: selectedImage ?? image };
  return item;
}

/**
 * [EN] `-initWithTitle:image:selectedImage:index:titlePositionAdjustment:imagePositionAdjustment:…`: as above, with the
 *      title offset; the index is the item's position in `tabBarItemsAttributes`.
 * [CN] 同上并带标题偏移；index 即该 item 在 `tabBarItemsAttributes` 中的位置。
 */
export function cyl_flatDesignTabBarItemWithOffset(title: ResourceStr | undefined, image: ResourceStr | undefined,
  selectedImage: ResourceStr | undefined, titlePositionAdjustment: CYLTitleOffset): CYLFlatDesignTabBarItem {
  const item: CYLFlatDesignTabBarItem = cyl_flatDesignTabBarItem(title, image, selectedImage);
  item.titlePositionAdjustment = titlePositionAdjustment;
  return item;
}

/**
 * [EN] `-[CYLFlatDesignTabBar hasPlusButton]`: whether the tab bar shows a plus button. [CN] TabBar 是否显示加号按钮。
 */
export function cyl_flatDesignHasPlusButton(plusButton: CYLPlusButton | undefined): boolean {
  return plusButton !== undefined;
}

/**
 * [EN] `-[CYLFlatDesignTabBar hasPlusChildViewController]`: whether the plus button selects a page of its own
 *      (`CYLPlusButton.selectable`). [CN] 加号按钮是否选中自己的页面（`CYLPlusButton.selectable`）。
 */
export function cyl_flatDesignHasPlusChildViewController(plusButton: CYLPlusButton | undefined): boolean {
  return plusButton?.selectable === true;
}
