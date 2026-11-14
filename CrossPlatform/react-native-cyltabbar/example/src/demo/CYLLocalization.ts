/**
 * The language switch of the Objective-C example (CYLLocalization.h): the picker's five languages, the texts in the
 * chosen language, and right to left for Arabic. The translations are the library's string tables, copied into
 * strings.json by scripts/sync-example-shared.py (English text -> translation, per language).
 * Objective-C 示例的语言切换（CYLLocalization.h）：选择器中的五种语言、所选语言的文字，以及阿拉伯语的从右到左布局。译文来自库的字符串表，
 * 由 scripts/sync-example-shared.py 复制到 strings.json（每种语言：英文 -> 译文）。
 */
const TABLES = require('./strings.json') as Record<string, Record<string, string>>;

/** +[UIViewController cyl_pickerLanguages]: the five most spoken languages. 使用人数最多的五种语言。 */
export const CYL_PICKER_LANGUAGES = ['en', 'zh-Hans', 'hi', 'es', 'ar'];

const FLAGS: Record<string, string> = { 'en': '🇺🇸', 'zh-Hans': '🇨🇳', 'hi': '🇮🇳', 'es': '🇪🇸', 'ar': '🇸🇦' };
/** Each language's name in that language (CYLLocalizationNativeName). 每种语言以其自身书写的名称。 */
const NATIVE_NAMES: Record<string, string> = { 'en': 'English', 'zh-Hans': '中文', 'hi': 'हिन्दी', 'es': 'Español', 'ar': 'العربية' };
const RIGHT_TO_LEFT = new Set(['ar', 'he', 'fa', 'ur']);

/** The table closest to a language tag such as "zh-Hant-TW" or "pt-PT"; English when none. 与语言标签最接近的表；没有时为英语。 */
export function CYLClosestLanguage(tag: string): string {
  const parts = tag.replace('_', '-').split('-');
  const language = { iw: 'he', in: 'id', no: 'nb' }[parts[0]!] ?? parts[0]!;
  if (language === 'zh') {
    return parts.some((part) => ['Hant', 'TW', 'HK', 'MO'].includes(part)) ? 'zh-Hant' : 'zh-Hans';
  }
  if (language === 'pt') return 'pt-BR';
  if (language === 'en' || TABLES[language]) return language;
  return 'en';
}

/** The device language, as a table. 设备语言对应的表。 */
export function CYLDeviceLanguage(): string {
  return CYLClosestLanguage(Intl.DateTimeFormat().resolvedOptions().locale);
}

let current = CYLDeviceLanguage();

/** CYLSetLocalizationLanguage(): undefined follows the device. 未指定时跟随设备。 */
export function CYLSetDemoLanguage(language: string | undefined) {
  current = language ?? CYLDeviceLanguage();
}

/** CYLLocalizationLanguage(). */
export function CYLDemoLanguage(): string {
  return current;
}

export function CYLIsRightToLeft(language: string): boolean {
  return RIGHT_TO_LEFT.has(language.split('-')[0]!);
}

/** "{name}" parts filled in. 填入「{name}」部分。 */
export function CYLFill(text: string, values: Record<string, string>): string {
  return text.replace(/\{(\w+)\}/g, (_, name: string) => values[name] ?? '-');
}

/** CYLLocalizedString(): an English text in the current language, its "{name}" parts filled in. 当前语言中的英文文字，并填入「{name}」部分。 */
export function t(text: string, values?: Record<string, string>): string {
  const translated = TABLES[current]?.[text] ?? text;
  return values ? CYLFill(translated, values) : translated;
}

/** CYLLocalizedStringForLanguage(text, nil): always in the device language. 始终使用设备语言。 */
export function tDevice(text: string): string {
  return TABLES[CYLDeviceLanguage()]?.[text] ?? text;
}

/** CYLLocalizationNativeName(): read by VoiceOver / TalkBack instead of the flag. 读屏软件朗读它而不是国旗。 */
export function CYLLanguageName(language: string): string {
  return NATIVE_NAMES[language] ?? language;
}

/** CYLLocalizationFlaggedName(): "🇪🇸 Español". */
export function CYLFlaggedLanguageName(language: string): string {
  return `${FLAGS[language] ?? '🌐'} ${CYLLanguageName(language)}`;
}
