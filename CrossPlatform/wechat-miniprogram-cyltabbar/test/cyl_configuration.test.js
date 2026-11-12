/**
 * [EN] Tests of the configuration reader of cyl-tab-bar (src/cyl-tab-bar/cyl_configuration.js),
 *      with the shared sample configuration and edge cases. Run: `npm test` (node --test).
 * [CN] cyl-tab-bar 配置读取器（miniprogram/components/cyl-tab-bar/cyl_configuration.js）的测试，使用共用示例配置与
 *      边界情况。运行：`npm test`（node --test）。
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const reader = require('../src/cyl-tab-bar/cyl_configuration');
const sharedConfiguration = require('../example/miniprogram/shared/configuration');
const symbolsByTheme = require('../example/miniprogram/shared/symbols');
const localization = require('../example/miniprogram/shared/localization');

const CYL_PLUS_BUTTON = {
  CYLTabBarItemTitle: 'Post',
  CYLTabBarItemImage: 'system:plus.circle',
  CYLTabBarItemIdentifier: 'publish',
  CYLTabBarItemPageIdentifier: 'publish',
};

test('the shared configuration: tabs, platforms, page identifiers and localization', () => {
  const model = reader.cylReadConfiguration(sharedConfiguration, {
    symbolsByTheme,
    strings: localization['zh-Hans'],
  });
  assert.deepEqual(model.items.map((item) => item.identifier), ['home', 'discover', 'me']);
  assert.equal(model.items[1].pageIdentifier, 'web');
  assert.deepEqual(model.items[1].pageParameters, { url: 'https://github.com/ChenYilong/CYLTabBarController' });
  assert.equal(model.items[1].title, '发现');
  assert.equal(model.items[0].title, 'JSON');
  assert.equal(model.items[0].image, '/shared/skins/2.1.0/light/home@3x.png');
  assert.equal(model.items[0].selectedImage, '/shared/skins/2.1.0/light/home_selected@3x.png');
  assert.equal(model.context, 'CYLConfigurationDemo');
  assert.equal(model.styleType, 'default');
  assert.equal(model.themeIdentifier, 'light');
  assert.equal(model.items[0].selectedTitleColor, '#007AFF');
});

test('Dark Mode picks the dark skin, its colors and its icons', () => {
  const model = reader.cylReadConfiguration(sharedConfiguration, { systemTheme: 'dark', symbolsByTheme });
  assert.equal(model.isDark, true);
  assert.equal(model.themeIdentifier, 'dark');
  assert.equal(model.backgroundColor, '#1C1C1E');
  assert.equal(model.items[0].image, '/shared/skins/2.1.0/dark/home@3x.png');
  const forcedLight = reader.cylReadConfiguration(Object.assign({}, sharedConfiguration, {
    CYLTabBarControllerUserInterfaceStyle: 'light',
  }), { systemTheme: 'dark', symbolsByTheme });
  assert.equal(forcedLight.themeIdentifier, 'light');
});

test('a requested skin wins over the configured one; an unknown one is ignored', () => {
  const themes = Object.assign({}, sharedConfiguration.CYLTabBarControllerThemes, { christmas: {} });
  const configuration = Object.assign({}, sharedConfiguration, { CYLTabBarControllerThemes: themes });
  assert.equal(reader.cylReadConfiguration(configuration, { themeIdentifier: 'christmas' }).themeIdentifier, 'christmas');
  assert.equal(reader.cylReadConfiguration(configuration, { themeIdentifier: 'missing' }).themeIdentifier, 'light');
  const chosenDark = reader.cylReadConfiguration(configuration, { themeIdentifier: 'dark', systemTheme: 'light' });
  assert.equal(chosenDark.isDark, true);
  assert.equal(reader.cylReadConfiguration(configuration, { themeIdentifier: 'light', systemTheme: 'dark' }).isDark, false);
  assert.equal(reader.cylActiveThemeIdentifier({}, { b: {}, a: {} }, false, ''), 'a');
  assert.deepEqual(reader.cylThemes([{ CYLTabBarThemeIdentifier: 'x', CYLTabBarThemeValues: { k: 1 } }]), { x: { k: 1 } });
});

test('the plus button: index in the middle by default, raised, with or without a page', () => {
  const configuration = Object.assign({}, sharedConfiguration, { CYLTabBarControllerPlusButton: CYL_PLUS_BUTTON });
  const model = reader.cylReadConfiguration(configuration, { symbolsByTheme });
  assert.equal(model.plusButton.index, 1);
  assert.equal(model.plusButton.hasPage, true);
  assert.ok(model.plusButton.centerYMultiplier < 0.5);
  assert.equal(model.plusButton.image, '/shared/skins/2.1.0/light/plus@3x.png');
  const placed = reader.cylReadConfiguration(Object.assign({}, configuration, {
    CYLTabBarControllerPlusButton: Object.assign({}, CYL_PLUS_BUTTON, {
      CYLPlusButtonIndexInTabBar: 3,
      CYLTabBarItemPageIdentifier: '',
      CYLPlusButtonSize: '{60, 80}',
    }),
  }), {});
  assert.equal(placed.plusButton.index, 3);
  assert.equal(placed.plusButton.hasPage, false);
  assert.equal(placed.plusButton.width, 60);
  assert.equal(reader.cylReadConfiguration(sharedConfiguration, {}).plusButton, null);
});

test('appearance keys: insets, title offsets, colors, style type, tap animation, speed', () => {
  const model = reader.cylReadConfiguration({
    CYLTabBarControllerTabBarItemsAttributes: [{
      CYLTabBarItemIdentifier: 'a',
      CYLTabBarItemTitle: 'A',
      CYLTabBarItemImageInsets: [6, 0, -6, 0],
      CYLTabBarItemTitlePositionAdjustment: { horizontal: 0, vertical: -3 },
      CYLTabBarItemTitleColor: 'red',
      CYLTabBarItemSelectedBackgroundColor: '#FF000080',
    }],
    CYLTabBarControllerStyleType: 3,
    CYLTabBarControllerTabButtonTapAnimation: 'rotation',
    CYLTabBarControllerTabBarItemAnimationSpeed: 2,
  }, {});
  assert.equal(model.items[0].imageStyle, 'transform: translate(0px, 6px);');
  assert.equal(model.items[0].titleStyle, 'transform: translate(0px, -3px);');
  assert.equal(model.items[0].titleColor, '');
  assert.equal(model.items[0].selectedBackgroundColor, '#FF000080');
  assert.equal(model.styleType, 'liquidGlass');
  assert.equal(model.tapAnimation, 'rotation');
  assert.equal(model.animationDuration, 200);
  const invalid = reader.cylReadConfiguration({ CYLTabBarControllerStyleType: 'glass', CYLTabBarControllerTabButtonTapAnimation: 'spin' }, {});
  assert.equal(invalid.styleType, 'default');
  assert.equal(invalid.tapAnimation, 'none');
});

test('eligibility: platforms and minimum app version (B22, B24)', () => {
  assert.equal(reader.cylIsItemEligible({ CYLTabBarItemPlatforms: 'ios,android' }, {}), false);
  assert.equal(reader.cylIsItemEligible({ CYLTabBarItemPlatforms: ['ios', 'miniprogram'] }, {}), true);
  assert.equal(reader.cylIsItemEligible({ CYLTabBarItemMinimumAppVersion: '2.3.0' }, { appVersion: '2.2.9' }), false);
  assert.equal(reader.cylIsItemEligible({ CYLTabBarItemMinimumAppVersion: '2.3.0' }, { appVersion: '2.10' }), true);
  assert.equal(reader.cylIsItemEligible({ CYLTabBarItemMinimumAppVersion: '2.3.0' }, { appVersion: '' }), true);
  assert.equal(reader.cylCompareVersions('1.2.10', '1.10'), -1);
});

test('login-required identifiers, swipe flag, value parsers', () => {
  const model = reader.cylReadConfiguration({
    CYLTabBarControllerLoginRequiredTabBarItemIdentifiers: 'me, message',
    CYLTabBarControllerSwipeToSwitchTab: 'yes',
  }, {});
  assert.deepEqual(model.loginRequiredIdentifiers, ['me', 'message']);
  assert.equal(model.swipeToSwitchTab, true);
  assert.deepEqual(reader.cylInsets('{1, 2, 3, 4}'), { top: 1, left: 2, bottom: 3, right: 4 });
  assert.deepEqual(reader.cylInsets('bad'), { top: 0, left: 0, bottom: 0, right: 0 });
  assert.deepEqual(reader.cylOffset([0, -2]), { horizontal: 0, vertical: -2 });
  assert.equal(reader.cylSize('{0, 10}'), null);
  assert.equal(reader.cylColor('#abc'), '#abc');
  assert.equal(reader.cylColor('#abcd'), '');
  assert.equal(reader.cylImagePath('icons/a.png', { imageBasePath: '/assets/' }), '/assets/icons/a.png');
  assert.equal(reader.cylImagePath('https://x/a.png', { imageBasePath: '/assets' }), 'https://x/a.png');
  assert.equal(reader.cylImagePath('system:unknown', {}), '');
  assert.deepEqual(reader.cylReadConfiguration(null, null).items, []);
});

test('arrays handed over as array-like objects by the base library', () => {
  assert.deepEqual(reader.cylArray({ 0: 'me', 1: 'message' }), ['me', 'message']);
  assert.equal(reader.cylArray({ a: 1 }), null);
  const model = reader.cylReadConfiguration({
    CYLTabBarControllerTabBarItemsAttributes: { 0: { CYLTabBarItemIdentifier: 'a' }, 1: { CYLTabBarItemIdentifier: 'b' } },
    CYLTabBarControllerLoginRequiredTabBarItemIdentifiers: { 0: 'b' },
    CYLTabBarControllerImageInsets: { 0: 1, 1: 0, 2: -1, 3: 0 },
  }, {});
  assert.deepEqual(model.items.map((item) => item.identifier), ['a', 'b']);
  assert.deepEqual(model.loginRequiredIdentifiers, ['b']);
  assert.equal(model.items[0].imageStyle, 'transform: translate(0px, 1px);');
});

test('Lottie, generic animation and GIF keys; PAG and Rive fall back to the image (B29)', () => {
  const env = { animationBasePath: '/shared/lottie', isDark: false };
  const lottie = reader.cylLottie({
    CYLTabBarLottieURL: 'home.json',
    CYLTabBarLottieDarkURL: 'https://x/home_dark.json',
    CYLTabBarLottieSize: '{30, 30}',
    CYLTabBarLottieDarkColors: { '**.Fill 1': '#FFFFFF', bad: 'red' },
    CYLTabBarLottieLoopsWhenUnselected: true,
  }, env);
  assert.deepEqual(lottie, {
    path: '/shared/lottie/home.json',
    darkPath: 'https://x/home_dark.json',
    width: 30,
    height: 30,
    colors: null,
    darkColors: { '**.Fill 1': '#FFFFFF' },
    loopsWhenUnselected: true,
  });
  const generic = reader.cylLottie({ CYLTabBarAnimationFilePath: '/a/b.json#loop=1', CYLTabBarAnimationSize: [20, 24] }, env);
  assert.equal(generic.path, '/a/b.json');
  assert.equal(generic.height, 24);
  assert.equal(reader.cylLottie({ CYLTabBarAnimationURL: 'https://x/a.riv', CYLTabBarPAGFilePath: 'a.pag' }, env), null);
  assert.equal(reader.cylGIF({ CYLTabBarGIFFilePath: 'a.gif', CYLTabBarGIFDarkFilePath: 'b.gif' }, env, true), '/shared/lottie/b.gif');
  assert.equal(reader.cylGIF({ CYLTabBarAnimationURL: 'https://x/a.gif' }, env, false), 'https://x/a.gif');
});

test('title fonts, image URL size, icon rendering mode and colors (#787), plus button selection', () => {
  assert.equal(reader.cylFont(15), 'font-size: 15px; line-height: 18px;');
  assert.equal(reader.cylFont({ name: 'Menlo', size: 12, weight: 'semibold' }),
    'font-size: 12px; line-height: 14px; font-weight: 600; font-family: "Menlo";');
  assert.equal(reader.cylFont('bold:0'), '');
  assert.equal(reader.cylRenderingMode('Template'), 'template');
  assert.equal(reader.cylRenderingMode('tinted'), '');
  const model = reader.cylReadConfiguration({
    CYLTabBarControllerIconColor: '#111111',
    CYLTabBarControllerSelectedIconColor: '#222222',
    CYLTabBarControllerTabBarItemsAttributes: [
      { CYLTabBarItemIdentifier: 'symbol', CYLTabBarItemImage: 'system:house' },
      { CYLTabBarItemIdentifier: 'png', CYLTabBarItemImage: 'a.png' },
      { CYLTabBarItemIdentifier: 'template', CYLTabBarItemImage: 'a.png', CYLTabBarItemIconRenderingMode: 'template',
        CYLTabBarItemSelectedIconColor: '#333333' },
      { CYLTabBarItemIdentifier: 'original', CYLTabBarItemImage: 'system:house', CYLTabBarItemIconRenderingMode: 'original',
        CYLTabBarItemTitleFont: 'bold:12', CYLTabBarItemImageURLSize: '{24, 24}' },
    ],
    CYLTabBarControllerPlusButton: { CYLTabBarItemIdentifier: 'plus', CYLPlusButtonShowsSelection: 'true' },
  }, { symbols: { house: '/h.png' } });
  const [symbol, png, template, original] = model.items;
  assert.deepEqual([symbol.iconTint, symbol.selectedIconTint], ['#111111', '#222222']);
  assert.deepEqual([png.iconTint, png.selectedIconTint], ['', '']);
  assert.deepEqual([template.iconTint, template.selectedIconTint], ['#111111', '#333333']);
  assert.deepEqual([original.iconTint, original.titleFontStyle, original.imageSize],
    ['', 'font-size: 12px; line-height: 14px; font-weight: 700;', { width: 24, height: 24 }]);
  assert.equal(model.plusButton.showsSelection, true);
});
