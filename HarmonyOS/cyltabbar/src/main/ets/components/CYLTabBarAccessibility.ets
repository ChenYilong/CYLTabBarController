import { common } from '@kit.AbilityKit';

/**
 * [EN] The string resource `id` of this module in the language of the device, formatted with `args` ("%s"); "" when the
 *      resource cannot be read.
 * [CN] 本模块字符串资源 `id` 的设备语言文本，用 `args` 格式化（"%s"）；无法读取资源时为 ""。
 */
export function cylLocalizedString(context: common.Context, id: number, ...args: Array<string | number>): string {
  try {
    return context.resourceManager.getStringSync(id, ...args);
  } catch (error) {
    return '';
  }
}

/**
 * [EN] A string resource or a text as a text, in the language of the device. [CN] 把字符串资源或文本转换为设备语言的文本。
 */
export function cylResolveText(context: common.Context, text?: ResourceStr): string {
  if (text === undefined) {
    return '';
  }
  if (typeof text === 'string') {
    return text;
  }
  return cylLocalizedString(context, text.id);
}

/**
 * [EN] What the screen reader reads for a badge value, as iOS `CYLBadgeAccessibilityDescription()`: "New content" for a red
 *      dot (""), "3 new messages" for a number, the localized text otherwise ("NEW"); undefined for no badge or zero.
 * [CN] 屏幕阅读器为角标值朗读的内容，对应 iOS 的 `CYLBadgeAccessibilityDescription()`：红点（""）为“有新内容”，数字为“3 条新消息”，
 *      其他为本地化文本（"NEW"）；没有角标或为 0 时为 undefined。
 */
export function cylBadgeAccessibilityDescription(context: common.Context, value?: string): string | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (value.length === 0) {
    return cylLocalizedString(context, $r('app.string.cyl_badge_new_content').id);
  }
  if (/^[0-9]+\+?$/.test(value)) {
    return parseInt(value) > 0 ? cylLocalizedString(context, $r('app.string.cyl_badge_new_messages').id, value) : undefined;
  }
  switch (value) {
    case 'NEW':
      return cylLocalizedString(context, $r('app.string.cyl_badge_text_NEW').id);
    case 'New':
      return cylLocalizedString(context, $r('app.string.cyl_badge_text_New').id);
    case 'new':
      return cylLocalizedString(context, $r('app.string.cyl_badge_text_new').id);
    default:
      return value;
  }
}

/**
 * [EN] The parts joined with the localized list separator ("Messages, 3 new messages"; Chinese "消息、3 条新消息").
 * [CN] 用本地化的列表分隔符连接各部分（“Messages, 3 new messages”；中文为“消息、3 条新消息”）。
 */
export function cylJoinAccessibilityParts(context: common.Context, parts: Array<string | undefined>): string {
  const separator = cylLocalizedString(context, $r('app.string.cyl_list_separator').id);
  return parts.filter((part: string | undefined) => part !== undefined && part.length > 0).join(separator);
}

/**
 * [EN] The localized "Plus button". [CN] 本地化的“加号按钮”。
 */
export function cylPlusButtonDefaultAccessibilityLabel(context: common.Context): string {
  return cylLocalizedString(context, $r('app.string.cyl_plus_button').id);
}
