/**
 * [EN] What each Home row does on tap (the rows of Example-Shared/DemoList/demo-list.json). Rows the mini program can
 *      act out change the app's tab bar state at once; the others open the demo page (pages/demo), which runs the case
 *      in the mini program. Every row has a tap action.
 * [CN] 首页每一行点击后的行为（Example-Shared/DemoList/demo-list.json 的行）。小程序能直接演示的行立即修改 App 的
 *      TabBar 状态；其他行打开演示页（pages/demo），在小程序中运行该用例。每一行都有点击行为。
 */
const { t } = require('./cyl_demo_localization');
const { CYL_APPEARANCES } = require('./cyl_demo_updates');

// [EN] Item 13: the vertical title offsets the row cycles through (CYLSettingsDemoRows.swift). [CN] 第 13 项：本行依次切换的标题垂直偏移。
const CYL_TITLE_OFFSETS = [0, -4, 4];
// [EN] Item 16: CYLTabBarMinimizeBehavior, in the row's order. [CN] 第 16 项：CYLTabBarMinimizeBehavior，按本行顺序。
const CYL_SCROLL_BEHAVIORS = ['Automatic', 'OnScrollDown', 'OnScrollUp', 'Never'];

/**
 * [EN] The vertical value of a "{h, v}" offset. [CN] "{h, v}" 偏移的垂直值。
 */
function cylVertical(offset) {
  const match = /\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}/.exec(String(offset || ''));
  return match ? Number(match[2]) : 0;
}

/**
 * [EN] Turns update flags on or off (utils/cyl_demo_updates.js). [CN] 打开或关闭更新标记（utils/cyl_demo_updates.js）。
 */
function cylSetUpdates(context, change) {
  const updates = Object.assign({}, context.overrides().cylDemoUpdates, change);
  Object.keys(updates).forEach((key) => {
    if (!updates[key]) {
      delete updates[key];
    }
  });
  context.override({ cylDemoUpdates: updates });
}

function cylUpdates(context) {
  return context.overrides().cylDemoUpdates || {};
}

/**
 * [EN] Sets the same keys on several tabs (null removes them).
 * [CN] 给多个 Tab 设置相同的键（null 表示移除）。
 */
function cylSetAttributes(context, valuesByIdentifier) {
  const all = Object.assign({}, context.overrides().cylDemoItemAttributes);
  Object.keys(valuesByIdentifier).forEach((identifier) => {
    const current = Object.assign({}, all[identifier]);
    Object.entries(valuesByIdentifier[identifier]).forEach(([key, value]) => {
      if (value === null) {
        delete current[key];
      } else {
        current[key] = value;
      }
    });
    all[identifier] = current;
  });
  context.override({ cylDemoItemAttributes: all });
}

/**
 * [EN] The actions by row id. `context` has: state(), configuration(), overrides(), update(change), override(change),
 *      tabBar(), toast(text), open(id).
 * [CN] 按行 id 的行为。`context` 提供：state()、configuration()、overrides()、update(change)、override(change)、
 *      tabBar()、toast(text)、open(id)。
 */
