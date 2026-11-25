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
  // [EN] The same rule on every platform: a '#' and exactly 6 (RRGGBB) or 8 (RRGGBBAA) hex digits. [CN] 各平台相同的规则：必须有 '#'，且恰好 6 位（RRGGBB）或 8 位（RRGGBBAA）十六进制。
  const trimmed = text.trim();
  if (!/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(trimmed)) {
    return undefined;
  }
  const hex = trimmed.substring(1);
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
  /** [EN] Whether the host set a normal icon color (`iconColor` is not ''). [CN] 宿主是否设置了普通图标颜色（`iconColor` 不是 ''）。 */
  hasIconColor: boolean = false;
  /** [EN] Whether the host set a selected icon color (`selectedIconColor` is not ''). [CN] 宿主是否设置了选中图标颜色（`selectedIconColor` 不是 ''）。 */
  hasSelectedIconColor: boolean = false;
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
 * [EN] The unified animation tint, the truth table shared by iOS, Android, HarmonyOS and the mini program: a set property overrides the same
 *      option of the source (each of the two on its own); unset keeps the source's. No tint, or text that is neither "title" nor a color
 *      (= unset): 'none'. "title": 'icon' when selected with a selected icon color, else 'icon' with a normal icon color (the view then draws in
 *      its selected icon color when selected and it has one, else the normal one), else 'none' (no automatic recolor). A fixed color:
 *      selected with a selected icon color: 'icon'; else 'fixed' in the color, or the dark one in dark mode when it is valid. The dark tint
 *      does nothing with "title". 8-digit hex is always #RRGGBBAA. Pure, unit tested with Node (table driven).
 * [CN] 统一的动画着色，iOS、Android、HarmonyOS 与小程序共用的真值表：设置了的属性覆盖来源的同名选项（两者各自独立）；未设置则沿用来源的。没有着色，
 *      或文本既不是 "title" 也不是颜色（即未设置）：'none'。"title"：选中且有选中图标颜色时为 'icon'，否则有普通图标颜色时为 'icon'（视图选中且有选中
 *      图标颜色时用它绘制，否则用普通的），都没有时为 'none'（不自动改色）。固定颜色：选中且有选中图标颜色时为 'icon'；否则为 'fixed'，颜色为
 *      固定颜色，深色模式下且深色值有效时为深色值。深色着色对 "title" 无效。8 位十六进制始终是 #RRGGBBAA。纯逻辑，用 Node 做表驱动单元测试。
 */
export function cylAnimatedItemResolveTint(input: CYLAnimatedItemTintInput): CYLAnimatedItemTintResult {
  const result = new CYLAnimatedItemTintResult();
  const tint = (input.propTint.trim() !== '' ? input.propTint : input.optionTint).trim();
  const darkTint = (input.propDarkTint.trim() !== '' ? input.propDarkTint : input.optionDarkTint).trim();
  if (tint === CYL_ANIMATED_ITEM_TINT_TITLE) {
    if ((input.selected && input.hasSelectedIconColor) || input.hasIconColor) {
      result.kind = 'icon';
    }
    return result;
  }
  const fixed = cylAnimatedItemTintArkColor(tint);
  if (fixed === undefined) {
    return result;
  }
  if (input.selected && input.hasSelectedIconColor) {
    result.kind = 'icon';
    return result;
  }
  const dark = input.dark ? cylAnimatedItemTintArkColor(darkTint) : undefined;
  result.kind = 'fixed';
  result.color = dark ?? fixed;
  return result;
}

/**
 * [EN] Stack inheritance: the effective value of a setting is the item's own when it is set (not '' after trimming), else the stack's
 *      (iOS `item ?? stack`). A set but invalid own value still wins (it is "set"); clearing it to '' inherits again.
 * [CN] 堆叠继承：设置项的生效值为条目自己的值（trim 后不为 ''），否则为堆叠的（iOS 的 `item ?? stack`）。设置了但无效的自有值仍然优先（它「已设置」）；
 *      清空为 '' 后重新继承。
 */
export function cylAnimatedItemEffective(own: string, inherited: string): string {
  return own.trim() !== '' ? own : inherited;
}

