/**
 * [EN] What each Home row does on tap (the rows of Example-Shared/DemoList/demo-list.json). Rows the mini program can
 *      act out change the app's tab bar state at once; the others open the demo page (pages/demo), which runs the case
 *      in the mini program. Every row has a tap action.
 * [CN] 首页每一行点击后的行为（Example-Shared/DemoList/demo-list.json 的行）。小程序能直接演示的行立即修改 App 的
 *      TabBar 状态；其他行打开演示页（pages/demo），在小程序中运行该用例。每一行都有点击行为。
 */
const { t } = require('./cyl_demo_localization');

// [EN] Icons on the network: the theme images of the iOS core bundle on GitHub. [CN] 网络图标：GitHub 上 iOS 核心 bundle 的主题图片。
const CYL_NETWORK_ICON = (name) => `https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController/Resources/CYLTabBarController.bundle/cyl_theme_${name}@3x.png`;
const CYL_NETWORK_ICONS = { home: 'balloon', message: 'bell', discover: 'beach_with_umbrella', me: 'alarm_clock' };
const CYL_LOCAL_ICON = (identifier, selected) => `/shared/skins/2.1.0/light/${identifier}${selected ? '_selected' : ''}@3x.png`;
const CYL_TABS = ['home', 'city', 'message', 'CYLMineViewController'];

// [EN] Title offsets the row cycles through. [CN] 本行依次切换的标题偏移。
const CYL_TITLE_OFFSETS = ['{0, -2}', '{0, -6}', '{0, 2}'];
const CYL_BACKGROUNDS = ['', '#FFF3E0', '#E8F5E9', '#E3F2FD'];
const CYL_TITLE_SETS = [
  {},
  { home: 'Feed', city: 'Explore', message: 'Inbox', CYLMineViewController: 'Profile' },
  { home: '首页', city: '同城', message: '消息', CYLMineViewController: '我的' },
];

/**
 * [EN] Toggles `key` of the per-tab attributes of `identifier` between `value` and nothing.
 * [CN] 在 `value` 与无之间切换 `identifier` 的单个 Tab 属性 `key`。
 */
function cylToggleAttribute(context, identifier, key, value) {
  const all = Object.assign({}, context.overrides().cylDemoItemAttributes);
  const current = Object.assign({}, all[identifier]);
  if (current[key] === value) {
    delete current[key];
  } else {
    current[key] = value;
  }
  all[identifier] = current;
  context.override({ cylDemoItemAttributes: all });
  return current[key] === value;
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

function cylNext(list, current) {
  return list[(list.indexOf(current) + 1) % list.length];
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
  titleOffset: (context) => {
    const current = context.configuration().CYLTabBarControllerTitlePositionAdjustment;
    context.override({ CYLTabBarControllerTitlePositionAdjustment: cylNext(CYL_TITLE_OFFSETS, current) });
  },
  standardAppearance: (context) => {
    const state = context.state();
    context.update({ itemStyle: state.itemStyle === 'liquidGlass' ? 'flat' : 'liquidGlass' });
    context.toast(`CYLTabBarItemStyle: ${state.itemStyle === 'liquidGlass' ? 'flat' : 'liquidGlass'}`);
  },
  scrollBehavior: (context) => {
    const on = !context.state().hidesOnScroll;
    context.update({ hidesOnScroll: on, tabBarHidden: false });
    context.toast(t(on ? 'Scroll down to hide the tab bar, up to show it' : 'The tab bar stays on scroll'));
  },
  flatShowHide: (context) => context.update({ tabBarHidden: !context.state().tabBarHidden }),
  flatBackground: (context) => {
    const current = ((context.overrides().cylDemoItemAttributes || {})['*'] || {}).CYLTabBarItemBackgroundColor || '';
    const next = cylNext(CYL_BACKGROUNDS, current);
    cylSetAttributes(context, { '*': { CYLTabBarItemBackgroundColor: next || null } });
  },
  changeTabTitle: (context) => {
    const on = cylToggleAttribute(context, 'home', 'CYLTabBarItemTitle', 'Changed');
    // [EN] The selected title too: a selected Home shows "Refresh". [CN] 选中标题也一起修改：选中的首页显示「Refresh」。
    const all = Object.assign({}, context.overrides().cylDemoItemAttributes);
    const home = Object.assign({}, all.home);
    if (on) {
      home.CYLTabBarItemSelectedTitle = 'Changed';
    } else {
      delete home.CYLTabBarItemSelectedTitle;
    }
    context.override({ cylDemoItemAttributes: Object.assign(all, { home }) });
    context.toast(t(on ? 'First tab title: Changed' : 'First tab title restored'));
  },
  allTitles: (context) => {
    const current = (context.overrides().cylDemoTitleSet || 0);
    const next = (current + 1) % CYL_TITLE_SETS.length;
    const titles = CYL_TITLE_SETS[next];
    const values = {};
    CYL_TABS.forEach((identifier) => {
      values[identifier] = { CYLTabBarItemTitle: titles[identifier] || null, CYLTabBarItemSelectedTitle: titles[identifier] || null };
    });
    cylSetAttributes(context, values);
    context.override({ cylDemoTitleSet: next });
  },
  switchTabIcon: (context) => {
    const on = cylToggleAttribute(context, 'city', 'CYLTabBarItemImage', CYL_NETWORK_ICON('bell'));
    cylSetAttributes(context, { discover: { CYLTabBarItemSelectedImage: on ? CYL_NETWORK_ICON('bell') : null } });
    context.override({ cylDemoIcons: 'images' });
  },
  downloadNetworkIcon: (context) => {
    cylSetAttributes(context, { me: { CYLTabBarItemImage: CYL_NETWORK_ICON('alarm_clock'), CYLTabBarItemSelectedImage: CYL_NETWORK_ICON('alarm_clock'), CYLTabBarItemImageURLSize: '{28, 28}' } });
    context.override({ cylDemoIcons: 'images' });
    context.toast(t('Downloading the icon of Me'));
  },
  allNetworkIcons: (context) => {
    const values = {};
    CYL_TABS.forEach((identifier) => {
      const url = CYL_NETWORK_ICON(CYL_NETWORK_ICONS[identifier]);
      values[identifier] = { CYLTabBarItemImage: url, CYLTabBarItemSelectedImage: url, CYLTabBarItemImageURLSize: '{28, 28}' };
    });
    cylSetAttributes(context, values);
    context.override({ cylDemoIcons: 'images' });
  },
  allLocalIcons: (context) => {
    const values = {};
    CYL_TABS.forEach((identifier) => {
      values[identifier] = { CYLTabBarItemImage: CYL_LOCAL_ICON(identifier, false), CYLTabBarItemSelectedImage: CYL_LOCAL_ICON(identifier, true), CYLTabBarItemImageURLSize: null };
    });
    cylSetAttributes(context, values);
    context.override({ cylDemoIcons: 'images' });
  },
  gifIcon: (context) => context.open('gifIcon'),
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
