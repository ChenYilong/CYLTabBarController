/**
 * [EN] What each Home row does on tap (the rows of Example-Shared/DemoList/demo-list.json). Rows the mini program can
 *      act out change the app's tab bar state at once; the others open the demo page (pages/demo), which runs the case
 *      in the mini program. Every row has a tap action.
 * [CN] 首页每一行点击后的行为（Example-Shared/DemoList/demo-list.json 的行）。小程序能直接演示的行立即修改 App 的
 *      TabBar 状态；其他行打开演示页（pages/demo），在小程序中运行该用例。每一行都有点击行为。
 */
const { t } = require('./cyl_demo_localization');
const { CYL_APPEARANCES } = require('./cyl_demo_updates');

/**
 * [EN] Item 33: the 14 steps of the tap animation row (CYLSettingsDemoRows.swift) as configuration keys.
 * [CN] 第 33 项：点击动画行的 14 步（CYLSettingsDemoRows.swift），以配置键表示。
 */
const CYL_STAR = `data:image/svg+xml;utf8,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2l2.9 6.6 7.1.6-5.4 4.7 1.6 7L12 17.3 5.8 20.9l1.6-7L2 9.2l7.1-.6z" fill="#FFCC00"/></svg>')}`;
const CYL_TAP_STEPS = [
  { name: 'None', animation: 'none' },
  { name: 'Scale up and down', animation: 'scale' },
  { name: 'Zoom in', animation: 'zoomIn' },
  { name: 'Bounce', animation: 'bounce' },
  { name: 'Bounce + fireworks', animation: 'bounceWithFireworks' },
  { name: 'Rotate', animation: 'rotation' },
  { name: 'Flip', animation: 'flip' },
  { name: 'Fume', animation: 'fume' },
  { name: 'Rotate (this tab only: viewController.cyl_tabButtonAnimation)', animation: 'none', thisTab: 'rotation' },
  { name: 'Frames + fireworks (all tabs: cyl_defaultTabButtonAnimation)', animation: 'frames' },
  { name: 'Slow scale up and down (CYLTabButtonScaleAnimation.duration = 1.2)', animation: 'scale', duration: 1.2 },
  { name: 'Slow zoom in (CYLTabButtonZoomInAnimation.duration = 1.2)', animation: 'zoomIn', duration: 1.2 },
  { name: 'Bounce + star fireworks (CYLTabButtonBounceAnimation.fireworksImage)', animation: 'bounceWithFireworks', fireworksImage: CYL_STAR },
  { name: 'Curl up, no deselect animation (CYLTabButtonFlipAnimation.direction = 5)', animation: 'flip', direction: 5 },
];
// [EN] Item 33: the 7 steps of the tap sound and haptics row. [CN] 第 33 项：点击声音与触感行的 7 步。
const CYL_SOUND_STEPS = [
  { name: 'None' },
  { name: 'Default click', sound: '/shared/sounds/cyl_tap_click.wav' },
  { name: 'Custom sound file (cyl_tabButtonTapSoundURL)', sound: '/shared/sounds/cyl_tap_tock.wav' },
  { name: 'Light haptic', haptic: 'light' },
  { name: 'Medium haptic', haptic: 'medium' },
  { name: 'Heavy haptic', haptic: 'heavy' },
  { name: 'Click + haptic', sound: '/shared/sounds/cyl_tap_click.wav', haptic: 'medium' },
];

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
  const updates = { ...context.overrides().cylDemoUpdates, ...change };
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
  const all = { ...context.overrides().cylDemoItemAttributes };
  Object.keys(valuesByIdentifier).forEach((identifier) => {
    const current = { ...all[identifier] };
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
  // [EN] Item 12: unloads the unselected tabs, then the alert "Memory warning" with the report. [CN] 第 12 项：卸载未选中的 Tab，然后弹出「内存警告」与报告。
  memoryWarning: (context) => {
    const bar = context.tabBar();
    const items = (context.configuration().CYLTabBarControllerTabBarItemsAttributes || [])
      .concat([context.configuration().CYLTabBarControllerPlusButton]).filter(Boolean);
    const tabs = (bar ? bar.data.cylSlots : []).map((slot) => {
      const item = items.find((candidate) => candidate.CYLTabBarItemIdentifier === slot.key) || {};
      return {
        title: (slot.item ? slot.item.title : slot.title) || slot.key,
        route: `pages/${item.CYLTabBarItemPageIdentifier || item.CYLTabBarItemIdentifier || slot.key}/index`,
        selected: Boolean(slot.selected),
      };
    });
    wx.showModal({
      title: t('Memory warning'),
      content: getApp().cyl_simulateMemoryWarning(tabs, t),
      showCancel: false,
      confirmText: t('OK'),
    });
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
    const on = !context.overrides().cylDemoItemAttributes?.['*']?.CYLTabBarItemBackgroundColor;
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
  // [EN] Item 27: the nearest real tab on each side of this page's tab (Home: only Nearby, on the right) becomes "Replaced
  //      page A" / "B"; tap again to restore; the example's decorations come back afterwards.
  // [CN] 第 27 项：当前页 Tab 两侧最近的真实 Tab（首页：只有右侧的同城）变为「替换页 A」/「B」；再点恢复；之后重新加上示例的装饰。
  replaceNeighbors: (context) => {
    const replaced = context.overrides().cylDemoReplaced;
    if (replaced) {
      context.override({ cylDemoReplaced: undefined });
    } else {
      const tabs = (context.configuration().CYLTabBarControllerTabBarItemsAttributes || []).map((item) => item.CYLTabBarItemIdentifier);
      const index = tabs.indexOf('home');
      const next = {};
      if (index > 0) {
        next[tabs[index - 1]] = 'A';
      }
      if (index >= 0 && index < tabs.length - 1) {
        next[tabs[index + 1]] = 'B';
      }
      context.override({ cylDemoReplaced: next });
    }
    getApp().cyl_decorateTabBar();
  },
  // [EN] Item 30: the row itself does nothing; its switch and slider act (pages/home). [CN] 第 30 项：点击该行无效果；由开关与滑块操作（pages/home）。
  touchableArea: () => {},
  // [EN] Item 35: (0.5 s / 0.35 s) → (1.0 / 0.6) → (0.25 / 0.25). [CN] 第 35 项：依次切换长按时长与双击间隔。
  longPressDuration: (context) => {
    const presets = [[0.5, 0.35], [1, 0.6], [0.25, 0.25]];
    const current = context.configuration().CYLTabBarControllerTabBarItemLongPressDuration || 0.5;
    const index = presets.findIndex(([value]) => Math.abs(value - current) < 0.001);
    const [longPress, doubleTap] = presets[(Math.max(0, index) + 1) % presets.length];
    context.override({ CYLTabBarControllerTabBarItemLongPressDuration: longPress, CYLTabBarControllerTabBarItemDoubleTapInterval: doubleTap });
  },
  // [EN] The long press switch: a long press on a tab or the plus button shows its identifier. [CN] 长按开关：长按 Tab 或 PlusButton 显示其标识。
  longPress: (context) => context.update({ longPressEnabled: !context.state().longPressEnabled }),
  imageLater: (context) => {
    context.override({ cylDemoPlusAttributes: { CYLTabBarItemImage: '', CYLTabBarItemSelectedImage: '' } });
    setTimeout(() => context.override({ cylDemoPlusAttributes: undefined }), 1500);
    context.toast(t('The plus image arrives in 1.5 s'));
  },
  // [EN] Item 33: the next of the 14 animations, played once on the selected tab. [CN] 第 33 项：切换到下一个动画，并在选中 Tab 上播放一次。
  tapAnimation: (context) => {
    const step = ((context.overrides().cylDemoTapStep || 0) + 1) % CYL_TAP_STEPS.length;
    const entry = CYL_TAP_STEPS[step];
    const bar = context.tabBar();
    const selected = bar ? bar.data.cylSlots.find((slot) => slot.selected)?.key : '';
    const attributes = { ...context.overrides().cylDemoItemAttributes };
    Object.keys(attributes).forEach((identifier) => {
      const changed = { ...attributes[identifier] };
      delete changed.CYLTabBarItemTabButtonTapAnimation;
      attributes[identifier] = changed;
    });
    if (entry.thisTab && selected) {
      attributes[selected] = { ...attributes[selected], CYLTabBarItemTabButtonTapAnimation: entry.thisTab };
    }
    context.override({
      cylDemoTapStep: step,
      cylDemoItemAttributes: attributes,
      CYLTabBarControllerTabButtonTapAnimation: step === 0 ? undefined : entry.animation,
      CYLTabBarControllerTabButtonTapAnimationDuration: entry.duration,
      CYLTabBarControllerTabButtonFireworksImage: entry.fireworksImage,
      CYLTabBarControllerTabButtonFlipDirection: entry.direction,
    });
    setTimeout(() => {
      const current = context.tabBar();
      if (current) {
        current.cylPlaySelectedTapAnimation();
      }
    }, 300);
  },
  // [EN] Item 33: the next of the 7 sound and haptic steps, played once at once. [CN] 第 33 项：切换到下一步，并立即播放一次。
  tapSound: (context) => {
    const step = ((context.overrides().cylDemoSoundStep || 0) + 1) % CYL_SOUND_STEPS.length;
    const entry = CYL_SOUND_STEPS[step];
    context.override({
      cylDemoSoundStep: step,
      CYLTabBarControllerTabButtonTapSoundURL: entry.sound,
      CYLTabBarControllerTabButtonTapHapticStyle: entry.haptic,
    });
    setTimeout(() => {
      const bar = context.tabBar();
      if (bar) {
        bar.cylPlayTabButtonTapFeedback();
      }
    }, 300);
  },
  // [EN] Item 37: the row does nothing; its arrows call cylSwitchToAdjacentTab (pages/home cyl_onArrow). [CN] 第 37 项：点击该行无效果；由箭头调用（pages/home 的 cyl_onArrow）。
  adjacentTab: () => {},
};

/**
 * [EN] The action of row `id`, or opening the demo page for it.
 * [CN] 行 `id` 的行为；没有时打开它的演示页。
 */
function cylHomeAction(id) {
  return CYL_HOME_ACTIONS[id] || ((context) => context.open(id));
}

module.exports = { cylHomeAction, CYL_HOME_ACTIONS, CYL_TAP_STEPS, CYL_SOUND_STEPS };
