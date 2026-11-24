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

import { CYLLiquidGlass } from 'cylanimateditem';

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
 * [EN] The glass material, with the reference's compatibility rule: never create a material at module level or in a field
 *      initializer, and fall back to a blur where the system material does not exist. On the SDKs this port builds with
 *      (API 12 to 21) only the fallback exists.
 * [CN] 玻璃材质，沿用参考工程的兼容规则：不在模块顶层或字段初始化器中创建材质，系统材质不存在时退化为模糊。本端使用的 SDK（API 12 到 21）只有退化方案。
 */
export class CYLLiquidGlassMaterial {
  /**
   * [EN] The fallback blur for a material strength 1 (thickest) to 5 (thinnest), as the reference's blurFallback.
   * [CN] 材质强度 1（最厚）到 5（最薄）对应的退化模糊，与参考工程的 blurFallback 相同。
   */
  static blurFallback(strength: number): BlurStyle {
    if (strength >= 4) {
      return BlurStyle.Thin;
    }
    if (strength <= 2) {
      return BlurStyle.Thick;
    }
    return BlurStyle.Regular;
  }
}

/**
 * [EN] The glass capsule (the expanded bar and the minimized ball): the fallback blur, the app's bar tint when it set one,
 *      the material's shadow and a light rim for the highlight; the radius makes it a capsule at any height.
 * [CN] 玻璃胶囊（展开的 TabBar 与缩小后的球）：退化模糊、App 设置的 TabBar 着色（如有）、材质阴影与作高光的浅色描边；圆角使其在任何高度都是胶囊。
 */
export class CYLLiquidGlassCapsuleModifier implements AttributeModifier<RowAttribute> {
  barTintColor: ResourceColor | undefined;
  height: number;
  strength: number;

  dark: boolean;

  constructor(barTintColor: ResourceColor | undefined, height: number, strength: number = 3, dark: boolean = false) {
    this.barTintColor = barTintColor;
    this.height = height;
    this.strength = strength;
    this.dark = dark;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    // [EN] As iOS 26: near-white glass in a light app, dark grey glass in a dark one, the pages softly blurred behind it.
    // [CN] 与 iOS 26 相同：浅色 App 中为近白色玻璃，深色 App 中为深灰色玻璃，后面的页面被柔和地模糊。
    instance.backgroundEffect({
      radius: CYLLiquidGlass.BLUR_RADIUS, saturation: CYLLiquidGlass.BLUR_SATURATION,
      brightness: this.dark ? CYLLiquidGlass.DARK_BRIGHTNESS : CYLLiquidGlass.LIGHT_BRIGHTNESS
    });
    instance.backgroundColor(this.barTintColor ?? (this.dark ? '#C21C1C1E' : '#DBFAFAFC'));
    instance.borderRadius(this.height / 2);
    instance.shadow({ radius: 28, color: this.dark ? '#40000000' : '#1A000000', offsetY: 6 });
    instance.clip(false);
  }
}

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
