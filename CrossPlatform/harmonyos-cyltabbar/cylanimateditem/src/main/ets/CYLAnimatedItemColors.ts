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

/** [EN] `animationRenderingMode` automatic (the default): tint only a file detected as one color. [CN] 自动（默认）：只给检测为单色的文件着色。 */
export const CYL_RENDERING_MODE_AUTOMATIC: string = 'automatic';
/** [EN] Always tint with the effective icon color. [CN] 始终用生效的图标颜色着色。 */
export const CYL_RENDERING_MODE_TEMPLATE: string = 'alwaysTemplate';
/** [EN] Never tint (unless an explicit `animationTint`). [CN] 从不着色（除非显式设置 `animationTint`）。 */
export const CYL_RENDERING_MODE_ORIGINAL: string = 'alwaysOriginal';

/** [EN] A rendering mode text as one of the three constants; anything else (and '') is automatic. [CN] 渲染模式文本归一为三个常量之一；其他（含 ''）为 automatic。 */
export function cylAnimatedItemRenderingMode(text: string): string {
  const trimmed = text.trim().toLowerCase();
  if (trimmed === CYL_RENDERING_MODE_TEMPLATE.toLowerCase()) {
    return CYL_RENDERING_MODE_TEMPLATE;
  }
  if (trimmed === CYL_RENDERING_MODE_ORIGINAL.toLowerCase()) {
    return CYL_RENDERING_MODE_ORIGINAL;
  }
  return CYL_RENDERING_MODE_AUTOMATIC;
}

/**
 * [EN] The effective rendering mode: the item's own when it is not automatic, else the `renderingMode=` option of the animation URL
 *      when it is set (and valid), else the stack's, else automatic. (automatic is the "not set" value of the item and of the stack.)
 * [CN] 生效的渲染模式：条目自己的（不是 automatic 时），否则动画 URL 的 `renderingMode=` 选项（已设置且有效时），否则堆叠的，否则 automatic。
 *      （automatic 即条目与堆叠的「未设置」值。）
 */
export function cylAnimatedItemEffectiveRenderingMode(own: string, urlOption: string, stack: string): string {
  const item = cylAnimatedItemRenderingMode(own);
  if (item !== CYL_RENDERING_MODE_AUTOMATIC) {
    return item;
  }
  const option = cylAnimatedItemRenderingMode(urlOption);
  if (option !== CYL_RENDERING_MODE_AUTOMATIC) {
    return option;
  }
  return cylAnimatedItemRenderingMode(stack);
}

/**
 * [EN] What the tint resolution looks at (see `cylAnimatedItemResolveTint`). Tint texts are '' when not set.
 * [CN] 着色解析的输入（见 `cylAnimatedItemResolveTint`）。未设置的着色文本为 ''。
 */
export class CYLAnimatedItemTintInput {
  /** [EN] The view's `animationTint` property (already merged with the stack's). [CN] 视图的 `animationTint` 属性（已与堆叠的合并）。 */
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
  /**
   * [EN] Whether an EXPLICIT selected icon color exists (the item's or the stack's; never the built-in selected color): only that one makes a
   *      fixed tint on a selected item yield. [CN] 是否存在显式的选中图标颜色（条目或堆叠的；不含内置选中色）：只有它会让选中条目上的固定着色让位。
   */
  hasSelectedIconColor: boolean = false;
  /** [EN] The effective rendering mode (`cylAnimatedItemEffectiveRenderingMode`); used only when no tint is set. [CN] 生效的渲染模式；仅在未设置着色时使用。 */
  renderingMode: string = CYL_RENDERING_MODE_AUTOMATIC;
  /** [EN] The detection of the file: 'oneColor' | 'multiColor' | 'unknown' (CYLAnimatedItemColorCount). [CN] 文件的检测结果。 */
  colorKind: string = 'unknown';
}

