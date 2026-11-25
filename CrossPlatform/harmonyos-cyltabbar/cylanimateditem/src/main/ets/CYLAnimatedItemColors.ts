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

/**
 * [EN] The tint a glass draws with, for a '#RRGGBB', '#AARRGGBB' or ARGB number color: its alpha times `tintAlpha`, so an opaque color tints the glass
 *      instead of covering it. A color whose alpha is 0 (`#00000000`, `0`, 'transparent') is `defaultTint`, as if no color was set: a clear color
 *      would give no tint and the glass would be a faint halo on a white page. Undefined for any other text, which the caller uses as it is.
 *      Pure, unit tested with Node (test/CYLAnimatedItemColors.test.mjs).
 * [CN] 玻璃使用的着色，适用于 '#RRGGBB'、'#AARRGGBB' 或 ARGB 数值颜色：其透明度乘以 `tintAlpha`，因此不透明色是给玻璃着色而不是盖住它。透明度为 0 的颜色
 *      （`#00000000`、`0`、'transparent'）使用 `defaultTint`，与未设置颜色相同：透明色没有着色，玻璃在白色页面上只是一圈淡淡的光晕。其他文本返回 undefined，
 *      调用方原样使用。纯逻辑。
 */
export function cylAnimatedItemGlassTintColor(color: string | number, tintAlpha: number, defaultTint: string): string | number | undefined {
  let argb: number = -1;
  if (typeof color === 'number') {
    argb = color >>> 0;
  } else if (color.trim().toLowerCase() === 'transparent') {
    return defaultTint;
  } else {
    const hex: RegExpMatchArray | null = color.match(/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/);
    if (hex !== null) {
      argb = hex[1].length === 6 ? (0xFF000000 + parseInt(hex[1], 16)) : parseInt(hex[1], 16);
    }
  }
  if (argb < 0) {
    return undefined;
  }
  if (((argb >>> 24) & 0xFF) === 0) {
    return defaultTint;
  }
  const alpha: number = Math.round(((argb >>> 24) & 0xFF) * tintAlpha);
  return ((alpha << 24) | (argb & 0xFFFFFF)) >>> 0;
}

/** [EN] The "title" value of the animation tint (as iOS `CYLTabBarAnimationOptionTint`). [CN] 动画着色的 "title" 值。 */
export const CYL_ANIMATED_ITEM_TINT_TITLE: string = 'title';

/**
 * [EN] A tint color of the unified interface ("#RRGGBB" or "#RRGGBBAA", the "#" optional; the order of Rive's `tint` / `darkTint`
 *      options on iOS) as the "#AARRGGBB" string ArkUI takes; undefined when it is not one.
 * [CN] 统一接口的着色颜色（"#RRGGBB" 或 "#RRGGBBAA"，"#" 可省略；与 iOS 上 Rive 的 `tint` / `darkTint` 选项顺序相同），转为 ArkUI 使用的
 *      "#AARRGGBB" 字符串；不是时为 undefined。
 */
export function cylAnimatedItemTintArkColor(text: string): string | undefined {
  const hex = text.trim().replace(/^#/, '');
  if (!/^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hex)) {
    return undefined;
  }
  const argb = hex.length === 6 ? 'FF' + hex : hex.substring(6, 8) + hex.substring(0, 6);
  return '#' + argb.toUpperCase();
}

/**
 * [EN] What the tint resolution looks at (see `cylAnimatedItemResolveTint`). Tint texts are '' when not set.
 * [CN] 着色解析的输入（见 `cylAnimatedItemResolveTint`）。未设置的着色文本为 ''。
 */
export class CYLAnimatedItemTintInput {
  /** [EN] The view's `animationTint` property. [CN] 视图的 `animationTint` 属性。 */
  propTint: string = '';
  /** [EN] The view's `animationDarkTint` property. [CN] 视图的 `animationDarkTint` 属性。 */
  propDarkTint: string = '';
  /** [EN] The animation source's `tint` option. [CN] 动画来源的 `tint` 选项。 */
  optionTint: string = '';
  /** [EN] The animation source's `darkTint` option. [CN] 动画来源的 `darkTint` 选项。 */
  optionDarkTint: string = '';
  /** [EN] Whether the item is selected. [CN] 条目是否选中。 */
  selected: boolean = false;
  /** [EN] Whether the app is in dark mode. [CN] 是否为深色模式。 */
  dark: boolean = false;
  /** [EN] Whether the host set an icon color (`iconColor` is not ''). [CN] 宿主是否设置了图标颜色（`iconColor` 不是 ''）。 */
  hasIconColor: boolean = false;
}

/**
 * [EN] The outcome: `kind` 'none' (the file keeps its own colors), 'icon' (draw in the item's icon color) or 'fixed' (draw in `color`,
 *      a "#AARRGGBB" string).
 * [CN] 结果：`kind` 为 'none'（文件保持自身颜色）、'icon'（用条目的图标颜色绘制）或 'fixed'（用 `color` 绘制，"#AARRGGBB" 字符串）。
 */
export class CYLAnimatedItemTintResult {
  kind: string = 'none';
  color: string = '';
}

/**
 * [EN] The unified animation tint, as iOS Rive's `tint` / `darkTint`: a set property overrides the same option of the source (each of
 *      the two on its own); unset keeps the source's. No tint, or one that is not "title" nor a color: 'none'. "title": the item's icon
 *      color (the selected state's when selected, the host passes the one of the current state), 'none' without an icon color (no
 *      automatic recolor). A fixed color: the item's icon color when selected (without one, the fixed color), else the fixed color,
 *      or the dark one in dark mode when it is set and valid. The dark tint does nothing with "title". Pure, unit tested with Node.
 * [CN] 统一的动画着色，与 iOS Rive 的 `tint` / `darkTint` 一致：设置了的属性覆盖来源的同名选项（两者各自独立）；未设置则沿用来源的。没有着色，
 *      或既不是 "title" 也不是颜色：'none'。"title"：条目的图标颜色（选中时为选中状态的，宿主传入当前状态的那个），没有图标颜色时为 'none'
 *      （不自动改色）。固定颜色：选中时为条目的图标颜色（没有时用固定颜色），否则为固定颜色，深色模式下且设置了有效的深色值时为深色值。
 *      深色着色对 "title" 无效。纯逻辑，用 Node 做单元测试。
 */
export function cylAnimatedItemResolveTint(input: CYLAnimatedItemTintInput): CYLAnimatedItemTintResult {
  const result = new CYLAnimatedItemTintResult();
  const tint = (input.propTint.trim() !== '' ? input.propTint : input.optionTint).trim();
  const darkTint = (input.propDarkTint.trim() !== '' ? input.propDarkTint : input.optionDarkTint).trim();
  if (tint === CYL_ANIMATED_ITEM_TINT_TITLE) {
    if (input.hasIconColor) {
      result.kind = 'icon';
    }
    return result;
  }
  const fixed = cylAnimatedItemTintArkColor(tint);
  if (fixed === undefined) {
    return result;
  }
  if (input.selected && input.hasIconColor) {
    result.kind = 'icon';
    return result;
  }
  const dark = input.dark ? cylAnimatedItemTintArkColor(darkTint) : undefined;
  result.kind = 'fixed';
  result.color = dark ?? fixed;
  return result;
}
