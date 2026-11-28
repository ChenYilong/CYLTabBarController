import { i18n } from '@kit.LocalizationKit';
import { CYL_LOCALIZATION_KEYS } from './CYLLocalizationTable';

/**
 * [EN] Localization of the HarmonyOS library and example (CYLLocalization.h): the key is the original text, as on iOS
 *      (`CYLLocalizedString(@"<original Chinese text>")`), and the translations are copied from the iOS bundle
 *      (CYLTabBarController.bundle/<lang>.lproj/CYLTabBarController.strings) by scripts/harmonyos-l10n.py into the string
 *      resources of this module, one folder per language. A key without a translation shows the key.
 * [CN] 鸿蒙库与示例的本地化（CYLLocalization.h）：key 即原文，与 iOS 相同；译文由 scripts/harmonyos-l10n.py 从 iOS 资源包复制到本模块的字符串资源，
 *      每种语言一个目录。没有译文的 key 显示 key 本身。
 */
let cylLocalizationContext: Context | undefined = undefined;

/**
 * [EN] Gives the localization the app's context (call it in UIAbility.onCreate). [CN] 设置本地化使用的应用 context（在 UIAbility.onCreate 中调用）。
 */
export function cyl_setLocalizationContext(context: Context): void {
  cylLocalizationContext = context;
}

/**
 * [EN] Marks a localization key that is looked up later (scripts/harmonyos-l10n.py collects it); returns the key.
 * [CN] 标记稍后查找的本地化 key（脚本会收集它）；返回 key 本身。
 */
export function cyl_localizationKey(key: string): string {
  return key;
}

/**
 * [EN] CYLLocalizedString: the text of `key` in the app's language, with %@, %1$@ ... and %ld replaced by `args`.
 * [CN] key 在应用语言下的文字，%@、%1$@ 等与 %ld 依次替换为 args。
 */
export function CYLLocalizedString(key: string, ...args: (string | number)[]): string {
  let text = key;
  const name = CYL_LOCALIZATION_KEYS.get(key);
  if (name !== undefined) {
    try {
      const context = cylLocalizationContext ?? getContext();
      text = context.resourceManager.getStringByNameSync(name);
    } catch (e) {
      text = key;
    }
  }
  let next = 0;
  return text.replace(/%(\d+\$)?(@|ld|d|s)/g, (match: string, position: string | undefined) => {
    const index = position !== undefined ? Number.parseInt(position, 10) - 1 : next++;
    return index < args.length ? `${args[index]}` : match;
  });
}

/**
 * [EN] The text of a ResourceStr (a string, or a $r string resource) in the app's language, for accessibility labels.
 * [CN] ResourceStr（字符串或 $r 字符串资源）在应用语言下的文字，用于无障碍标签。
 */
export function cyl_textOf(value: ResourceStr | undefined): string {
  if (value === undefined) {
    return '';
  }
  if (typeof value === 'string') {
    return value;
  }
  try {
    const context = cylLocalizationContext ?? getContext();
    return context.resourceManager.getStringSync(value as Resource);
  } catch (e) {
    return '';
  }
}

/** [EN] CYLLocalizationLanguageDidChangeNotification observers. [CN] 语言变化的监听者。 */
let cylLanguageListeners: ((language: string) => void)[] = [];

/**
 * [EN] CYLLocalizationLanguageDidChangeNotification: called after CYLSetLocalizationLanguage. [CN] CYLSetLocalizationLanguage 之后调用。
 */
export function cyl_addLocalizationLanguageListener(listener: (language: string) => void): void {
  cylLanguageListeners.push(listener);
}

export function cyl_removeLocalizationLanguageListener(listener: (language: string) => void): void {
  cylLanguageListeners = cylLanguageListeners.filter((item: (language: string) => void) => item !== listener);
}

/**
 * [EN] CYLLocalizationLanguage(): the app's language ('' follows the system). [CN] 应用语言（'' 表示跟随系统）。
 */
export function CYLLocalizationLanguage(): string {
  const language = i18n.System.getAppPreferredLanguage();
  return language === 'default' ? '' : language;
}

/**
 * [EN] CYLSetLocalizationLanguage(): sets the app's language ('' follows the system); resources ($r and
 *      CYLLocalizedString) switch at once, then the listeners are told.
 * [CN] 设置应用语言（'' 跟随系统）；资源立即切换，然后通知监听者。
 */
export function CYLSetLocalizationLanguage(language: string): void {
  i18n.System.setAppPreferredLanguage(language.length === 0 ? 'default' : language);
  cylLanguageListeners.slice().forEach((listener: (language: string) => void) => listener(language));
}

/**
 * [EN] +cyl_pickerLanguages: the languages of the language picker ('' follows the system), those of the iOS bundle.
 * [CN] 语言选择器的语言（'' 跟随系统），与 iOS 资源包相同。
 */
export function cyl_pickerLanguages(): string[] {
  return ['', 'en-Latn-US', 'zh-Hans-CN', 'zh-Hant-TW', 'ar', 'ca', 'cs', 'da', 'de', 'el', 'es', 'fi', 'fr', 'he', 'hi',
    'hr', 'hu', 'id', 'it', 'ja', 'ko', 'ms', 'nb', 'nl', 'pl', 'pt-BR', 'ro', 'ru', 'sk', 'sv', 'th', 'tr', 'uk', 'vi'];
}
