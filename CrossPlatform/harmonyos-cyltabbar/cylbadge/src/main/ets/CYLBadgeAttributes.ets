import { CYLBadge, CYLBadgeAnimationType } from './CYLBadge';
import { cylBadgeAnimationIndex, cylParseBadgeAttributes } from './CYLBadgeAttributeParser';

export { CYLBadgeAttributeKey } from './CYLBadgeAttributeParser';

/**
 * [EN] The animation named in `attributes` (a name in any letter case, or 0...9); `None` for anything else.
 * [CN] `attributes` 中指定的动画（任意大小写的名称，或 0...9）；其他情况为 `None`。
 */
export function cylBadgeAnimationType(attributes: Record<string, Object> | undefined): CYLBadgeAnimationType {
  return cylBadgeAnimationIndex(attributes) as CYLBadgeAnimationType;
}

/**
 * [EN] Applies the style keys of `attributes` to `badge`. The value and the animation are not applied here: the caller shows the badge.
 * [CN] 把 `attributes` 中的样式键应用到 `badge`。值与动画不在这里应用：由调用方显示角标。
 */
export function cylApplyBadgeAttributes(badge: CYLBadge, attributes: Record<string, Object> | undefined): void {
  const parsed = cylParseBadgeAttributes(attributes);
  if (parsed.color !== undefined) {
    badge.backgroundColor = parsed.color;
  }
  if (parsed.textColor !== undefined) {
    badge.textColor = parsed.textColor;
  }
  if (parsed.borderColor !== undefined) {
    badge.borderColor = parsed.borderColor;
  }
  if (parsed.fontSize !== undefined) {
    badge.fontSize = parsed.fontSize;
  }
  if (parsed.radius !== undefined) {
    badge.radius = parsed.radius;
  }
  if (parsed.borderWidth !== undefined) {
    badge.borderWidth = parsed.borderWidth;
  }
  if (parsed.maximumNumber !== undefined) {
    badge.maximumBadgeNumber = parsed.maximumNumber;
  }
  if (parsed.centerOffsetX !== undefined && parsed.centerOffsetY !== undefined) {
    badge.centerOffset = { horizontal: parsed.centerOffsetX, vertical: parsed.centerOffsetY };
  }
  if (parsed.respectsReduceMotion !== undefined) {
    badge.respectsReduceMotion = parsed.respectsReduceMotion;
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
