/**
 * [EN] The dark Liquid Glass colour adaptation of an item (ClassifyMenu's `CYLIconContrast` rule, moved here so no host has to apply it): an
 *      EXPLICIT, static title or icon colour that does not contrast enough with the dark glass behind it is lightened (HSL lightness raised in
 *      steps of 0.005, never above white; hue, saturation and alpha kept) until it reaches 4.5:1 (text) or 3:1 (icon, animation tint) against
 *      the glass over black. Unchanged: a colour that already passes, a colour that is not a '#RRGGBB' / '#AARRGGBB' string or a non-zero-alpha
 *      ARGB number (a Resource, a `Color` constant: dynamic). The caller applies it only where the glass is drawn and the mode is dark. Light
 *      glass is NOT adapted (no symmetric rule). Pure: no platform state is read.
 * [CN] 条目的深色液态玻璃颜色适配（ClassifyMenu 的 `CYLIconContrast` 规则，移到这里，宿主无需再做）：显式、静态的标题或图标颜色与其后的深色玻璃对比不足时，
 *      提高 HSL 亮度（步长 0.005，不超过白色；保持色相、饱和度与透明度），直到相对黑底上的玻璃达到 4.5:1（文字）或 3:1（图标、动画着色）。不变：已满足的颜色、
 *      不是 '#RRGGBB' / '#AARRGGBB' 字符串或非零透明度 ARGB 数值的颜色（资源、`Color` 常量：动态）。仅在绘制玻璃且为深色模式时由调用方使用。浅色玻璃不适配。纯逻辑。
 */
const BYTE_MAX: number = 255;
const BYTE_COUNT: number = 256;
const RGB_DIGITS: number = 6;
const ARGB_DIGITS: number = 8;
const HEX_RADIX: number = 16;
const HEX_PATTERN: string = '^[0-9a-fA-F]+$';
const LUMINANCE_OFFSET: number = 0.05;
const HUE_SECTORS: number = 6;
const PAIR: number = 2;
const LUMA_RED: number = 0.2126;
const LUMA_GREEN: number = 0.7152;
const LUMA_BLUE: number = 0.0722;
const LINEAR_KNEE: number = 0.03928;
const LINEAR_SLOPE: number = 12.92;
const LINEAR_OFFSET: number = 0.055;
const LINEAR_SCALE: number = 1.055;
const LINEAR_GAMMA: number = 2.4;
const ALPHA_SHIFT: number = 16777216;
const RED_SHIFT: number = 65536;
const GREEN_SHIFT: number = 256;

/** [EN] sRGB components and alpha, all 0...1. [CN] sRGB 分量与透明度，均为 0...1。 */
export class CYLAnimatedItemContrastRGBA {
  red: number = 0;
  green: number = 0;
  blue: number = 0;
  alpha: number = 1;

  constructor(red: number, green: number, blue: number, alpha: number) {
    this.red = red;
    this.green = green;
    this.blue = blue;
    this.alpha = alpha;
  }
}

/** [EN] Hue, saturation and lightness, all 0...1. [CN] 色相、饱和度与亮度，均为 0...1。 */
export class CYLAnimatedItemContrastHSL {
  hue: number = 0;
  saturation: number = 0;
  lightness: number = 0;

  constructor(hue: number, saturation: number, lightness: number) {
    this.hue = hue;
    this.saturation = saturation;
    this.lightness = lightness;
  }
}

export class CYLAnimatedItemContrast {
  /** [EN] The least contrast of an icon / animation tint. [CN] 图标与动画着色的最低对比度。 */
  static readonly minimumIconContrast: number = 3;
  /** [EN] The least contrast of a title text. [CN] 标题文字的最低对比度。 */
  static readonly minimumTextContrast: number = 4.5;
  /** [EN] The white share of the default frosted glass in dark mode. [CN] 深色模式默认磨砂玻璃的白色占比。 */
  static readonly frostedGlassWhiteAlpha: number = 0.14;
  /** [EN] The share of an explicit tint's alpha that tints the glass when no tint alpha is given. [CN] 未给 tintAlpha 时显式着色透明度的占比。 */
  static readonly defaultGlassTintShare: number = 0.75;
  /** [EN] The lightness step. [CN] 亮度步长。 */
  static readonly lightnessStep: number = 0.005;

