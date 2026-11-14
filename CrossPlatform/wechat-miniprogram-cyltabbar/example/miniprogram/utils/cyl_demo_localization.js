/**
 * [EN] The example's localization: one function, t(), over the example's own tables (cyl_demo_strings.js), and the
 *      configuration's table of the current language (shared/localization.js, the ConfigurationDemo tables of
 *      Example-Shared). The component itself has no texts.
 * [CN] 示例的本地化：一个函数 t()，读取示例自己的表（cyl_demo_strings.js）；另外提供当前语言的配置本地化表
 *      （shared/localization.js，即 Example-Shared 的 ConfigurationDemo 表）。组件本身没有文字。
 */
const cylDemoStrings = require('./cyl_demo_strings');
const cylConfigurationStrings = require('../shared/localization');

/**
 * [EN] The language folder name that matches the system language ("zh_CN" -> "zh-Hans", "zh_TW" -> "zh-Hant",
 *      "pt_BR" -> "pt-BR", "de" -> "de"), "en" when none matches.
 * [CN] 与系统语言匹配的语言文件夹名（"zh_CN" -> "zh-Hans"、"zh_TW" -> "zh-Hant"、"pt_BR" -> "pt-BR"、"de" -> "de"），
 *      没有匹配时为 "en"。
 */
function cylLanguage(tables) {
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
  const candidates = [language, language.split('-')[0]];
  return candidates.find((candidate) => tables[candidate]) || 'en';
}

/**
 * [EN] The example text for an English key in the current language.
 * [CN] 英文键在当前语言下的示例文字。
 */
function t(key) {
  const table = cylDemoStrings[cylLanguage(cylDemoStrings)] || {};
  return table[key] || key;
}

/**
 * [EN] The configuration's localization table of the current language, for the component's `strings`.
 * [CN] 当前语言的配置本地化表，用于组件的 `strings`。
 */
function cylConfigurationTable() {
  return cylConfigurationStrings[cylLanguage(cylConfigurationStrings)] || {};
}

module.exports = { t, cylConfigurationTable, cylLanguage };