/**
 * [EN] The outcome: `kind` 'none' (the file keeps its own colors), 'icon' (draw in the item's EFFECTIVE icon color of the current state) or
 *      'fixed' (draw in `color`, a "#AARRGGBB" string).
 * [CN] 结果：`kind` 为 'none'（文件保持自身颜色）、'icon'（用条目当前状态下生效的图标颜色绘制）或 'fixed'（用 `color` 绘制，"#AARRGGBB" 字符串）。
 */
export class CYLAnimatedItemTintResult {
  kind: string = 'none';
  color: string = '';
}

/**
 * [EN] The unified animation tint (tint spec v2), the truth table shared by iOS, Android, HarmonyOS and the mini program. An explicit tint
 *      (the property over the `tint` option of the source; each of the two on its own) always wins over the rendering mode:
 *      "title": 'icon' (the effective icon color always exists: explicit, stack, or built-in). A fixed color: selected with an EXPLICIT
 *      selected icon color: 'icon'; else 'fixed' in the color, or the dark one in dark mode when it is valid. The dark tint does nothing
 *      with "title". 8-digit hex is always #RRGGBBAA. No tint (unset, or text that is neither "title" nor a color): by the rendering mode:
 *      alwaysTemplate 'icon'; alwaysOriginal 'none'; automatic 'icon' only when the file is detected as 'oneColor' (multi-color and
 *      undetectable files keep their colors). Pure, unit tested with Node (table driven).
 * [CN] 统一的动画着色（着色规范 v2），iOS、Android、HarmonyOS 与小程序共用的真值表。显式着色（属性覆盖来源的 `tint` 选项；两者各自独立）始终优先于渲染模式：
 *      "title"：'icon'（生效的图标颜色一定存在：显式、堆叠或内置）。固定颜色：选中且有显式选中图标颜色时为 'icon'；否则为 'fixed'，颜色为固定颜色，
 *      深色模式下且深色值有效时为深色值。深色着色对 "title" 无效。8 位十六进制始终是 #RRGGBBAA。没有着色（未设置，或文本既不是 "title" 也不是颜色）：
 *      按渲染模式：alwaysTemplate 为 'icon'；alwaysOriginal 为 'none'；automatic 仅当文件检测为 'oneColor' 时为 'icon'（多色与无法检测的文件保持原色）。
 */
