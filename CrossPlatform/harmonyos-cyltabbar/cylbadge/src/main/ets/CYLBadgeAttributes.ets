import { CYLBadge, CYLBadgeAnimationType } from './CYLBadge';

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

/**
 * [EN] The animation named in `attributes` (a name in any letter case, or 0...9); `None` for anything else.
 * [CN] `attributes` 中指定的动画（任意大小写的名称，或 0...9）；其他情况为 `None`。
 */
export function cylBadgeAnimationType(attributes: Record<string, Object> | undefined): CYLBadgeAnimationType {
  const value: Object | undefined = attributes ? attributes[CYLBadgeAttributeKey.animation] : undefined;
  if (typeof value === 'number' && Number.isInteger(value) && value >= 0 && value < CYL_BADGE_ANIMATION_NAMES.length) {
    return value as CYLBadgeAnimationType;
  }
  if (typeof value === 'string') {
    const index = CYL_BADGE_ANIMATION_NAMES.indexOf(value.trim().toLowerCase());
    if (index >= 0) {
      return index as CYLBadgeAnimationType;
    }
  }
  return CYLBadgeAnimationType.None;
}

/**
 * [EN] Applies the style keys of `attributes` to `badge`. The value and the animation are not applied here: the caller shows the badge.
 * [CN] 把 `attributes` 中的样式键应用到 `badge`。值与动画不在这里应用：由调用方显示角标。
 */
export function cylApplyBadgeAttributes(badge: CYLBadge, attributes: Record<string, Object> | undefined): void {
  if (!attributes) {
    return;
  }
  const color = cylBadgeColor(attributes[CYLBadgeAttributeKey.color]);
  if (color !== undefined) {
    badge.backgroundColor = color;
  }
  const textColor = cylBadgeColor(attributes[CYLBadgeAttributeKey.textColor]);
  if (textColor !== undefined) {
    badge.textColor = textColor;
  }
  const borderColor = cylBadgeColor(attributes[CYLBadgeAttributeKey.borderColor]);
  if (borderColor !== undefined) {
    badge.borderColor = borderColor;
  }
  const fontSize = cylBadgeNumber(attributes[CYLBadgeAttributeKey.font]);
  if (fontSize !== undefined && fontSize > 0) {
    badge.fontSize = fontSize;
  }
  const radius = cylBadgeNumber(attributes[CYLBadgeAttributeKey.radius]);
  if (radius !== undefined) {
    badge.radius = radius;
  }
  const borderWidth = cylBadgeNumber(attributes[CYLBadgeAttributeKey.borderWidth]);
  if (borderWidth !== undefined) {
    badge.borderWidth = borderWidth;
  }
  const maximum = cylBadgeNumber(attributes[CYLBadgeAttributeKey.maximumNumber]);
  if (maximum !== undefined) {
    badge.maximumBadgeNumber = maximum;
  }
  const offset = cylBadgeOffset(attributes[CYLBadgeAttributeKey.centerOffset]);
  if (offset !== undefined) {
    badge.centerOffset = { horizontal: offset[0], vertical: offset[1] };
  }
  const respects: Object | undefined = attributes[CYLBadgeAttributeKey.respectsReduceMotion];
  if (typeof respects === 'boolean') {
    badge.respectsReduceMotion = respects;
  }
}

/**
 * [EN] The localized description of a badge value (TalkBack-like: "New content" for a dot, "N new messages" for a number). `cylbadge` has no string
 *      table of its own (the strings are cyltabbar's `CYLLocalization`), so a host that localizes installs `CYLBadgeAccessibility.textProvider`
 *      once (`cyltabbar` does when it loads); without one the badge text itself is read and a dot adds nothing.
 * [CN] 角标值的本地化描述（类似 TalkBack：红点为 "有新内容"，数字为 "N 条新消息"）。`cylbadge` 没有自己的字符串表（字符串是 cyltabbar 的
 *      `CYLLocalization`），因此做本地化的宿主只需安装一次 `CYLBadgeAccessibility.textProvider`（`cyltabbar` 加载时会安装）；没有时朗读角标文字本身，红点不追加内容。
 */
export class CYLBadgeAccessibility {
  /** `text` is null for a dot, otherwise the badge's display text; returns the description. */
  static textProvider?: (text: string | null) => string;
}

/**
 * [EN] What a screen reader says for `badge` (read as part of its host); '' when no badge is shown.
 * [CN] 屏幕阅读器为 `badge` 读出的内容（作为宿主的一部分读出）；没有角标时为 ''。
 */
export function cylBadgeAccessibilityText(badge: CYLBadge | undefined): string {
  if (badge === undefined || !badge.isShowBadge()) {
    return '';
  }
  const text: string | null = badge.displayText();
  const provider = CYLBadgeAccessibility.textProvider;
  if (provider !== undefined) {
    return provider(text);
  }
  return text === null ? '' : text;
}
