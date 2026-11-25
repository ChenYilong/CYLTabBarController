import { CYLLiquidGlass } from './CYLLiquidGlass';
import { cylAnimatedItemGlassTintColor } from './CYLAnimatedItemColors';

/**
 * [EN] What an item's background is made of: the solid color (`flat`, the default) or Liquid Glass (a blur imitation tinted with
 *      the color, where `CYLLiquidGlass.isActive()`; flat elsewhere, the other parameters kept).
 * [CN] 条目背景的构成：纯色（`flat`，默认）或液态玻璃（带着色的模糊仿制，在 `CYLLiquidGlass.isActive()` 时；否则为扁平，其他参数保持）。
 */
/**
 * [EN] The named constant of the capsule (1000 vp): pass it as `cornerRadius` instead of a literal; the platform limits any radius to half the height, so it is
 *      exactly a capsule and follows the size (any plain number is vp with the same limit). -1 is not set: a capsule for the drawn glass, square for flat.
 * [CN] 胶囊的命名常量（1000 vp）：作为 `cornerRadius` 传入，不要写字面量；平台会把任何圆角截断到半高，所以它恰好是胶囊并随尺寸变化（任何普通数字都是 vp，同样截断）。
 *      -1 表示未设置：绘制玻璃时为胶囊，扁平时为直角。
 */
export const CYLAnimatedItemCornerRadiusCapsule: number = 1000;

/**
 * [EN] The space (vp) between the outer border and the content, left and right, that an item with the drawn Liquid Glass gets while
 *      `itemContentHorizontalInset` is not set (-1): a capsule's round ends take room from the content, so the unset glass inset is wider; the
 *      unset flat inset is 0. The same condition as the unset `itemCornerRadius`. Pass it by name, never the literal.
 * [CN] 绘制液态玻璃的条目在未设置（-1）`itemContentHorizontalInset` 时，外侧边框与内容之间左右的间距（vp）：胶囊的圆端会占去内容的空间，所以未设置时
 *      玻璃的间距更宽；未设置时扁平的间距为 0。与未设置的 `itemCornerRadius` 条件相同。请用名称，不要写字面量。
 */
export const CYLAnimatedItemLiquidGlassContentInset: number = 14;

export enum CYLAnimatedItemBackgroundStyle {
  flat = 0,
  liquidGlass = 1
}

/**
 * [EN] The one place that decides and applies an item background on HarmonyOS: `CYLAnimatedItemView` uses it for its own root, and a
 *      host whose item is not a `CYLAnimatedItemView` (CollectionViewClassifyMenu's tag) applies the same background to its container
 *      with `.attributeModifier(new CYLAnimatedItemBackgroundModifier(...))`, so it keeps no glass, blur or capsule code of its own.
 *      `cornerRadius` -1 is not set: a capsule for the drawn glass, square for flat; a value of 0 or more customizes it.
 * [CN] 鸿蒙上决定并应用条目背景的唯一位置：`CYLAnimatedItemView` 用它处理自己的根节点；条目不是 `CYLAnimatedItemView` 的宿主（CollectionViewClassifyMenu 的
 *      标签）用 `.attributeModifier(new CYLAnimatedItemBackgroundModifier(...))` 把同样的背景应用到自己的容器，因此不保留任何玻璃、模糊或胶囊代码。
 *      `cornerRadius` 为 -1 表示未设置：绘制玻璃时为胶囊，扁平时为直角；0 及以上的值用于自定义。
 */
export class CYLAnimatedItemBackgroundModifier implements AttributeModifier<CommonAttribute> {
  /** [EN] The tint of a glass with no color (225, 222, 220 at alpha 0.5). [CN] 未设置颜色时玻璃的着色（225, 222, 220，透明度 0.5）。 */
  static readonly DEFAULT_GLASS_TINT: string = '#80E1DEDC';

  style: CYLAnimatedItemBackgroundStyle;

  color: ResourceColor;

  cornerRadius: number;

  borderWidth: number;

  borderColor: ResourceColor;

  /** [EN] The share of the color's alpha that tints the glass, -1 for the default 0.75. [CN] 用于给玻璃着色的颜色透明度比例，-1 为默认的 0.75。 */
  tintAlpha: number;

  constructor(style: CYLAnimatedItemBackgroundStyle, color: ResourceColor, cornerRadius: number = -1, borderWidth: number = 0,
    borderColor: ResourceColor = Color.Transparent, tintAlpha: number = -1) {
    this.tintAlpha = tintAlpha;
    this.style = style;
    this.color = color;
    this.cornerRadius = cornerRadius;
    this.borderWidth = borderWidth;
    this.borderColor = borderColor;
  }

  /**
   * [EN] Whether the glass is drawn for `style`. [CN] `style` 是否绘制玻璃。
   */
  static isGlassDrawn(style: CYLAnimatedItemBackgroundStyle): boolean {
    return style === CYLAnimatedItemBackgroundStyle.liquidGlass && CYLLiquidGlass.isActive();
  }

