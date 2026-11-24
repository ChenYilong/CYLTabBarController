import { CYLLiquidGlass } from './CYLLiquidGlass';

/**
 * [EN] What an item's background is made of: the solid color (`flat`, the default) or Liquid Glass (a blur imitation tinted with
 *      the color, where `CYLLiquidGlass.isActive()`; flat elsewhere, the other parameters kept).
 * [CN] 条目背景的构成：纯色（`flat`，默认）或液态玻璃（带着色的模糊仿制，在 `CYLLiquidGlass.isActive()` 时；否则为扁平，其他参数保持）。
 */
/**
 * [EN] The corner radius of a capsule, vp: pass this constant as `cornerRadius`, never the number 1000. 0 is square; no other value has a
 *      special meaning (-1 is not set: a capsule for the drawn glass).
 * [CN] 胶囊的圆角半径（vp）：作为 `cornerRadius` 传这个常量，不要传数字 1000。0 为直角；其他值没有特殊含义（-1 表示未设置：绘制玻璃时为胶囊）。
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
 *      `cornerRadius` -1 is not set: a capsule for every style; a value of 0 or more customizes it.
 * [CN] 鸿蒙上决定并应用条目背景的唯一位置：`CYLAnimatedItemView` 用它处理自己的根节点；条目不是 `CYLAnimatedItemView` 的宿主（CollectionViewClassifyMenu 的
 *      标签）用 `.attributeModifier(new CYLAnimatedItemBackgroundModifier(...))` 把同样的背景应用到自己的容器，因此不保留任何玻璃、模糊或胶囊代码。
 *      `cornerRadius` 为 -1 表示未设置：所有样式均为胶囊；0 及以上的值用于自定义。
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
   * [EN] The radius: the set value, else a capsule for every style. [CN] 圆角：设置的值，否则所有样式均为胶囊。
   */
  static resolvedCornerRadius(style: CYLAnimatedItemBackgroundStyle, cornerRadius: number): number {
    if (cornerRadius >= 0) {
      return cornerRadius;
    }
    return CYLAnimatedItemCornerRadiusCapsule;
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    const glass: boolean = CYLAnimatedItemBackgroundModifier.isGlassDrawn(this.style);
    instance.backgroundEffect(glass ?
      { radius: CYLLiquidGlass.BLUR_RADIUS, saturation: CYLLiquidGlass.BLUR_SATURATION, brightness: CYLLiquidGlass.LIGHT_BRIGHTNESS } :
      { radius: 0 });
    instance.backgroundColor(this.color);
    instance.borderRadius(CYLAnimatedItemBackgroundModifier.resolvedCornerRadius(this.style, this.cornerRadius));
    instance.borderWidth(this.borderWidth);
    instance.borderColor(this.borderColor);
    instance.clip(glass);
  }
}
