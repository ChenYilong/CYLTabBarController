/**
 * [EN] The cases the demo page (pages/demo) runs for the Home rows that have no direct action. Each case returns
 *      { note, input, configuration, actions }: `input` is the configuration text it feeds to the core, `configuration`
 *      what a live cyl-tab-bar on the page draws, `actions` buttons that run more of the case.
 * [CN] 演示页（pages/demo）为没有直接行为的首页行运行的用例。每个用例返回 { note, input, configuration, actions }：
 *      `input` 是交给核心层的配置文字，`configuration` 是页面上实时 cyl-tab-bar 绘制的配置，`actions` 是运行更多内容的按钮。
 */
const { cylReadConfiguration } = require('cyl-tabbar-miniprogram/cyl-tab-bar/cyl_configuration');
const { cylDemoConfiguration, cylAvailableAnimationFiles } = require('./cyl_demo_configuration');
const { t } = require('./cyl_demo_localization');

const CYL_TAB = (title, identifier, extra) => ({
  CYLTabBarItemTitle: title,
  CYLTabBarItemImage: `/shared/skins/2.1.0/light/${identifier}@3x.png`,
  CYLTabBarItemSelectedImage: `/shared/skins/2.1.0/light/${identifier}_selected@3x.png`,
  CYLTabBarItemIdentifier: identifier,
  ...extra,
});
const CYL_TABS = () => [CYL_TAB('Home', 'home'), CYL_TAB('Message', 'message'), CYL_TAB('Discover', 'discover'), CYL_TAB('Me', 'me')];
const CYL_JSON = (object) => JSON.stringify(object);

/**
 * [EN] The configuration-file cases: the text a broken file holds, as the iOS example's ConfigurationFailures.
 * [CN] 配置文件用例：损坏文件中的文字，与 iOS 示例的 ConfigurationFailures 相同。
 */
const CYL_CONFIGURATION_INPUTS = {
  configurationFile: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }),
  configurationA3: () => '',
  configurationA4: () => '// only comments\n/* nothing else */',
  configurationA13: () => '{"CYLTabBarControllerTabBarItemsAttributes": [ {"CYLTabBarItemTitle": "Home",',
  configurationA11: () => CYL_JSON(CYL_TABS()),
  configurationA7: () => 'CYLTabBarControllerTabBarItemsAttributes:\n  - CYLTabBarItemTitle: Home',
  configurationA5: () => '{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "��"}]}',
  configurationA16: () => '﻿{\u0000"\u0000C\u0000',
  configurationA10: () => `${'['.repeat(10000)}${']'.repeat(10000)}`,
  configurationA9: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: CYL_TABS(), cylPadding: 'x'.repeat(6 * 1024 * 1024) }),
  configurationB1: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [] }),
  configurationD7: () => '<!DOCTYPE html><html><body>404 Not Found</body></html>',
  configurationB5: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarItemTitle: 42 }), null, 'Me', CYL_TAB('Discover', 'discover', { CYLTabBarItemImage: null })] }),
  configurationB7: () => CYL_JSON({ CYLTabBarControllerImageInsets: '{NaN, Infinity, 0, 0}', CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }),
  configurationB9: () => CYL_JSON({ CYLTabBarControllerStyleType: 'hologram', CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }),
  configurationB22: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home'), CYL_TAB('Android only', 'message', { CYLTabBarItemPlatforms: 'android' }), CYL_TAB('Future', 'discover', { CYLTabBarItemMinimumAppVersion: '99.0' }), CYL_TAB('Me', 'me')] }),
  configurationB23: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarItemPlatforms: 42 }), CYL_TAB('Me', 'me', { CYLTabBarItemMinimumAppVersion: 'abc' })] }),
  configurationB28: () => CYL_JSON({ CYLTabBarControllerTabBarItemAnimationSpeed: -3, CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarLottieURL: 42 }), CYL_TAB('Me', 'me')] }),
  configurationB30: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarGIFFilePath: '/shared/skins/2.1.0/light/home@3x.png' }), CYL_TAB('Me', 'me')] }),
  configurationB13: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarItemImage: 'htp:/bad url' }), CYL_TAB('Me', 'me', { CYLTabBarLottieURL: 'missing.json' })] }),
  configurationB12: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home'), CYL_TAB('Home again', 'home'), CYL_TAB('Me', 'me')] }),
  configurationB11: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [{ CYLTabBarItemTitel: 'Home', CYLTabBarItemImage: '/shared/skins/2.1.0/light/home@3x.png', CYLTabBarItemIdentifier: 'home' }, CYL_TAB('Me', 'me')] }),
  configurationB19: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home', { CYLTabBarItemTitleColor: '#GGGGGG', CYLTabBarItemTitleFont: 'bold:-4' }), CYL_TAB('Me', 'me')] }),
  configurationB21: () => CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('', 'home', { CYLTabBarItemImage: '' }), CYL_TAB('Me', 'me')] }),
  configurationA12: () => '\u0008\u0096\u0001\u0012\u0004Ho',
  configurationA12b: () => 'bplist00Ô\u0001\u0002',
  configurationA14: () => '<?xml version="1.0"?><!DOCTYPE plist [<!ENTITY x SYSTEM "file:///etc/passwd">]><plist>&x;</plist>',
  configurationA2: () => null,
};

