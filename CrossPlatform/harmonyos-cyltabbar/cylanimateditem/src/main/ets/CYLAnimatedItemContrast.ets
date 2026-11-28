import { CYLAnimatedItemBackgroundModifier, CYLAnimatedItemBackgroundStyle } from './CYLAnimatedItemBackground';
import { CYLLiquidGlass } from './CYLLiquidGlass';

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

/** [EN] The kind of `CYLAnimatedItemContrast.adaptedOnGlass` for an icon / animation tint (3:1). [CN] `adaptedOnGlass` 的图标 / 动画着色类型（3:1）。 */
export const CYLAnimatedItemContrastKindIcon: string = 'icon';
/** [EN] The kind of `CYLAnimatedItemContrast.adaptedOnGlass` for a title text (4.5:1). [CN] `adaptedOnGlass` 的标题文字类型（4.5:1）。 */
export const CYLAnimatedItemContrastKindText: string = 'text';

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
  /**
   * [EN] The white share (0...1, the Y/255 of the rendered glass interior) that the glass reference never goes below: the dark Liquid Glass this
   *      platform really renders over a dark plate is brighter than the model (white 0.14 over black). MEASURED on the HarmonyOS 6 x86_64
   *      emulator (Mate 70 Pro), CYLAnimatedItemView with liquidGlass and no tint over the demo's dark plate gradient, `cylColorMode dark`:
   *      Rec.601 Y of the sRGB bytes in the middle band of the glass (away from glyphs and the top sheen band), median of 12 tags (Y 96.0, i.e. 0.376), then a
   *      margin of 0.02 (0.396, set to 0.4). Never copied from another platform. The model (`glassReferenceLuminance`) is unchanged.
   * [CN] 玻璃参考亮度的白色占比下限（0...1，即实际渲染的玻璃内部的 Y/255）：本平台在深色背板上真正渲染的深色液态玻璃比模型（黑底上 0.14 的白）更亮。
   *      在 HarmonyOS 6 x86_64 模拟器（Mate 70 Pro）上实测：未设置着色的 liquidGlass CYLAnimatedItemView 位于示例的深色背板渐变之上，`cylColorMode dark`：
   *      取玻璃中间带（避开字形与顶部高光带）sRGB 字节的 Rec.601 Y，多个标签的中位数，再加 0.02 余量。不照搬其他平台。模型（`glassReferenceLuminance`）不变。
   */
  static readonly renderedDarkGlassWhiteShare: number = 0.4;

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
   * [EN] The reference the lift judges against: `max(model, floor)`, the model being `glassReferenceLuminance` and the floor the luminance of
   *      `renderedDarkGlassWhiteShare` as a gray. The lift never judges against a glass darker than the one this platform really renders.
   * [CN] 提亮所对照的参考亮度：`max(模型, 下限)`，模型为 `glassReferenceLuminance`，下限为灰色 `renderedDarkGlassWhiteShare` 的亮度。提亮从不对照比本平台实际渲染更暗的玻璃。
   */
  static renderedGlassReferenceLuminance(glassTint: ResourceColor | undefined, tintAlpha: number | undefined): number {
    const share: number = CYLAnimatedItemContrast.renderedDarkGlassWhiteShare;
    return Math.max(CYLAnimatedItemContrast.glassReferenceLuminance(glassTint, tintAlpha),
      CYLAnimatedItemContrast.relativeLuminance(share, share, share));
  }

  /**
   * [EN] The colour to draw on the item's background: `color` itself (the same value) unless the glass is drawn for `style`
   *      (`CYLAnimatedItemBackgroundModifier.isGlassDrawn`) AND the mode is dark (`CYLLiquidGlass.isDark()`); then `adjustedColor` with the
   *      contrast of `kind`: `CYLAnimatedItemContrastKindIcon` = `minimumIconContrast` (3), `CYLAnimatedItemContrastKindText` (or any other
   *      kind) = `minimumTextContrast` (4.5).
   * [CN] 条目背景上应绘制的颜色：除非 `style` 绘制了玻璃（`isGlassDrawn`）且为深色模式（`CYLLiquidGlass.isDark()`），否则原值返回；否则按 `kind` 的对比度调用
   *      `adjustedColor`：`CYLAnimatedItemContrastKindIcon` 为 `minimumIconContrast`（3），`CYLAnimatedItemContrastKindText`（及其他值）为 `minimumTextContrast`（4.5）。
   */
  static adaptedOnGlass(color: ResourceColor, kind: string, style: CYLAnimatedItemBackgroundStyle, glassTint: ResourceColor | undefined,
    tintAlpha: number | undefined): ResourceColor {
    return CYLAnimatedItemContrast.adaptedOnGlassState(color, kind, CYLAnimatedItemBackgroundModifier.isGlassDrawn(style), CYLLiquidGlass.isDark(),
      glassTint, tintAlpha);
  }

  /**
   * [EN] The same rule with the item's state as plain inputs (what `CYLAnimatedItemView.adaptedOnGlass` calls): `drawsGlass` (the item's
   *      `drawsLiquidGlass`) and `dark` (the item's resolved colour mode); nothing global is read.
   * [CN] 同一规则，条目状态作为普通输入（`CYLAnimatedItemView.adaptedOnGlass` 所调用）：`drawsGlass`（条目的 `drawsLiquidGlass`）与 `dark`（条目解析后的颜色模式）；不读取任何全局状态。
   */
  static adaptedOnGlassState(color: ResourceColor, kind: string, drawsGlass: boolean, dark: boolean, glassTint: ResourceColor | undefined,
    tintAlpha: number | undefined): ResourceColor {
    if (!drawsGlass || !dark) {
      return color;
    }
    const minimum: number = kind === CYLAnimatedItemContrastKindIcon ? CYLAnimatedItemContrast.minimumIconContrast :
    CYLAnimatedItemContrast.minimumTextContrast;
    return CYLAnimatedItemContrast.adjustedColor(color, glassTint, tintAlpha, minimum);
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
    return CYLAnimatedItemContrast.adjustedToReference(color, CYLAnimatedItemContrast.renderedGlassReferenceLuminance(glassTint, tintAlpha),
      minimumContrast);
  }

  /**
   * [EN] The reference of a FLAT item that draws a fill (iOS `flatReferenceLuminance(fill:traits:)`, Android `flatReferenceLuminance`): the fill over black by its
   *      alpha; undefined for a fill that is not a static colour (a resource) or is clear (alpha 0): such an item is not adapted. No floor (the floor is glass-only).
   * [CN] 绘制填充的扁平条目的参考亮度（对应 iOS `flatReferenceLuminance(fill:traits:)`、Android `flatReferenceLuminance`）：填充按其透明度叠在黑色上；填充不是静态颜色（资源）
   *      或透明（alpha 0）时为 undefined：这样的条目不调整。没有下限（下限仅用于玻璃）。
   */
  static flatReferenceLuminance(fill: ResourceColor | undefined): number | undefined {
    const rgba: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(fill);
    if (rgba === undefined || rgba.alpha <= 0) {
      return undefined;
    }
    return CYLAnimatedItemContrast.relativeLuminance(rgba.red * rgba.alpha, rgba.green * rgba.alpha, rgba.blue * rgba.alpha);
  }

  /**
   * [EN] THE contrast rule of an item (iOS `adaptedForContrast(_:kind:)`) with its state as plain inputs: `color` itself unless `dark` AND (the glass is drawn OR
   *      `flatFill` is a static, non-clear fill); then lifted to the contrast of `kind` against the rendered glass or the fill over black. Lift-only: light text on a
   *      light fill is kept (never turned whiter), flat without a fill is not adapted.
   * [CN] 条目的对比度规则（对应 iOS `adaptedForContrast(_:kind:)`），状态作为普通输入：除非 `dark` 且（绘制玻璃或 `flatFill` 是静态、非透明的填充），否则原值返回；
   *      适用时按 `kind` 对照实际渲染的玻璃或叠在黑色上的填充提亮。只提亮：浅色填充上的浅色文字保持不变（绝不变得更白），没有填充的扁平背景不调整。
   */
  static adaptedForContrastState(color: ResourceColor, kind: string, drawsGlass: boolean, dark: boolean, glassTint: ResourceColor | undefined,
    tintAlpha: number | undefined, flatFill: ResourceColor | undefined): ResourceColor {
    if (!dark) {
      return color;
    }
    if (drawsGlass) {
      return CYLAnimatedItemContrast.adaptedOnGlassState(color, kind, true, true, glassTint, tintAlpha);
    }
    const reference: number | undefined = CYLAnimatedItemContrast.flatReferenceLuminance(flatFill);
    if (reference === undefined) {
      return color;
    }
    const minimum: number = kind === CYLAnimatedItemContrastKindIcon ? CYLAnimatedItemContrast.minimumIconContrast :
    CYLAnimatedItemContrast.minimumTextContrast;
    return CYLAnimatedItemContrast.adjustedToReference(color, reference, minimum);
  }

  /**
   * [EN] `color` lifted against a reference luminance: itself when not static or already passing; else the lowest passing lightness (steps of 0.005, at most white).
   *      When even white cannot pass (a light reference), whichever of the original and the lifted colour has more contrast: a lift never makes it worse.
   * [CN] 对照参考亮度提亮 `color`：非静态或已满足时原值返回；否则取满足要求的最低亮度（步长 0.005，最高为白色）。连白色也不能满足时（参考较亮），取原色与提亮色中对比度更高者：提亮绝不会更差。
   */
  static adjustedToReference(color: ResourceColor, reference: number, minimumContrast: number): ResourceColor {
    const rgba: CYLAnimatedItemContrastRGBA | undefined = CYLAnimatedItemContrast.components(color);
    if (rgba === undefined) {
      return color;
    }
    const hsl: CYLAnimatedItemContrastHSL = CYLAnimatedItemContrast.hslFromRGB(rgba.red, rgba.green, rgba.blue);
    const original: number = CYLAnimatedItemContrast.ratio(hsl, hsl.lightness, reference);
    if (original >= minimumContrast) {
      return color;
    }
    let lightness: number = hsl.lightness;
    while (lightness < 1 && CYLAnimatedItemContrast.ratio(hsl, lightness, reference) < minimumContrast) {
      lightness = Math.min(1, lightness + CYLAnimatedItemContrast.lightnessStep);
    }
    if (CYLAnimatedItemContrast.ratio(hsl, lightness, reference) < minimumContrast && original >= CYLAnimatedItemContrast.ratio(hsl, lightness, reference)) {
      return color;
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
