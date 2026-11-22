/**
 * [EN] The colors of `CYLAnimatedItemPlayer.applyColors` ("#RRGGBB" or "#AARRGGBB", "#" optional) as components, for the
 *      engines that recolor (Lottie, Rive). Pure, unit tested with Node (test/CYLAnimatedItemColors.test.mjs).
 * [CN] `CYLAnimatedItemPlayer.applyColors` 的颜色（"#RRGGBB" 或 "#AARRGGBB"，"#" 可省略）转为分量，供能改色的引擎（Lottie、Rive）使用。纯逻辑。
 */
export class CYLAnimatedItemRGBA {
  /** [EN] 0...255 each. [CN] 每个分量 0...255。 */
  red: number = 0;
  green: number = 0;
  blue: number = 0;
  alpha: number = 255;
}

/** [EN] The components of a hex color, or undefined when it is not one. [CN] 十六进制颜色的分量；不是时为 undefined。 */
export function cylAnimatedItemParseHexColor(text: string): CYLAnimatedItemRGBA | undefined {
  const hex = text.trim().replace(/^#/, '');
  if (!/^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hex)) {
    return undefined;
  }
  const value = (index: number): number => parseInt(hex.substring(index, index + 2), 16);
  const color = new CYLAnimatedItemRGBA();
  const offset = hex.length === 8 ? 2 : 0;
  color.alpha = hex.length === 8 ? value(0) : 255;
  color.red = value(offset);
  color.green = value(offset + 2);
  color.blue = value(offset + 4);
  return color;
}

/**
 * [EN] The color as a signed 32-bit ARGB integer (Rive's color properties).
 * [CN] 颜色的有符号 32 位 ARGB 整数（Rive 的颜色属性）。
 */
export function cylAnimatedItemARGBInteger(color: CYLAnimatedItemRGBA): number {
  const byte = (component: number): number => Math.max(0, Math.min(255, Math.round(component)));
  return (byte(color.alpha) * 0x1000000 + byte(color.red) * 0x10000 + byte(color.green) * 0x100 + byte(color.blue)) | 0;
}