const CYL_HOME_ACTIONS = {
  memoryWarning: (context) => {
    // [EN] What the core does on a memory warning: drop the decoded icon images; the bar draws them again. [CN] 核心层收到内存警告时的行为：丢弃已解码的图标；TabBar 重新绘制。
    context.update({ overrides: Object.assign({}, context.overrides()) });
    context.toast(t('Memory warning: icon caches released and drawn again'));
  },
  // [EN] Item 13: 0 → -4 → 4 on every tab; a value not in the list goes to the first. [CN] 第 13 项：所有 Tab 依次为 0 → -4 → 4；不在列表中的值回到第一个。
  titleOffset: (context) => {
    const current = cylVertical(context.configuration().CYLTabBarControllerTitlePositionAdjustment);
    const index = CYL_TITLE_OFFSETS.findIndex((value) => Math.abs(value - current) < 0.5);
    const next = index < 0 ? CYL_TITLE_OFFSETS[0] : CYL_TITLE_OFFSETS[(index + 1) % CYL_TITLE_OFFSETS.length];
    context.override({ CYLTabBarControllerTitlePositionAdjustment: `{0, ${next}}` });
  },
  // [EN] Item 14: Original → Dark → Centered capsule → Green line. [CN] 第 14 项：原始 → 深色 → 居中胶囊 → 绿色描边。
  standardAppearance: (context) => {
    const current = context.overrides().cylDemoAppearance || 'Original';
    const next = CYL_APPEARANCES[(CYL_APPEARANCES.indexOf(current) + 1) % CYL_APPEARANCES.length];
    context.override({ cylDemoAppearance: next === 'Original' ? undefined : next });
  },
  // [EN] Item 16: Automatic → OnScrollDown → OnScrollUp → Never (pages/home onPageScroll). [CN] 第 16 项：依次切换滚动行为（pages/home 的 onPageScroll）。
  scrollBehavior: (context) => {
    const current = context.state().scrollBehavior || 'Automatic';
    context.update({ scrollBehavior: CYL_SCROLL_BEHAVIORS[(CYL_SCROLL_BEHAVIORS.indexOf(current) + 1) % CYL_SCROLL_BEHAVIORS.length], tabBarHidden: false });
  },
  flatShowHide: (context) => context.update({ tabBarHidden: !context.state().tabBarHidden }),
  // [EN] Item 19: FlatDesign only (an alert otherwise); every tab toggles #2E2E2E, selected black. [CN] 第 19 项：仅扁平样式（否则弹窗）；每个 Tab 切换 #2E2E2E 背景，选中为黑色。
  flatBackground: (context) => {
    if (context.configuration().CYLTabBarControllerStyleType !== 'flatDesign') {
      wx.showModal({
        title: t('Not supported by this tab bar style'),
        content: t('This needs FlatDesign tab items (CYLFlatDesignTabBarItem). With Liquid Glass and the classic style the system draws the tab items, so their layout and background color cannot be changed.'),
        showCancel: false,
        confirmText: t('OK'),
      });
      return;
    }
    const on = !((context.overrides().cylDemoItemAttributes || {})['*'] || {}).CYLTabBarItemBackgroundColor;
    cylSetAttributes(context, { '*': { CYLTabBarItemBackgroundColor: on ? '#2E2E2E' : null, CYLTabBarItemSelectedBackgroundColor: on ? '#000000' : null } });
  },
  // [EN] Item 21: this page's tab title becomes "Purchased courses"; tap again to restore. [CN] 第 21 项：当前页 Tab 标题改为「已购课程」；再点恢复。
  changeTabTitle: (context) => cylSetUpdates(context, { changeTabTitle: !cylUpdates(context).changeTabTitle }),
  // [EN] Items 22, 25 and "Switch tab icon" share this page's icon slot. [CN] 第 22、25 项与「切换 Tab 图标」共用当前页的图标位置。
  switchTabIcon: (context) => cylSetUpdates(context, { homeIcon: cylUpdates(context).homeIcon === 'custom' ? '' : 'custom' }),
  downloadNetworkIcon: (context) => cylSetUpdates(context, { homeIcon: cylUpdates(context).homeIcon === 'network' ? '' : 'network' }),
  gifIcon: (context) => cylSetUpdates(context, { homeIcon: cylUpdates(context).homeIcon === 'gif' ? '' : 'gif' }),
  // [EN] Items 23 and 24 exclude each other and clear the single icon. [CN] 第 23、24 项互斥，并清除单个图标。
  allNetworkIcons: (context) => cylSetUpdates(context, { allIcons: cylUpdates(context).allIcons === 'network' ? '' : 'network', homeIcon: '' }),
  allLocalIcons: (context) => cylSetUpdates(context, { allIcons: cylUpdates(context).allIcons === 'local' ? '' : 'local', homeIcon: '' }),
  // [EN] Item 26: "★ " before every title; restoring also clears item 21. [CN] 第 26 项：每个标题前加「★ 」；恢复时同时清除第 21 项。
  allTitles: (context) => {
    const on = !cylUpdates(context).allTitles;
    cylSetUpdates(context, on ? { allTitles: true } : { allTitles: false, changeTabTitle: false });
  },
  replaceNeighbors: (context) => {
    // [EN] Discover and Me swap their places by hiding one and showing the other (one bar, other tabs). [CN] 通过隐藏一个、显示另一个，替换相邻的 Tab。
    const hidden = context.state().hiddenIdentifiers || [];
    context.update({ hiddenIdentifiers: hidden.includes('city') ? [] : ['city'] });
    context.toast(t(hidden.includes('city') ? 'Discover is back' : 'Discover replaced: its neighbors moved in'));
  },
  touchableArea: (context) => {
    const on = !context.overrides().cylDemoPlusAttributes;
    context.override({ cylDemoPlusAttributes: on ? { CYLPlusButtonSize: '{84, 84}' } : undefined });
    context.toast(t(on ? 'Plus button: larger touchable area' : 'Plus button: default touchable area'));
  },
  imageLater: (context) => {
    context.override({ cylDemoPlusAttributes: { CYLTabBarItemImage: '', CYLTabBarItemSelectedImage: '' } });
    setTimeout(() => context.override({ cylDemoPlusAttributes: undefined }), 1500);
    context.toast(t('The plus image arrives in 1.5 s'));
  },
  tapSound: (context) => {
    const on = !context.state().tapFeedback;
    context.update({ tapFeedback: on });
    if (on) {
      wx.vibrateShort({ type: 'light' });
    }
    context.toast(t(on ? 'Haptics on every tab tap' : 'Haptics off'));
  },
  adjacentTab: (context) => {
    const bar = context.tabBar();
    if (bar) {
      bar.cyl_selectAdjacent(1);
    }
  },
};

/**
 * [EN] The action of row `id`, or opening the demo page for it.
 * [CN] 行 `id` 的行为；没有时打开它的演示页。
 */
function cylHomeAction(id) {
  return CYL_HOME_ACTIONS[id] || ((context) => context.open(id));
}

module.exports = { cylHomeAction, CYL_HOME_ACTIONS };