  /** [EN] The WCAG relative luminance of sRGB components 0...1. [CN] sRGB 分量（0...1）的 WCAG 相对亮度。 */
  static relativeLuminance(red: number, green: number, blue: number): number {
    const linear = (value: number): number => value <= LINEAR_KNEE ? value / LINEAR_SLOPE :
      Math.pow((value + LINEAR_OFFSET) / LINEAR_SCALE, LINEAR_GAMMA);
    return LUMA_RED * linear(red) + LUMA_GREEN * linear(green) + LUMA_BLUE * linear(blue);
  }

  /** [EN] The WCAG contrast ratio of two relative luminances, 1 to 21. [CN] 两个相对亮度的 WCAG 对比度，1 到 21。 */
  static contrastRatio(first: number, second: number): number {
    return (Math.max(first, second) + LUMINANCE_OFFSET) / (Math.min(first, second) + LUMINANCE_OFFSET);
  }

  /**
   * [EN] The components of a static colour: '#RRGGBB', '#AARRGGBB', or an ARGB number with a non-zero alpha byte; undefined for anything else.
   * [CN] 静态颜色的分量：'#RRGGBB'、'#AARRGGBB'，或透明度字节非零的 ARGB 数值；其他返回 undefined。
   */
  static components(color: ResourceColor | undefined): CYLAnimatedItemContrastRGBA | undefined {
    if (typeof color === 'number') {
      const argb: number = (color as number) >>> 0;
      const alpha: number = Math.floor(argb / ALPHA_SHIFT) % BYTE_COUNT;
      if (alpha === 0) {
        return undefined;
      }
      return new CYLAnimatedItemContrastRGBA(Math.floor(argb / RED_SHIFT) % BYTE_COUNT / BYTE_MAX,
        Math.floor(argb / GREEN_SHIFT) % BYTE_COUNT / BYTE_MAX, argb % BYTE_COUNT / BYTE_MAX, alpha / BYTE_MAX);
    }
    if (typeof color !== 'string') {
      return undefined;
    }
    const hex: string = (color as string).trim().replace('#', '');
    if ((hex.length !== RGB_DIGITS && hex.length !== ARGB_DIGITS) || !new RegExp(HEX_PATTERN).test(hex)) {
      return undefined;
    }
    const argbText: string = hex.length === RGB_DIGITS ? 'FF' + hex : hex;
    const byteAt = (index: number): number => parseInt(argbText.substring(index * PAIR, index * PAIR + PAIR), HEX_RADIX) / BYTE_MAX;
    return new CYLAnimatedItemContrastRGBA(byteAt(1), byteAt(PAIR), byteAt(PAIR + 1), byteAt(0));
  }

  /**
   * [EN] The luminance of the glass over black: the default frosted glass (`glassTint` undefined, not static, or fully transparent) is white at
   *      0.14; an explicit tint is its colour x alpha x `tintAlpha` (0.75 when undefined or negative).
   * [CN] 黑底上玻璃的亮度：默认磨砂玻璃（未设置、非静态或全透明）为 0.14 的白色；显式着色为其颜色 x 透明度 x `tintAlpha`（未设置或为负时为 0.75）。
   */
  static glassReferenceLuminance(glassTint: ResourceColor | undefined, tintAlpha: number | undefined): number {
    const tint: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(glassTint);
    if (tint === undefined || tint.alpha <= 0) {
      const white: number = CYLAnimatedItemContrast.frostedGlassWhiteAlpha;
      return CYLAnimatedItemContrast.relativeLuminance(white, white, white);
    }
    const share: number = tint.alpha * (tintAlpha === undefined || tintAlpha < 0 ? CYLAnimatedItemContrast.defaultGlassTintShare : tintAlpha);
    return CYLAnimatedItemContrast.relativeLuminance(tint.red * share, tint.green * share, tint.blue * share);
  }

