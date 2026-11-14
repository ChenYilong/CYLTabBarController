/**
 * [EN] The feed of badge rows that every iOS tab shows under its demo sections (UITableViewCell+CYLBadgeHelper,
 *      `-cyl_badgeTitleForRow:` and `-cyl_showBadgeForRow:`), from the shared demo list.
 * [CN] iOS 每个 Tab 在演示 section 下方显示的角标行信息流（UITableViewCell+CYLBadgeHelper 的 `-cyl_badgeTitleForRow:`
 *      与 `-cyl_showBadgeForRow:`），来自共用演示列表。
 */
const cylDemoList = require('../shared/demo_list');
const { cylLanguage } = require('./cyl_demo_localization');

/**
 * [EN] A badge text as the core shows it: numbers above the maximum read "99+".
 * [CN] 与核心层相同的角标文字：超过上限的数字显示为 "99+"。
 */
function cylBadgeText(sample) {
  const maximum = sample.maximum || 99;
  const number = Number(sample.value);
  return Number.isFinite(number) && sample.value !== '' && number > maximum ? `${maximum}+` : (sample.value || '');
}

function cylListText(text) {
  const table = cylDemoList.strings[cylLanguage(cylDemoList.strings)] || {};
  return table[text] || text || '';
}

/**
 * [EN] The rows: index, title, badge text (empty for a dot).
 * [CN] 各行：序号、标题、角标文字（红点时为空）。
 */
function cylFeedRows() {
  return cylDemoList.badgeSamples.map((sample, index) => ({
    index,
    title: cylListText(sample.title),
    text: cylBadgeText(sample),
    dot: !sample.value,
  }));
}

module.exports = { cylFeedRows, cylBadgeText };