/**
 * [EN] Parses `text` as the core would load a file, then reads it with cylReadConfiguration.
 * [CN] 像核心层读取文件那样解析 `text`，再用 cylReadConfiguration 读取。
 */
function cylLoad(text) {
  if (text === null) {
    return { ok: false, result: t('The file does not exist: the default configuration is kept') };
  }
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return { ok: false, result: `${t('Not valid JSON: the default configuration is kept')} (${String(error.message).slice(0, 80)})` };
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return { ok: false, result: t('The top level is not a dictionary: the default configuration is kept') };
  }
  const read = cylReadConfiguration(parsed, { appVersion: '1.0.0' });
  const titles = read.items.map((item) => item.title || '—').join(', ');
  return {
    ok: read.items.length > 0,
    configuration: read.items.length ? parsed : null,
    result: read.items.length
      ? `${read.items.length} ${t('tabs')}: ${titles}; ${t('style')} ${read.styleType}`
      : t('No usable tab: the default configuration is kept'),
  };
}

/**
 * [EN] A request through wx.request, its outcome shown on the page.
 * [CN] 通过 wx.request 发出的请求，结果显示在页面上。
 */
function cylRequest(options) {
  return (page) => {
    page.setData({ result: t('Loading…') });
    const task = wx.request({
      success: (response) => page.setData({ result: `HTTP ${response.statusCode}` }),
      fail: (error) => page.setData({ result: `${t('Failed, the default configuration is kept')}: ${error.errMsg}` }),
      ...options,
    });
    if (options.cylCancel && task) {
      setTimeout(() => task.abort(), 50);
    }
  };
}

