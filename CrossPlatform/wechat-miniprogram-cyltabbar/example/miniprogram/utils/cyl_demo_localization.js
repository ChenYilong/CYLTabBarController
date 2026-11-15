/**
 * [EN] The example's localization: one function, t(), over the example's own tables (cyl_demo_strings.js, plus the
 *      languages of the Objective-C language picker made from the library's tables, shared/strings_more.js), and the
 *      configuration's table of the current language (shared/localization.js, the ConfigurationDemo tables of
 *      Example-Shared). The language follows WeChat, or the one chosen on Home (CYLSetLocalizationLanguage, not saved:
 *      a new launch follows WeChat again, as the Objective-C example). The component itself has no texts.
 * [CN] 示例的本地化：一个函数 t()，读取示例自己的表（cyl_demo_strings.js，以及由库的字符串表生成的 Objective-C 语言选择器中的
 *      语言，shared/strings_more.js）；另外提供当前语言的配置本地化表（shared/localization.js，即 Example-Shared 的
 *      ConfigurationDemo 表）。语言跟随微信，或使用首页选择的语言（CYLSetLocalizationLanguage，不保存：与 Objective-C 示例
 *      相同，重新启动后再次跟随微信）。组件本身没有文字。
 */
const cylDemoStrings = require('./cyl_demo_strings');
const cylMoreStrings = require('../shared/strings_more');
const cylConfigurationStrings = require('../shared/localization');

// [EN] The language chosen on Home, or null to follow WeChat. [CN] 首页选择的语言；null 表示跟随微信。
let cylChosenLanguage = null;

/**
 * [EN] CYLSetLocalizationLanguage: "en", "zh-Hans", "hi", "es", "ar", or null to follow WeChat.
 * [CN] CYLSetLocalizationLanguage："en"、"zh-Hans"、"hi"、"es"、"ar"，或 null 表示跟随微信。
 */
function cylSetLanguage(language) {
  cylChosenLanguage = language || null;
}

function cylChosen() {
  return cylChosenLanguage;
}

/**
 * [EN] The language folder name of WeChat's language ("zh_CN" -> "zh-Hans", "zh_TW" -> "zh-Hant", "pt_BR" -> "pt-BR").
 * [CN] 微信语言对应的语言文件夹名（"zh_CN" -> "zh-Hans"、"zh_TW" -> "zh-Hant"、"pt_BR" -> "pt-BR"）。
 */
function cylSystemLanguage() {
  let language = 'en';
  try {
    const info = typeof wx.getAppBaseInfo === 'function' ? wx.getAppBaseInfo() : wx.getSystemInfoSync();
    language = String(info.language || 'en').replace('_', '-');
  } catch (error) {
    language = 'en';
  }
  const lower = language.toLowerCase();
  if (lower.startsWith('zh')) {
    return /tw|hk|mo|hant/.test(lower) ? 'zh-Hant' : 'zh-Hans';
  }
  return language;
}

/**
 * [EN] The language in use that `tables` has (chosen, else WeChat's, else its base language), "en" when none matches.
 * [CN] `tables` 中存在的当前语言（所选语言，否则为微信语言，否则为其基础语言）；都不匹配时为 "en"。
 */
function cylLanguage(tables) {
  const language = cylChosenLanguage || cylSystemLanguage();
  const candidates = [language, language.split('-')[0]];
  return candidates.find((candidate) => tables[candidate]) || 'en';
}

/**
 * [EN] Whether the language in use is written right to left (Arabic, Hebrew). [CN] 当前语言是否从右到左书写（阿拉伯语、希伯来语）。
 */
function cylIsRightToLeft() {
  return /^(ar|he)/.test(cylChosenLanguage || cylSystemLanguage());
}

/**
 * [EN] The example text for an English key in the current language. [CN] 英文键在当前语言下的示例文字。
 */
function t(key) {
  const own = cylLanguage(cylDemoStrings);
  const table = own !== 'en' ? cylDemoStrings[own] : (cylMoreTable()[key] !== undefined ? cylMoreTable() : cylDemoStrings.en);
  return (table && table[key]) || key;
}

/**
 * [EN] The demo-list texts in the current language that the demo list has no table for (hi, es, ar).
 * [CN] 演示列表没有表的当前语言（hi、es、ar）中的演示列表文字。
 */
function cylMoreTable() {
  const language = cylLanguage(cylMoreStrings);
  return language === 'en' ? {} : (cylMoreStrings[language] || {});
}

/**
 * [EN] The configuration's localization table of the current language, for the component's `strings`.
 * [CN] 当前语言的配置本地化表，用于组件的 `strings`。
 */
function cylConfigurationTable() {
  return cylConfigurationStrings[cylLanguage(cylConfigurationStrings)] || {};
}

module.exports = { t, cylConfigurationTable, cylLanguage, cylSetLanguage, cylChosen, cylSystemLanguage, cylIsRightToLeft, cylMoreTable };
