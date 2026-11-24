/**
 * [EN] The Liquid Glass of `CYLAnimatedItemView` on HarmonyOS NEXT (`itemBackgroundStyle = liquidGlass`): the availability rule
 *      `CYLLiquidGlass.isActive()` (the same name as `CYLAnimatedItemView.isLiquidGlassActive()` on iOS and Android; an ArkUI
 *      struct has no static members), the glass material and capsule the tab bar draws, and `CYLLiquidGlassView`, a glass
 *      background for a host that draws its own container. API 12 to 21 have no system glass material, so the glass is a blur
 *      with a light or dark tint, as in the tab bar.
 * [CN] 鸿蒙 `CYLAnimatedItemView` 的液态玻璃（`itemBackgroundStyle = liquidGlass`）：可用性判断 `CYLLiquidGlass.isActive()`（对应 iOS 与
 *      Android 的 `CYLAnimatedItemView.isLiquidGlassActive()`；ArkUI struct 没有静态成员）、TabBar 绘制的玻璃材质与胶囊，以及
 *      `CYLLiquidGlassView`（供自行绘制容器的宿主使用的玻璃背景）。API 12 到 21 没有系统玻璃材质，因此玻璃使用模糊加浅色或深色着色，与 TabBar 相同。
 */

/**
 * [EN] Whether Liquid Glass is drawn, the one rule every CYLTabBarController component asks (the same name as iOS and Android):
 *      always on HarmonyOS, whose tab bar draws the blur imitation on every supported API (the system material replaces it from
 *      API 24); `activeOverride` replaces it in tests.
 * [CN] 是否绘制液态玻璃，CYLTabBarController 各组件共用的唯一规则（与 iOS、Android 同名）：在鸿蒙上始终为真，因为 TabBar 在每个受支持的
 *      API 上都绘制模糊仿制（系统材质从 API 24 起替代它）；`activeOverride` 供测试替换。
 */
export class CYLLiquidGlass {
  /**
   * [EN] For tests: replaces the rule of `isActive()` (`undefined`, the default, uses the rule). [CN] 供测试使用：替代 `isActive()` 的规则（默认 `undefined`，使用规则）。
   */
  static activeOverride: boolean | undefined = undefined;

  /**
   * [EN] Whether Liquid Glass is in use (see the class comment); when false the caller keeps its flat background.
   * [CN] 是否使用液态玻璃（见类注释）；为 false 时调用方保持其扁平背景。
   */
  static isActive(): boolean {
    const override: boolean | undefined = CYLLiquidGlass.activeOverride;
    return override !== undefined ? override : true;
  }
}

/**
 * [EN] A Liquid Glass background for any component (the same name as iOS `CYLLiquidGlassView`): put it behind the content in a
 *      `Stack`. The pages behind it are blurred inside the rounded rectangle and tinted with `glassTintColor` (a color string such
 *      as '#66FF8800'; '' for none). It takes no touches and is hidden from accessibility. When `CYLLiquidGlass.isActive()` is
 *      false the caller keeps its flat background and does not create the view.
 * [CN] 任意组件的液态玻璃背景（与 iOS 的 `CYLLiquidGlassView` 同名）：放在 `Stack` 中内容的后面。它后面的页面在圆角矩形内被模糊，并以
 *      `glassTintColor`（颜色字符串，如 '#66FF8800'；'' 表示不着色）着色。不接收触摸，对辅助功能隐藏。`CYLLiquidGlass.isActive()` 为 false 时，
 *      调用方保持其扁平背景，不创建该视图。
 */
@Component
export struct CYLLiquidGlassView {
  /**
   * [EN] The tint of the glass; '' for none. [CN] 玻璃的着色；'' 表示不着色。
   */
  @Prop glassTintColor: string = '';
  /**
   * [EN] The corner radius the glass is clipped to, in vp. [CN] 玻璃裁剪所用的圆角半径，单位 vp。
   */
  @Prop cornerRadius: number = 0;
  /**
   * [EN] Dark glass for a dark app. [CN] 深色 App 使用深色玻璃。
   */
  @Prop dark: boolean = false;

  build() {
    Row()
      .width('100%')
      .height('100%')
      .backgroundEffect({ radius: 28, saturation: 1.6, brightness: this.dark ? 0.9 : 1.05 })
      .backgroundColor(this.glassTintColor.length > 0 ? this.glassTintColor : Color.Transparent)
      .borderRadius(this.cornerRadius)
      .clip(true)
      .hitTestBehavior(HitTestMode.None)
      .accessibilityLevel('no')
  }
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
    instance.backgroundEffect({ radius: 28, saturation: 1.6, brightness: this.dark ? 0.9 : 1.05 });
    instance.backgroundColor(this.barTintColor ?? (this.dark ? '#C21C1C1E' : '#DBFAFAFC'));
    instance.borderRadius(this.height / 2);
    instance.shadow({ radius: 28, color: this.dark ? '#40000000' : '#1A000000', offsetY: 6 });
    instance.clip(false);
  }
}