const CYL_CASES = {
  memoryWarning: () => ({ note: t('The tab bar drops its decoded icons on a memory warning and draws them again.') }),
  flatHeight: () => ({
    note: t('Three bars of different heights, drawn by cyl-tab-bar inside a frame of that height.'),
    heights: [44, 56, 72],
    configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() },
  }),
  flatNotCentered: () => ({ note: t('Items laid out as the system does: icon above the title.'), items: [{ title: 'Home', image: 'home' }, { title: 'Me', image: 'me' }] }),
  flatCentered: () => ({ note: t('Items with no image are centered in their slot (layoutCentered).'), items: [{ title: 'Home', centered: true }, { title: 'Me', centered: true }] }),
  scrollSimulation: () => ({ note: t('Scroll this page: the bar hides while you scroll down and comes back when you scroll up or stop.'), scroll: true, configuration: cylDemoConfiguration({}) }),
  scrollSimulationsToggle: () => ({ note: t('Scroll this page: the bar hides while you scroll down and comes back when you scroll up or stop.'), scroll: true, configuration: cylDemoConfiguration({}) }),
  gifIcon: () => {
    const gif = cylAvailableAnimationFiles().find((file) => file.endsWith('.gif'));
    return {
      note: gif ? t('A tab whose icon is a GIF file.') : t('Run npm run setup -- --animation=gif to install the GIF files; the bar below shows the fallback image.'),
      configuration: { CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('GIF', 'home', gif ? { CYLTabBarGIFFilePath: gif, CYLTabBarGIFSize: '{30, 30}' } : {})].concat(CYL_TABS().slice(1)) },
    };
  },
  longPress: () => ({ note: t('Long press a tab of the bar below.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }, longPress: true }),
  longPressDuration: () => ({ note: t('Long press a tab of the bar below: the time you held it is shown.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }, longPress: true }),
  slideTransition: () => ({ note: t('Tap the tabs: the panels slide left or right like CYLTabBarSlideTransitionAnimator.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }, slide: true }),
  hideNavigationBar: () => ({ note: t('Toggle the navigation bar title and loading indicator of this page.'), actions: [{ label: t('Toggle'), run: (page) => page.cyl_toggleNavigation() }] }),
  outsideBounds: () => ({ note: t('The raised plus button reaches above the bar and still takes taps there.'), configuration: cylDemoConfiguration({}) }),
  bundleImage: () => ({ note: t('Tab images loaded from the package folder /shared/skins.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() } }),
  weakAssociation: () => ({ note: t('Finds a tab item component by its identifier with selectComponent.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }, actions: [{ label: t('Find Discover'), run: (page) => page.cyl_findItem('discover') }] }),
  configurationC11: () => ({ note: t('A tab whose page is not registered opens nothing; the bar still draws it.'), configuration: { CYLTabBarControllerTabBarItemsAttributes: [CYL_TAB('Home', 'home'), CYL_TAB('Unknown', 'message', { CYLTabBarItemPageIdentifier: 'nowhere' })] } }),
  configurationD4: () => ({ note: 'https://cyl-unknown-host.invalid/configuration.json', actions: [{ label: t('Run'), run: cylRequest({ url: 'https://cyl-unknown-host.invalid/configuration.json' }) }] }),
  configurationD5: () => ({ note: 'timeout: 3000 ms', actions: [{ label: t('Run'), run: cylRequest({ url: 'https://10.255.255.1/configuration.json', timeout: 3000 }) }] }),
  configurationD10: () => ({ note: t('The request is cancelled 50 ms after it starts.'), actions: [{ label: t('Run'), run: cylRequest({ url: 'https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/README.md', cylCancel: true }) }] }),
  configurationC10: () => ({ note: t('A request without a URL.'), actions: [{ label: t('Run'), run: cylRequest({ url: '' }) }] }),
  configurationD7n: () => ({ note: 'https://github.com/ChenYilong', actions: [{ label: t('Run'), run: cylRequest({ url: 'https://github.com/ChenYilong' }) }] }),
  compareSystem: () => ({ note: t('The system tab bar of WeChat (app.json tabBar without custom) next to cyl-tab-bar.'), configuration: cylDemoConfiguration({}), system: true }),
  pushSystem: () => ({ note: t('Opens another page with its own tab bar and plus button.'), actions: [{ label: t('Open'), run: () => wx.navigateTo({ url: '/pages/glass/index' }) }] }),
  pushFlat: () => ({ note: t('Opens another page with its own tab bar and plus button.'), actions: [{ label: t('Open'), run: () => wx.navigateTo({ url: '/pages/glass/index' }) }] }),
  popPush: () => ({
    note: t('Push a new page on the stack, or pop this one.'),
    actions: [
      { label: 'cyl_push', run: (page) => wx.navigateTo({ url: `/pages/demo/index?id=popPush&title=${encodeURIComponent(`cyl_push ${getCurrentPages().length}`)}` }) },
      { label: 'cyl_pop', run: () => wx.navigateBack() },
    ],
  }),
};

/**
 * [EN] The case of row `id`: a configuration-file case is loaded and drawn; other code-only cases explain the
 *      mini program's counterpart.
 * [CN] 行 `id` 的用例：配置文件用例会被读取并绘制；其他只能用代码演示的用例说明小程序中的对应做法。
 */
function cylDemoCase(id) {
  if (CYL_CASES[id]) {
    return CYL_CASES[id]();
  }
  if (CYL_CONFIGURATION_INPUTS[id]) {
    const input = CYL_CONFIGURATION_INPUTS[id]();
    const loaded = cylLoad(input);
    return {
      note: t('This file is loaded with cylReadConfiguration of the core.'),
      input: input === null ? '' : (input.length > 400 ? `${input.slice(0, 400)}… (${input.length} ${t('characters')})` : input),
      result: loaded.result,
      configuration: loaded.configuration,
    };
  }
  // [EN] Cases that need code (C*, B18, C6, C9, E1, B27, C20): the same check in the mini program. [CN] 需要代码的用例：在小程序中做同样的检查。
  const values = { configurationB18: 'not a dictionary', configurationC6: [null, 'page', 'page'], configurationC9: [] };
  const loaded = cylLoad(id in values ? JSON.stringify(values[id]) : CYL_JSON({ CYLTabBarControllerTabBarItemsAttributes: CYL_TABS() }));
  return { note: t('A case written in code on iOS; here the same input goes through cylReadConfiguration.'), result: loaded.result, configuration: loaded.configuration };
}

module.exports = { cylDemoCase, cylLoad };