  /**
   * [EN] The colour to draw in dark mode on glass: `color` itself (the same value) when the rule does not apply or it already has
   *      `minimumContrast`; else its lightness raised in steps of 0.005 (never above white), alpha kept, in the kind it came in (a number stays a
   *      number, a string becomes '#AARRGGBB'). The caller calls it only when the glass is drawn and the mode is dark.
   * [CN] 深色模式下玻璃上应绘制的颜色：规则不适用或已满足 `minimumContrast` 时原值返回；否则按 0.005 步长提高亮度（不超过白色），保持透明度，类型不变（数值仍为数值，
   *      字符串变为 '#AARRGGBB'）。仅在绘制玻璃且为深色模式时调用。
   */
  static adjustedColor(color: ResourceColor, glassTint: ResourceColor | undefined, tintAlpha: number | undefined,
    minimumContrast: number): ResourceColor {
    const rgba: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(color);
    if (rgba === undefined) {
      return color;
    }
    const reference: number = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint, tintAlpha);
    const hsl: CYLAnimatedItemContrastHSL = CYLAnimatedItemContrast.hslFromRGB(rgba.red, rgba.green, rgba.blue);
    if (CYLAnimatedItemContrast.ratio(hsl, hsl.lightness, reference) >= minimumContrast) {
      return color;
    }
    let lightness: number = hsl.lightness;
    while (lightness < 1 && CYLAnimatedItemContrast.ratio(hsl, lightness, reference) < minimumContrast) {
      lightness = Math.min(1, lightness + CYLAnimatedItemContrast.lightnessStep);
    }
    const lifted: CYLAnimatedItemContrastRGBA = CYLAnimatedItemContrast.rgbFromHSL(hsl.hue, hsl.saturation, lightness);
    const alphaByte: number = Math.round(rgba.alpha * BYTE_MAX);
    const redByte: number = Math.round(Math.min(1, Math.max(0, lifted.red)) * BYTE_MAX);
    const greenByte: number = Math.round(Math.min(1, Math.max(0, lifted.green)) * BYTE_MAX);
    const blueByte: number = Math.round(Math.min(1, Math.max(0, lifted.blue)) * BYTE_MAX);
    if (typeof color === 'number') {
      return alphaByte * ALPHA_SHIFT + redByte * RED_SHIFT + greenByte * GREEN_SHIFT + blueByte;
    }
    const pad = (byte: number): string => (byte < HEX_RADIX ? '0' : '') + byte.toString(HEX_RADIX).toUpperCase();
    return '#' + pad(alphaByte) + pad(redByte) + pad(greenByte) + pad(blueByte);
  }

  private static ratio(hsl: CYLAnimatedItemContrastHSL, lightness: number, reference: number): number {
    const rgb: CYLAnimatedItemContrastRGBA = CYLAnimatedItemContrast.rgbFromHSL(hsl.hue, hsl.saturation, lightness);
    return CYLAnimatedItemContrast.contrastRatio(CYLAnimatedItemContrast.relativeLuminance(rgb.red, rgb.green, rgb.blue), reference);
  }

  /** [EN] HSL of an sRGB colour (components 0...1). [CN] sRGB 颜色（分量 0...1）的 HSL。 */
  static hslFromRGB(red: number, green: number, blue: number): CYLAnimatedItemContrastHSL {
    const high: number = Math.max(red, green, blue);
    const low: number = Math.min(red, green, blue);
    const lightness: number = (high + low) / PAIR;
    const delta: number = high - low;
    if (delta <= 0) {
      return new CYLAnimatedItemContrastHSL(0, 0, lightness);
    }
    const saturation: number = delta / (1 - Math.abs(PAIR * lightness - 1));
    let hue: number;
    if (high === red) {
      hue = (green - blue) / delta;
      if (hue < 0) {
        hue += HUE_SECTORS;
      }
    } else if (high === green) {
      hue = (blue - red) / delta + PAIR;
    } else {
      hue = (red - green) / delta + PAIR * PAIR;
    }
    return new CYLAnimatedItemContrastHSL(hue / HUE_SECTORS, saturation, lightness);
  }

  /** [EN] The sRGB colour (components 0...1) of an HSL triple. [CN] HSL 三元组对应的 sRGB 颜色（分量 0...1）。 */
  static rgbFromHSL(hue: number, saturation: number, lightness: number): CYLAnimatedItemContrastRGBA {
    const chroma: number = (1 - Math.abs(PAIR * lightness - 1)) * saturation;
    const sector: number = hue * HUE_SECTORS;
    const second: number = chroma * (1 - Math.abs((sector % PAIR) - 1));
    const base: number = lightness - chroma / PAIR;
    let red: number = chroma;
    let green: number = 0;
    let blue: number = second;
    switch (Math.floor(sector) % HUE_SECTORS) {
      case 0:
        red = chroma;
        green = second;
        blue = 0;
        break;
      case 1:
        red = second;
        green = chroma;
        blue = 0;
        break;
      case 2:
        red = 0;
        green = chroma;
        blue = second;
        break;
      case 3:
        red = 0;
        green = second;
        blue = chroma;
        break;
      case 4:
        red = second;
        green = 0;
        blue = chroma;
        break;
      default:
        break;
    }
    return new CYLAnimatedItemContrastRGBA(red + base, green + base, blue + base, 1);
  }
}
