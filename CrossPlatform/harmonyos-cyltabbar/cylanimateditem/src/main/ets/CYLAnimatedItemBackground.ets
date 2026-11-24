import { CYLLiquidGlass } from './CYLLiquidGlass';

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
  style: CYLAnimatedItemBackgroundStyle;

  color: ResourceColor;

  cornerRadius: number;

  borderWidth: number;

  borderColor: ResourceColor;

  constructor(style: CYLAnimatedItemBackgroundStyle, color: ResourceColor, cornerRadius: number = -1, borderWidth: number = 0,
    borderColor: ResourceColor = Color.Transparent) {
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
   * [EN] The tint a glass draws with: a '#RRGGBB', '#AARRGGBB' or ARGB number color made translucent (its alpha times
   *      `CYLLiquidGlass.GLASS_TINT_ALPHA`), so an opaque color such as a selected tag's green tints the glass instead of covering it; the same rule as
   *      iOS and Android. Other kinds of color (a resource, a `Color` value) are used as they are.
   * [CN] 玻璃使用的着色：'#RRGGBB'、'#AARRGGBB' 或 ARGB 数值颜色变为半透明（其透明度乘以 `CYLLiquidGlass.GLASS_TINT_ALPHA`），因此选中标签的绿色这样的
   *      不透明色是给玻璃着色而不是盖住它；与 iOS、Android 同一规则。其他类型的颜色（资源、`Color` 值）原样使用。
   */
  static glassTint(color: ResourceColor): ResourceColor {
    // [EN] No color set: the default frosted tint (225, 222, 220 at alpha 0.5, as iOS in light mode). [CN] 未设置颜色：默认的磨砂着色（225, 222, 220，透明度 0.5，与 iOS 浅色模式相同）。
    if (color === Color.Transparent || color === '') {
      return '#80E1DEDC';
    }
    let argb: number = -1;
    if (typeof color === 'number') {
      argb = color >>> 0;
    } else if (typeof color === 'string') {
      const hex: RegExpMatchArray | null = color.match(/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/);
      if (hex !== null) {
        argb = hex[1].length === 6 ? (0xFF000000 + parseInt(hex[1], 16)) : parseInt(hex[1], 16);
      }
    }
    if (argb < 0) {
      return color;
    }
    const sourceAlpha: number = (argb >>> 24) & 0xFF;
    // [EN] A fully transparent color (alpha 0) means "no color" too: the default frosted tint. [CN] 完全透明的颜色（透明度 0）同样表示「没有颜色」：使用默认磨砂着色。
    if (sourceAlpha === 0) {
      return '#80E1DEDC';
    }
    const alpha: number = Math.round(sourceAlpha * CYLLiquidGlass.GLASS_TINT_ALPHA);
    return ((alpha << 24) | (argb & 0xFFFFFF)) >>> 0;
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    const glass: boolean = CYLAnimatedItemBackgroundModifier.isGlassDrawn(this.style);
    instance.backgroundEffect(glass ?
      { radius: CYLLiquidGlass.BLUR_RADIUS, saturation: CYLLiquidGlass.BLUR_SATURATION, brightness: CYLLiquidGlass.LIGHT_BRIGHTNESS } :
      { radius: 0 });
    instance.backgroundColor(glass ? CYLAnimatedItemBackgroundModifier.glassTint(this.color) : this.color);
    instance.borderRadius(CYLAnimatedItemBackgroundModifier.resolvedCornerRadius(this.style, this.cornerRadius));
    instance.borderWidth(this.borderWidth);
    instance.borderColor(this.borderColor);
    instance.clip(glass);
  }
}
