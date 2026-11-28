// [EN] The pure part of the badge style parser (no ArkUI import, so `node --test` runs it): the keys of iOS' `CYLBadgeAttributeKey`, and one function that reads a
//      style record into plain numbers and strings. `CYLBadgeAttributes.ets` applies the result to a `CYLBadge`.
// [CN] 角标样式解析的纯逻辑部分（不导入 ArkUI，因此 `node --test` 能运行）：iOS `CYLBadgeAttributeKey` 的键，以及把样式 Record 读成纯数字与字符串的函数。
//      `CYLBadgeAttributes.ets` 把结果应用到 `CYLBadge`。

/**
 * [EN] The keys of a badge style record: the same strings as iOS' `CYLBadgeAttributeKey` and the host view's `badgeAttributes`
 *      (docs/Animated-Item-Badge-CrossPlatform.md, HarmonyOS phase 2). Values are numbers or strings (`#RRGGBB` / `#RRGGBBAA`
 *      colors, `{x, y}` offsets, numeric strings); null and unknown types are ignored, never a crash. One parser,
 *      `cylApplyBadgeAttributes`, serves animated items, the tab bar and configuration files. Written statically, not built in DevEco yet.
 * [CN] 角标样式 Record 的键：与 iOS 的 `CYLBadgeAttributeKey` 和宿主视图的 `badgeAttributes` 相同的字符串（docs/Animated-Item-Badge-CrossPlatform.md，鸿蒙阶段 2）。
 *      值为数字或字符串（`#RRGGBB` / `#RRGGBBAA` 颜色、`{x, y}` 偏移、数字字符串）；null 与未知类型被忽略，不会崩溃。一个解析函数
 *      `cylApplyBadgeAttributes` 同时服务动效 item、TabBar 与配置文件。静态编写，尚未在 DevEco 中构建。
 */
export class CYLBadgeAttributeKey {
  static readonly value: string = 'value';
  static readonly color: string = 'color';
  static readonly animation: string = 'animation';
  static readonly radius: string = 'radius';
  static readonly centerOffset: string = 'centerOffset';
  static readonly textColor: string = 'textColor';
  static readonly font: string = 'font';
  static readonly borderColor: string = 'borderColor';
  static readonly borderWidth: string = 'borderWidth';
  static readonly maximumNumber: string = 'maximumNumber';
  static readonly respectsReduceMotion: string = 'respectsReduceMotion';
}

const CYL_BADGE_ANIMATION_NAMES: string[] = ['none', 'scale', 'shake', 'bounce', 'breathe', 'leftrightonce', 'rightleftonce', 'fadeinonce', 'rollingonce', 'scaleonce'];

function cylBadgeNumber(value: Object | undefined): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function cylBadgeColor(value: Object | undefined): string | undefined {
  // [EN] `#RRGGBB` and `#RRGGBBAA` are what ArkUI's ResourceColor strings take, as iOS and the configuration files write them. [CN] ArkUI 的 ResourceColor 字符串接受 `#RRGGBB` 与 `#RRGGBBAA` 的写法。
  if (typeof value === 'string' && /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value.trim())) {
    return value.trim();
  }
  return undefined;
}

function cylBadgeOffset(value: Object | undefined): number[] | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }
  const match = /^\s*\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}\s*$/.exec(value);
  return match ? [Number(match[1]), Number(match[2])] : undefined;
}


/** [EN] What a style record says, as plain values; a field is undefined when the key is absent or unreadable. [CN] 样式 Record 所表达的内容，纯值；键缺失或无法读取时字段为 undefined。 */
export interface CYLParsedBadgeAttributes {
  color?: string;
  textColor?: string;
  borderColor?: string;
  fontSize?: number;
  radius?: number;
  borderWidth?: number;
  maximumNumber?: number;
  centerOffsetX?: number;
  centerOffsetY?: number;
  respectsReduceMotion?: boolean;
  /** 0...9, the index of `CYLBadgeAnimationType`; 0 (none) when the key is absent or unknown. */
  animationIndex: number;
}

/**
 * [EN] The animation index named in `attributes` (a name in any letter case, or 0...9); 0 (none) for anything else.
 * [CN] `attributes` 中指定的动画序号（任意大小写的名称，或 0...9）；其他情况为 0（无）。
 */
export function cylBadgeAnimationIndex(attributes: Record<string, Object> | undefined): number {
  const value: Object | undefined = attributes ? attributes[CYLBadgeAttributeKey.animation] : undefined;
  if (typeof value === 'number' && Number.isInteger(value) && value >= 0 && value < CYL_BADGE_ANIMATION_NAMES.length) {
    return value;
  }
  if (typeof value === 'string') {
    const index = CYL_BADGE_ANIMATION_NAMES.indexOf(value.trim().toLowerCase());
    if (index >= 0) {
      return index;
    }
  }
  return 0;
}

/**
 * [EN] Reads `attributes` into plain values: null, unknown keys and unknown types are ignored, never a throw.
 * [CN] 把 `attributes` 读成纯值：null、未知键与未知类型被忽略，不会抛出异常。
 */
export function cylParseBadgeAttributes(attributes: Record<string, Object> | undefined): CYLParsedBadgeAttributes {
  const parsed: CYLParsedBadgeAttributes = { animationIndex: cylBadgeAnimationIndex(attributes) };
  if (!attributes) {
    return parsed;
  }
  parsed.color = cylBadgeColor(attributes[CYLBadgeAttributeKey.color]);
  parsed.textColor = cylBadgeColor(attributes[CYLBadgeAttributeKey.textColor]);
  parsed.borderColor = cylBadgeColor(attributes[CYLBadgeAttributeKey.borderColor]);
  const fontSize = cylBadgeNumber(attributes[CYLBadgeAttributeKey.font]);
  parsed.fontSize = fontSize !== undefined && fontSize > 0 ? fontSize : undefined;
  parsed.radius = cylBadgeNumber(attributes[CYLBadgeAttributeKey.radius]);
  parsed.borderWidth = cylBadgeNumber(attributes[CYLBadgeAttributeKey.borderWidth]);
  parsed.maximumNumber = cylBadgeNumber(attributes[CYLBadgeAttributeKey.maximumNumber]);
  const offset = cylBadgeOffset(attributes[CYLBadgeAttributeKey.centerOffset]);
  if (offset !== undefined) {
    parsed.centerOffsetX = offset[0];
    parsed.centerOffsetY = offset[1];
  }
  const respects: Object | undefined = attributes[CYLBadgeAttributeKey.respectsReduceMotion];
  parsed.respectsReduceMotion = typeof respects === 'boolean' ? respects : undefined;
  return parsed;
}
