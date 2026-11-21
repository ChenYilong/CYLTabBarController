// The language switch of the Objective-C example (CYLLocalization.h): the picker's five languages, the texts in the
// chosen language, and right to left for Arabic. The translations are the library's string tables, copied into
// assets/demo/strings.json by scripts/sync-example-shared.py (English text -> translation, per language).
// Objective-C 示例的语言切换（CYLLocalization.h）：选择器中的五种语言、所选语言的文字，以及阿拉伯语的从右到左布局。译文来自库的字符串表，
// 由 scripts/sync-example-shared.py 复制到 assets/demo/strings.json（每种语言：英文 -> 译文）。
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;

/// +[UIViewController cyl_pickerLanguages]: the five most spoken languages. 使用人数最多的五种语言。
const cylPickerLanguages = ['en', 'zh-Hans', 'hi', 'es', 'ar'];

const _flags = {
  'en': '🇺🇸',
  'zh-Hans': '🇨🇳',
  'hi': '🇮🇳',
  'es': '🇪🇸',
  'ar': '🇸🇦',
};

/// Each language's name in that language (CYLLocalizationNativeName). 每种语言以其自身书写的名称。
const _nativeNames = {
  'en': 'English',
  'zh-Hans': '中文',
  'hi': 'हिन्दी',
  'es': 'Español',
  'ar': 'العربية',
};
const _rightToLeft = ['ar', 'he', 'fa', 'ur'];

/// The translations and the current language, as CYLSetLocalizationLanguage() / CYLLocalizedString().
/// 译文与当前语言，对应 CYLSetLocalizationLanguage() / CYLLocalizedString()。
class CYLLocalization {
  CYLLocalization._();

  static Map<String, Map<String, String>> _tables = const {};
  static String _current = 'en';

  /// Loads strings.json; call once before runApp. 加载 strings.json；在 runApp 之前调用一次。
  static Future<void> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/demo/strings.json'),
    ) as Map<String, dynamic>;
    _tables = {
      for (final entry in json.entries)
        entry.key: (entry.value as Map<String, dynamic>).cast<String, String>(),
    };
    _current = deviceLanguage;
  }

  /// The table closest to a language tag such as "zh-Hant-TW" or "pt-PT"; English when none. 与语言标签最接近的表；没有时为英语。
  static String closest(String tag) {
    final parts = tag.replaceAll('_', '-').split('-');
    final language =
        const {'iw': 'he', 'in': 'id', 'no': 'nb'}[parts.first] ?? parts.first;
    if (language == 'zh') {
      return parts.any(const ['Hant', 'TW', 'HK', 'MO'].contains)
          ? 'zh-Hant'
          : 'zh-Hans';
    }
    if (language == 'pt') return 'pt-BR';
    if (language == 'en' || _tables.containsKey(language)) return language;
    return 'en';
  }

  /// The device language, as a table. 设备语言对应的表。
  static String get deviceLanguage =>
      closest(PlatformDispatcher.instance.locale.toLanguageTag());

  /// CYLSetLocalizationLanguage(): null follows the device. null 时跟随设备。
  static set language(String? language) =>
      _current = language ?? deviceLanguage;

  /// CYLLocalizationLanguage().
  static String get language => _current;

  static bool isRightToLeft(String language) =>
      _rightToLeft.contains(language.split('-').first);

  /// "{name}" parts filled in. 填入「{name}」部分。
  static String fill(String text, Map<String, String> values) =>
      text.replaceAllMapped(
        RegExp(r'\{(\w+)\}'),
        (match) => values[match[1]] ?? '-',
      );

  /// CYLLocalizedStringForLanguage(text, nil): always in the device language. 始终使用设备语言。
  static String device(String text) => _tables[deviceLanguage]?[text] ?? text;

  /// CYLLocalizationNativeName(): read by VoiceOver / TalkBack instead of the flag. 读屏软件朗读它而不是国旗。
  static String name(String language) => _nativeNames[language] ?? language;

  /// CYLLocalizationFlaggedName(): "🇪🇸 Español".
  static String flaggedName(String language) =>
      '${_flags[language] ?? '🌐'} ${name(language)}';
}

/// CYLLocalizedString(): an English text in the current language, its "{name}" parts filled in. 当前语言中的英文文字，并填入「{name}」部分。
String t(String text, [Map<String, String>? values]) {
  final translated =
      CYLLocalization._tables[CYLLocalization._current]?[text] ?? text;
  return values == null ? translated : CYLLocalization.fill(translated, values);
}
