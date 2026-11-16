/**
 * [EN] Liquid Glass for the HarmonyOS CYLTabBarController (`CYLTabBarStyleTypeLiquidGlass`), rebuilt on the design of
 *      harmonyos-liquid-glass-tabbar (https://github.com/DUDUXXR2/harmonyos-liquid-glass-tabbar, MIT, by DUDUXXR2): a floating
 *      glass capsule over the pages, the tab content drawn by the controller on top of it, and one continuous morph when the
 *      bar minimizes on scroll (`tabBarMinimizeBehavior`): the capsule narrows into a ball at the leading edge, the selected
 *      tab slides to the ball's center, its title fades and its icon scales, all in one `animateTo` (iOS 26 minimized tab bar).
 *      The reference paints the glass with HDS system material (`HdsTabs` `barFloatingStyle` / `uiMaterial`, API 24+); this
 *      port targets API 12 to 21, so it uses the reference's own fallback below API 26: `backgroundBlurStyle` plus the
 *      material's shadow, with a light rim for the highlight. TODO: switch to HDS material when the SDK is 6.1.1 (API 24) or
 *      later (see CYLLiquidGlassMaterial).
 * [CN] 鸿蒙 CYLTabBarController 的液态玻璃（`CYLTabBarStyleTypeLiquidGlass`），按 harmonyos-liquid-glass-tabbar 的设计重构
 *      （https://github.com/DUDUXXR2/harmonyos-liquid-glass-tabbar，MIT，作者 DUDUXXR2）：悬浮在页面之上的玻璃胶囊，Tab 内容由控制器
 *      画在胶囊上，滚动缩小（`tabBarMinimizeBehavior`）时是一段连续形变：胶囊收窄成起始端的一颗球，选中 Tab 平移到球心，标题淡出、图标缩放，
 *      全部由一个 `animateTo` 完成（iOS 26 缩小后的 TabBar）。参考工程用 HDS 系统材质（API 24 起）；本端面向 API 12 到 21，因此使用参考
 *      工程在 API 26 以下的退化方案：`backgroundBlurStyle` 加材质阴影，并以浅色描边作高光。TODO：SDK 升级到 6.1.1（API 24）及以上后改用
 *      HDS 材质（见 CYLLiquidGlassMaterial）。
 */

/**
 * [EN] Every Liquid Glass size in one place, from the reference's DockBarTokens (vp; measured on a device there).
 * [CN] 液态玻璃的全部尺寸，取自参考工程的 DockBarTokens（vp，参考工程在真机上测得）。
 */
export class CYLLiquidGlassTokens {
  /**
   * [EN] The capsule's distance from the bottom of the screen. [CN] 胶囊距屏幕底部的距离。
   */
  static readonly BAR_BOTTOM_MARGIN: number = 24;
  /**
   * [EN] The expanded capsule's distance from the screen's sides. [CN] 展开态胶囊距屏幕两侧的距离。
   */
  static readonly BAR_SIDE_MARGIN: number = 11;
  /**
   * [EN] The expanded capsule's height (at least; a taller `tabBarHeight` wins). [CN] 展开态胶囊高度（至少；更高的 `tabBarHeight` 优先）。
   */
  static readonly ROW_HEIGHT_EXPANDED: number = 56;
  /**
   * [EN] The minimized bar: a ball of this diameter. [CN] 缩小后的 TabBar：直径为此值的球。
   */
  static readonly ROW_HEIGHT_COLLAPSED: number = 42;
  /**
   * [EN] The minimized ball's distance from the leading edge. [CN] 缩小后的球距起始边的距离。
   */
  static readonly COLLAPSED_EDGE_MARGIN: number = 22;
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

  constructor(barTintColor: ResourceColor | undefined, height: number, strength: number = 3) {
    this.barTintColor = barTintColor;
    this.height = height;
    this.strength = strength;
  }

  applyNormalAttribute(instance: RowAttribute): void {
    // [EN] Vibrant glass: blur with boosted saturation and brightness (what makes iOS glass look liquid rather than frosted).
    // [CN] 鲜亮的玻璃：模糊并提高饱和度与亮度（这让 iOS 玻璃看起来像液体而不是磨砂）。
    instance.backgroundEffect({ radius: 30 + 10 * (5 - this.strength), saturation: 1.8, brightness: 1.08 });
    instance.backgroundColor(this.barTintColor ?? '#26FFFFFF');
    instance.borderRadius(this.height / 2);
    instance.shadow({ radius: 20, color: '#22000000', offsetY: 6 });
    instance.clip(true);
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