  /**
   * [EN] The radius: the set value, else a capsule for the drawn glass and square for flat. [CN] 圆角：设置的值，否则绘制玻璃时为胶囊、扁平时为直角。
   */
  static resolvedCornerRadius(style: CYLAnimatedItemBackgroundStyle, cornerRadius: number): number {
    // CYLAnimatedItemCornerRadiusCapsule is the capsule: the platform limits it to half the height, so it follows the size.
    if (cornerRadius >= 0) {
      return cornerRadius;
    }
    return CYLAnimatedItemBackgroundModifier.isGlassDrawn(style) ? CYLAnimatedItemCornerRadiusCapsule : 0;
  }

  /**
   * [EN] The content inset (vp): the set value (0 or more), else `CYLAnimatedItemLiquidGlassContentInset` for the drawn glass and 0 for flat. The
   *      unset radius's condition. [CN] 内容间距（vp）：设置的值（0 及以上），否则绘制玻璃时为 `CYLAnimatedItemLiquidGlassContentInset`，扁平时为 0。与未设置圆角的条件相同。
   */
  static resolvedContentInset(style: CYLAnimatedItemBackgroundStyle, inset: number): number {
    if (inset >= 0) {
      return inset;
    }
    return CYLAnimatedItemBackgroundModifier.isGlassDrawn(style) ? CYLAnimatedItemLiquidGlassContentInset : 0;
  }

  /**
   * [EN] The tint a glass draws with: a '#RRGGBB', '#AARRGGBB' or ARGB number color made translucent (its alpha times
   *      `CYLLiquidGlass.GLASS_TINT_ALPHA`), so an opaque color such as a selected tag's green tints the glass instead of covering it; the same rule as
   *      iOS and Android. Other kinds of color (a resource, a `Color` value) are used as they are.
   * [CN] 玻璃使用的着色：'#RRGGBB'、'#AARRGGBB' 或 ARGB 数值颜色变为半透明（其透明度乘以 `CYLLiquidGlass.GLASS_TINT_ALPHA`），因此选中标签的绿色这样的
   *      不透明色是给玻璃着色而不是盖住它；与 iOS、Android 同一规则。其他类型的颜色（资源、`Color` 值）原样使用。
   */
  static glassTint(color: ResourceColor, tintAlpha: number = -1): ResourceColor {
    // [EN] No color set: the default frosted tint (225, 222, 220 at alpha 0.5, as iOS in light mode). [CN] 未设置颜色：默认的磨砂着色（225, 222, 220，透明度 0.5，与 iOS 浅色模式相同）。
    if (color === Color.Transparent || color === '') {
      return CYLAnimatedItemBackgroundModifier.DEFAULT_GLASS_TINT;
    }
    if (typeof color === 'number' || typeof color === 'string') {
      const tint: string | number | undefined = cylAnimatedItemGlassTintColor(color, CYLLiquidGlass.GLASS_TINT_ALPHA, CYLAnimatedItemBackgroundModifier.DEFAULT_GLASS_TINT);
      if (tint !== undefined) {
        return tint;
      }
    }
    return color;
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    const glass: boolean = CYLAnimatedItemBackgroundModifier.isGlassDrawn(this.style);
    instance.backgroundEffect(glass ?
      { radius: CYLLiquidGlass.BLUR_RADIUS, saturation: CYLLiquidGlass.BLUR_SATURATION, brightness: CYLLiquidGlass.LIGHT_BRIGHTNESS } :
      { radius: 0 });
    instance.backgroundColor(glass ? CYLAnimatedItemBackgroundModifier.glassTint(this.color, this.tintAlpha) : this.color);
    instance.borderRadius(CYLAnimatedItemBackgroundModifier.resolvedCornerRadius(this.style, this.cornerRadius));
    // [EN] A drawn glass without an explicit border gets the hairline rim of Android's `CYLLiquidGlassView` (1 vp, dark on a light page, light on a dark one),
    //      so the edge of a tag or a section card is visible on a plain or gradient page. [CN] 绘制的玻璃在没有显式边框时带有 Android `CYLLiquidGlassView` 的
    //      细边（1 vp，浅色页面上为深色、深色页面上为浅色），使标签或分组卡片的边缘在纯色或渐变页面上可见。
    const rim: boolean = glass && this.borderWidth <= 0;
    instance.borderWidth(rim ? CYLLiquidGlass.RIM_WIDTH : this.borderWidth);
    instance.borderColor(rim ? CYLLiquidGlass.rimEdgeColors(CYLLiquidGlass.isDark()) : this.borderColor);
    if (glass) {
      instance.linearGradient({ direction: GradientDirection.Bottom, colors: CYLLiquidGlass.sheenColors(CYLLiquidGlass.isDark()) });
    }
    instance.clip(glass);
  }
}