/** [EN] The alpha of a divider drawn in the icon color (CYLAnimatedItemDividerAlpha). [CN] 以图标颜色绘制分隔线时的透明度。 */
export const CYL_ANIMATED_ITEM_DIVIDER_ALPHA: number = 0.3;

/** [EN] The default length of a divider line in vp (CYLAnimatedItemDividerLength); its thickness is 1 vp. [CN] 分隔线的默认长度（vp）；粗细为 1 vp。 */
export const CYL_ANIMATED_ITEM_DIVIDER_LENGTH: number = 20;

/** [EN] The separator color of the platform fallback (iOS `UIColor.separator`), light, "#AARRGGBB". [CN] 平台后备分隔色（iOS `UIColor.separator`），浅色。 */
export const CYL_ANIMATED_ITEM_SEPARATOR_LIGHT: string = '#4A3C3C43';
/** [EN] The same, dark. [CN] 同上，深色。 */
export const CYL_ANIMATED_ITEM_SEPARATOR_DARK: string = '#99545458';

/**
 * [EN] What the divider color resolution looks at (see `cylAnimatedItemDividerColor`). Colors are '' when not set; they are ArkUI color
 *      texts ('#RRGGBB' / '#AARRGGBB'). `iconColor` is the NORMAL-state icon color (the effective one: own, else the stack's).
 * [CN] 分隔线颜色解析的输入（见 `cylAnimatedItemDividerColor`）。未设置的颜色为 ''；均为 ArkUI 颜色文本。`iconColor` 是普通状态的图标颜色（生效值：自有，否则堆叠的）。
 */
export class CYLAnimatedItemDividerInput {
  dividerColor: string = '';
  iconColor: string = '';
  dark: boolean = false;
}

/**
 * [EN] The outcome: `source` 'divider' | 'icon' | 'separator', the `color` text to draw and the `opacity` to draw it with (1, except for an
 *      icon color that is not a hex text: the text as it is with opacity 0.3).
 * [CN] 结果：`source` 为 'divider' | 'icon' | 'separator'，绘制用的 `color` 文本与 `opacity`（均为 1，图标颜色不是十六进制文本时除外：原文本加透明度 0.3）。
 */
export class CYLAnimatedItemDividerResult {
  source: string = 'separator';
  color: string = '';
  opacity: number = 1;
}

/**
 * [EN] The divider line color: `dividerColor` as it is when set; else the icon color at alpha 0.3 (the alpha REPLACES the color's own, as
 *      iOS `withAlphaComponent`); else the separator color of the mode. Pure, unit tested with Node (table driven).
 * [CN] 分隔线颜色：设置了 `dividerColor` 时原样使用；否则为透明度 0.3 的图标颜色（透明度替换颜色自带的，同 iOS `withAlphaComponent`）；否则为当前模式的分隔色。
 *      纯逻辑，用 Node 做表驱动单元测试。
 */
export function cylAnimatedItemDividerColor(input: CYLAnimatedItemDividerInput): CYLAnimatedItemDividerResult {
  const result = new CYLAnimatedItemDividerResult();
  if (input.dividerColor.trim() !== '') {
    result.source = 'divider';
    result.color = input.dividerColor;
    return result;
  }
  if (input.iconColor.trim() !== '') {
    result.source = 'icon';
    const rgba = cylAnimatedItemParseHexColor(input.iconColor);
    if (input.iconColor.trim().startsWith('#') && rgba !== undefined) {
      const alpha = Math.round(255 * CYL_ANIMATED_ITEM_DIVIDER_ALPHA).toString(16).toUpperCase().padStart(2, '0');
      const hex = (value: number): string => value.toString(16).toUpperCase().padStart(2, '0');
      result.color = '#' + alpha + hex(rgba.red) + hex(rgba.green) + hex(rgba.blue);
    } else {
      result.color = input.iconColor;
      result.opacity = CYL_ANIMATED_ITEM_DIVIDER_ALPHA;
    }
    return result;
  }
  result.color = input.dark ? CYL_ANIMATED_ITEM_SEPARATOR_DARK : CYL_ANIMATED_ITEM_SEPARATOR_LIGHT;
  return result;
}