export function cylAnimatedItemResolveTint(input: CYLAnimatedItemTintInput): CYLAnimatedItemTintResult {
  const result = new CYLAnimatedItemTintResult();
  const tint = (input.propTint.trim() !== '' ? input.propTint : input.optionTint).trim();
  const darkTint = (input.propDarkTint.trim() !== '' ? input.propDarkTint : input.optionDarkTint).trim();
  if (tint === CYL_ANIMATED_ITEM_TINT_TITLE) {
    result.kind = 'icon';
    return result;
  }
  const fixed = cylAnimatedItemTintArkColor(tint);
  if (fixed === undefined) {
    const mode = cylAnimatedItemRenderingMode(input.renderingMode);
    if (mode === CYL_RENDERING_MODE_TEMPLATE || (mode === CYL_RENDERING_MODE_AUTOMATIC && input.colorKind === 'oneColor')) {
      result.kind = 'icon';
    }
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

/** [EN] The alpha of a divider drawn in an explicit icon color (CYLAnimatedItemDividerAlpha); it was 0.3 (too faint, 1.3:1). [CN] 以显式图标颜色绘制分隔线时的透明度（原为 0.3，太淡）。 */
export const CYL_ANIMATED_ITEM_DIVIDER_ALPHA: number = 0.6;

/** [EN] The default length of a divider line in vp (CYLAnimatedItemDividerLength); its thickness is 1 vp. [CN] 分隔线的默认长度（vp）；粗细为 1 vp。 */
export const CYL_ANIMATED_ITEM_DIVIDER_LENGTH: number = 20;

/**
 * [EN] A built-in color: `resource` is the name under `sys.color.` that the view draws with (the system adapts it to light and dark), '' when
 *      the SDK has no matching color; `color` is the constant of the mode ("#AARRGGBB", the iOS system values measured on the iOS 27.2
 *      simulator): drawn when `resource` is '', and what the contrast tests pin.
 * [CN] 内置颜色：`resource` 是视图绘制时使用的 `sys.color.` 下的名称（系统自动适配深浅色），SDK 没有对应颜色时为 ''；`color` 是该模式的常量
 *      （"#AARRGGBB"，取自 iOS 27.2 模拟器实测的 iOS 系统值）：`resource` 为 '' 时使用，也是对比度测试所固定的值。
 */
export class CYLAnimatedItemBuiltInColor {
  resource: string = '';
  color: string = '';
}

/** [EN] iOS probe values (light | dark), "#AARRGGBB". [CN] iOS 实测值（浅色 | 深色）。 */
export const CYL_BUILTIN_LABEL_LIGHT: string = '#FF000000';
export const CYL_BUILTIN_LABEL_DARK: string = '#FFFFFFFF';
/** [EN] The system blue the UITabBar selected item has (the inherited tint). [CN] UITabBar 选中项的系统蓝（继承的 tint）。 */
export const CYL_BUILTIN_SELECTED_LIGHT: string = '#FF0088FF';
export const CYL_BUILTIN_SELECTED_DARK: string = '#FF0091FF';
/** [EN] UIButton(.system) disabled title: 134,134,134 at 0.45 | 140,140,140 at 0.35. [CN] UIButton(.system) 禁用标题。 */
export const CYL_BUILTIN_DISABLED_LIGHT: string = '#73868686';
export const CYL_BUILTIN_DISABLED_DARK: string = '#598C8C8C';
/** [EN] secondaryLabel: 60,60,67 at 0.60 | 235,235,245 at 0.60, the default divider color. [CN] secondaryLabel，分隔线的默认颜色。 */
export const CYL_BUILTIN_DIVIDER_LIGHT: string = '#993C3C43';
export const CYL_BUILTIN_DIVIDER_DARK: string = '#99EBEBF5';

/**
 * [EN] The built-in color of a role: 'normal' (icon + title: label color, `sys.color.font_primary`), 'selected' (the inherited tint:
 *      `sys.color.interactive_active`; a host's tint is the explicit stack / item value, there is no tint chain on HarmonyOS), 'disabled'
 *      (no SDK color: the iOS UIButton disabled constants), 'divider' (secondary label: `sys.color.font_secondary`). Evaluated at resolve
 *      time with the item's own mode, never stored. Pure.
 * [CN] 角色的内置颜色：'normal'（图标 + 标题：标签色，`sys.color.font_primary`）、'selected'（继承的 tint：`sys.color.interactive_active`；宿主的 tint 是显式的
 *      堆叠 / 条目值，HarmonyOS 没有 tint 链）、'disabled'（SDK 无对应颜色：iOS UIButton 禁用常量）、'divider'（次级标签色：`sys.color.font_secondary`）。
 *      在解析时按条目自己的模式求值，从不存储。纯逻辑。
 */
export function cylAnimatedItemBuiltInColor(role: string, dark: boolean): CYLAnimatedItemBuiltInColor {
  const result = new CYLAnimatedItemBuiltInColor();
  if (role === 'selected') {
    result.resource = 'interactive_active';
    result.color = dark ? CYL_BUILTIN_SELECTED_DARK : CYL_BUILTIN_SELECTED_LIGHT;
  } else if (role === 'disabled') {
    result.color = dark ? CYL_BUILTIN_DISABLED_DARK : CYL_BUILTIN_DISABLED_LIGHT;
  } else if (role === 'divider') {
    result.resource = 'font_secondary';
    result.color = dark ? CYL_BUILTIN_DIVIDER_DARK : CYL_BUILTIN_DIVIDER_LIGHT;
  } else {
    result.resource = 'font_primary';
    result.color = dark ? CYL_BUILTIN_LABEL_DARK : CYL_BUILTIN_LABEL_LIGHT;
  }
  return result;
}

/** [EN] Colors per state, '' = not set (an item's, or a stack's). [CN] 各状态的颜色，'' 表示未设置（条目的或堆叠的）。 */
export class CYLAnimatedItemStateColors {
  normal: string = '';
  selected: string = '';
  disabled: string = '';
}

/**
 * [EN] What a state color resolution looks at (`cylAnimatedItemResolveStateColor`): the item's and the stack's explicit values, the state.
 * [CN] 状态颜色解析的输入：条目与堆叠的显式值，以及状态。
 */
export class CYLAnimatedItemStateColorInput {
  item: CYLAnimatedItemStateColors = new CYLAnimatedItemStateColors();
  stack: CYLAnimatedItemStateColors = new CYLAnimatedItemStateColors();
  selected: boolean = false;
  enabled: boolean = true;
  dark: boolean = false;
}

/**
 * [EN] Where the EXPLICIT color of the current state comes from: 'item' (the item's value of the state is set), else 'stack', else 'builtIn'
 *      (neither set). A disabled item uses the disabled property, a selected one the selected property, else the normal one; each property on
 *      its own (a selected item whose host set only the normal color has NO explicit selected color: it gets the built-in selected one). The
 *      view uses it to pick its own `ResourceColor` (a resource color has no text). Pure.
 * [CN] 当前状态的显式颜色来自哪里：'item'（条目该状态的值已设置），否则 'stack'，否则 'builtIn'（都未设置）。禁用的条目用 disabled 属性，选中的用 selected 属性，否则用
 *      normal；各属性互相独立（宿主只设置了普通颜色的选中条目没有显式选中色：使用内置选中色）。视图据此选取自己的 `ResourceColor`（资源颜色没有文本）。纯逻辑。
 */
export function cylAnimatedItemStateColorSource(input: CYLAnimatedItemStateColorInput): string {
  const pick = (colors: CYLAnimatedItemStateColors): string =>
    !input.enabled ? colors.disabled : (input.selected ? colors.selected : colors.normal);
  if (pick(input.item).trim() !== '') {
    return 'item';
  }
  return pick(input.stack).trim() !== '' ? 'stack' : 'builtIn';
}

/** [EN] The EXPLICIT color of the current state as text: the item's, else the stack's, else ''. [CN] 当前状态的显式颜色（文本）：条目的，否则堆叠的，否则 ''。 */
export function cylAnimatedItemExplicitStateColor(input: CYLAnimatedItemStateColorInput): string {
  const pick = (colors: CYLAnimatedItemStateColors): string =>
    !input.enabled ? colors.disabled : (input.selected ? colors.selected : colors.normal);
  const source = cylAnimatedItemStateColorSource(input);
  return source === 'item' ? pick(input.item) : (source === 'stack' ? pick(input.stack) : '');
}

/**
 * [EN] The outcome of the EFFECTIVE color: `explicit` the host's text ('' when built-in), `builtIn` the built-in of the state (always filled).
 * [CN] 生效颜色的结果：`explicit` 为宿主设置的文本（内置时为 ''），`builtIn` 为该状态的内置颜色（始终有值）。
 */
export class CYLAnimatedItemStateColorResult {
  explicit: string = '';
  builtIn: CYLAnimatedItemBuiltInColor = new CYLAnimatedItemBuiltInColor();
}

/** [EN] The EFFECTIVE color of the current state: explicit (item, then stack), else the built-in of the state. [CN] 当前状态生效的颜色：显式（条目、堆叠），否则该状态的内置色。 */
export function cylAnimatedItemResolveStateColor(input: CYLAnimatedItemStateColorInput): CYLAnimatedItemStateColorResult {
  const result = new CYLAnimatedItemStateColorResult();
  result.explicit = cylAnimatedItemExplicitStateColor(input);
  result.builtIn = cylAnimatedItemBuiltInColor(!input.enabled ? 'disabled' : (input.selected ? 'selected' : 'normal'), input.dark);
  return result;
}

/**
 * [EN] What the divider color resolution looks at (see `cylAnimatedItemDividerColor`). Colors are '' when not set; they are ArkUI color
 *      texts ('#RRGGBB' / '#AARRGGBB'). `iconColor` is the EXPLICIT normal-state icon color (the item's, else the stack's; no built-in).
 * [CN] 分隔线颜色解析的输入（见 `cylAnimatedItemDividerColor`）。未设置的颜色为 ''；均为 ArkUI 颜色文本。`iconColor` 是显式的普通状态图标颜色（条目的，否则堆叠的；不含内置色）。
 */
export class CYLAnimatedItemDividerInput {
  dividerColor: string = '';
  iconColor: string = '';
  dark: boolean = false;
}

/**
 * [EN] The outcome: `source` 'divider' | 'icon' | 'builtin', the `color` text to draw (for 'builtin' the constant of the mode, and
 *      `resource` the `sys.color.` name the view draws instead) and the `opacity` to draw it with (1, except for an icon color that is
 *      not a hex text: the text as it is with opacity 0.6).
 * [CN] 结果：`source` 为 'divider' | 'icon' | 'builtin'，绘制用的 `color` 文本（'builtin' 时为该模式的常量，视图改用 `resource` 指向的 `sys.color.` 名称）
 *      与 `opacity`（均为 1，图标颜色不是十六进制文本时除外：原文本加透明度 0.6）。
 */
export class CYLAnimatedItemDividerResult {
  source: string = 'builtin';
  color: string = '';
  resource: string = '';
  opacity: number = 1;
}

/**
 * [EN] The divider line color: `dividerColor` as it is when set; else an EXPLICIT icon color at alpha 0.6 (the alpha REPLACES the color's own,
 *      as iOS `withAlphaComponent`); else the built-in divider color (secondary label, >= 3:1 on light and dark bars). Pure, unit tested with
 *      Node (table driven, with contrast rows).
 * [CN] 分隔线颜色：设置了 `dividerColor` 时原样使用；否则为透明度 0.6 的显式图标颜色（透明度替换颜色自带的，同 iOS `withAlphaComponent`）；否则为内置分隔色
 *      （次级标签色，在浅色与深色栏上对比度 >= 3:1）。纯逻辑，用 Node 做表驱动单元测试（含对比度）。
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
  const builtIn = cylAnimatedItemBuiltInColor('divider', input.dark);
  result.color = builtIn.color;
  result.resource = builtIn.resource;
  return result;
}

/**
 * [EN] The WCAG contrast ratio of a color ("#AARRGGBB" / "#RRGGBB", drawn over an opaque background "#RRGGBB") against that background. Pure,
 *      used by the contrast tests (3:1 for the divider).
 * [CN] 颜色（"#AARRGGBB" / "#RRGGBB"，绘制在不透明背景 "#RRGGBB" 上）相对该背景的 WCAG 对比度。纯逻辑，供对比度测试使用（分隔线 3:1）。
 */
export function cylAnimatedItemContrast(foreground: string, background: string): number {
  const fg = cylAnimatedItemParseHexColor(foreground);
  const bg = cylAnimatedItemParseHexColor(background);
  if (fg === undefined || bg === undefined) {
    return 0;
  }
  const a = fg.alpha / 255;
  const mix = (f: number, b: number): number => f * a + b * (1 - a);
  const linear = (v: number): number => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  };
  const luminance = (r: number, g: number, b: number): number => 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
  const lf = luminance(mix(fg.red, bg.red), mix(fg.green, bg.green), mix(fg.blue, bg.blue));
  const lb = luminance(bg.red, bg.green, bg.blue);
  return (Math.max(lf, lb) + 0.05) / (Math.min(lf, lb) + 0.05);
}
