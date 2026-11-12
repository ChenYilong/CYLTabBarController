/**
 * [EN] Tests of cyl-tab-bar-item's render model (src/cyl-tab-bar-item/cyl_tab_bar_item_model.js), one per group of
 *      the iOS CYLFlatDesignTabBarItem API. Run: `npm test`.
 * [CN] cyl-tab-bar-item 渲染模型（src/cyl-tab-bar-item/cyl_tab_bar_item_model.js）的测试，每组对应 iOS
 *      CYLFlatDesignTabBarItem 的一组 API。运行：`npm test`。
 */
const test = require('node:test');
const assert = require('node:assert/strict');
const { cylItemModel, cylAnimationType, cylTextStyle, cylStateKey } = require('../src/cyl-tab-bar-item/cyl_tab_bar_item_model');

test('title, image, selectedImage and the selected state', () => {
  assert.equal(cylItemModel({ title: 'Home', image: 'a.png', selectedImage: 'b.png' }).image, 'a.png');
  assert.equal(cylItemModel({ title: 'Home', image: 'a.png', selectedImage: 'b.png', selected: true }).image, 'b.png');
  assert.equal(cylItemModel({ image: 'a.png', selected: true }).image, 'a.png');
});

test('lottieFilePath, lottieURL, lottieSizeValue and the animation type', () => {
  const model = cylItemModel({ lottieFilePath: '/a.json', lottieSizeValue: '{36, 30}' });
  assert.equal(model.animationType, 'lottie');
  assert.equal(model.iconBoxStyle, 'width: 36px; height: 30px;');
  assert.equal(cylItemModel({ lottieURL: 'https://x/a.json', lottieFilePath: '/b.json' }).animationPath, 'https://x/a.json');
  assert.deepEqual(['a.json', 'a.pag', 'a.riv', 'a.png'].map(cylAnimationType), ['lottie', 'pag', 'rive', '']);
});

test('badges: value, dot, color, size, content inset, position, text attributes', () => {
  const model = cylItemModel({ badgeValue: '8', badgeColor: '#34C759', badgeContentInset: '{2, 8, 2, 8}',
    badgePositionAdjustment: '{4, -2}', badgeTextAttributes: { normal: { color: '#FFFF00', font: 'bold:9' } } });
  assert.equal(model.showsBadge, true);
  assert.equal(model.badgeText, '8');
  assert.match(model.badgeStyle, /padding: 2px 8px 2px 8px;/);
  assert.match(model.badgeStyle, /translate\(4px, -2px\)/);
  assert.match(model.badgeStyle, /background-color: #34C759;/);
  assert.match(model.badgeStyle, /color: #FFFF00;font-size: 9px/);
  assert.equal(cylItemModel({ badgeValue: '•' }).badgeIsDot, true);
  const sized = cylItemModel({ badgeSize: '{10, 10}' });
  assert.equal(sized.showsBadge && sized.badgeIsDot, true);
  assert.equal(cylItemModel({}).showsBadge, false);
  assert.equal(cylItemModel({ badgeValue: '' }).badgeStyle.startsWith('padding: 1px 6px 1px 6px;'), true);
});

test('title text attributes per state, positions, insets, layoutCentered, backgrounds, enabled', () => {
  const attributes = { normal: { color: '#8E8E93' }, selected: { NSForegroundColorAttributeName: '#FF2D55', NSFontAttributeName: 'bold:12' } };
  assert.equal(cylItemModel({ title: 'A', titleTextAttributes: attributes }).titleStyle, 'color: #8E8E93;');
  assert.equal(cylItemModel({ title: 'A', selected: true, titleTextAttributes: attributes }).titleStyle,
    'color: #FF2D55;font-size: 12px; line-height: 14px; font-weight: 700;');
  assert.equal(cylItemModel({ title: 'A', titlePositionAdjustment: '{0, 4}' }).titleStyle, 'transform: translate(0px, 4px);');
  assert.match(cylItemModel({ image: 'a', imagePositionAdjustment: '{0, -4}', imageInsets: '{6, 0, -6, 0}' }).iconBoxStyle,
    /translate\(0px, 2px\)/);
  assert.equal(cylItemModel({ title: 'A', layoutCentered: true }).centered, true);
  assert.equal(cylItemModel({ title: 'A', image: 'a', layoutCentered: true }).centered, false);
  assert.equal(cylItemModel({ selected: true, backgroundColor: '#111111', selectedBackgroundColor: '#222222' }).itemStyle,
    'background-color: #222222;');
  assert.equal(cylItemModel({ enabled: false }).enabled, false);
  assert.match(cylItemModel({ enabled: false }).itemStyle, /opacity: 0.4/);
});

test('standardAppearance while selected, tint, accessibility label, helpers', () => {
  const appearance = { stackedLayoutAppearance: { selected: { iconColor: '#AF52DE', titleTextAttributes: { color: '#AF52DE' },
    badgeBackgroundColor: '#AF52DE' } } };
  const model = cylItemModel({ title: 'A', image: 'a', selected: true, standardAppearance: appearance, badgeValue: '2' });
  assert.equal(model.iconTint, '#AF52DE');
  assert.match(model.titleStyle, /color: #AF52DE;/);
  assert.match(model.badgeStyle, /background-color: #AF52DE;/);
  assert.equal(cylItemModel({ title: 'A', standardAppearance: appearance }).iconTint, '');
  assert.equal(cylItemModel({ image: 'a', iconTint: '#111111', selectedIconTint: '#222222', selected: true }).iconTint, '#222222');
  assert.equal(model.accessibilityLabel, 'A, 2');
  assert.equal(cylTextStyle(null), '');
  assert.deepEqual([cylStateKey(4), cylStateKey('selected'), cylStateKey(0)], ['selected', 'selected', 'normal']);
});
