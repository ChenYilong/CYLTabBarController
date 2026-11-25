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
  assert.deepEqual(['a.json', 'a.pag', 'a.riv', 'a.svga', 'a.svga.bin', 'a.png'].map(cylAnimationType), ['lottie', 'pag', 'rive', 'svga', 'svga', '']);
});

test('badges: value, dot, color, size, content inset, position, text attributes', () => {
  const model = cylItemModel({ badgeValue: '8', badgeColor: '#34C759', badgeContentInset: '{2, 8, 2, 8}',
    badgePositionAdjustment: '{4, -2}', badgeTextAttributes: { normal: { color: '#FFFF00', font: 'bold:9' } } });
  assert.equal(model.showsBadge, true);
  assert.equal(model.badgeText, '8');
  assert.match(model.badgeStyle, /padding: 2px 8px 2px 8px;/);
  // [EN] Moved by margins, so the badge animations can use transform. [CN] 用外边距移动，角标动画可以使用 transform。
  assert.match(model.badgeStyle, /margin-left: 4px; margin-top: -2px;/);
  assert.doesNotMatch(model.badgeStyle, /transform/);
  assert.equal(model.badgeClass, '');
  assert.equal(cylItemModel({ badgeValue: '8', badgeAnimation: 'bounce' }).badgeClass, 'cyl-badge-bounce');
  assert.equal(cylItemModel({ badgeValue: '•', badgeAnimation: 'breathe' }).badgeClass, 'cyl-badge-breathe');
  assert.equal(cylItemModel({ badgeValue: '8', badgeAnimation: 'unknown' }).badgeClass, '');
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

test('badge debugging switch (cyl_debug.js): off by default, on leaves out the animation class', () => {
  const { CYL_BADGE_ANIMATION_DISABLED, cylBadgeAnimationClass } = require('../src/cyl-tab-bar/cyl_debug');
  assert.equal(CYL_BADGE_ANIMATION_DISABLED, false, 'never commit the badge debugging switch on');
  assert.equal(cylItemModel({ badgeValue: '9', badgeAnimation: 'bounce' }).badgeClass, 'cyl-badge-bounce');
  assert.equal(cylBadgeAnimationClass('bounce', true), '');
  assert.equal(cylBadgeAnimationClass('', false), '');
});

test('cyl-tab-bar-item: the icon box size goes to cyl-animated-item (iconWidth / iconHeight)', () => {
  const sized = cylItemModel({ title: 'Home', image: 'a.png', imageSize: '{30, 20}' })
  assert.equal(sized.iconWidth, 30)
  assert.equal(sized.iconHeight, 20)
  const plain = cylItemModel({ title: 'Home', image: 'a.png' })
  assert.equal(plain.iconWidth, 28)
  assert.equal(plain.iconHeight, 28)
})

test('animation tint: the item hands the options and its title colors over, cyl-animated-item resolves them', () => {
  const titleTextAttributes = { normal: { color: '#8E8E93' }, selected: { color: '#007AFF' } };
  const standardAppearance = { stackedLayoutAppearance: { selected: { titleTextAttributes: { color: '#FF3B30' } } } };
  const { cylAnimatedItemAnimationTint: resolve } = require('../src/cyl-animated-item/cyl_animated_item_model');
  const resolved = (props) => {
    const m = cylItemModel({ titleTextAttributes, ...props });
    return resolve({ animationTint: m.animationTint, animationDarkTint: m.animationDarkTint, selected: m.selected,
      isDark: Boolean(props.isDark), iconTint: m.animationIconTint, selectedIconTint: m.animationSelectedIconTint });
  };
  assert.equal(resolved({ animationTint: 'title' }), '#8E8E93');
  assert.equal(resolved({ animationTint: 'title', selected: true }), '#007AFF');
  assert.equal(resolved({ animationTint: 'title', selected: true, standardAppearance }), '#FF3B30');
  assert.equal(resolved({ animationTint: 'Title', selected: true, standardAppearance }), '', '"title" is case-sensitive, as on every platform');
  assert.equal(resolved({ animationTint: 'title', selected: true, titleTextAttributes: { normal: { color: '#8E8E93' } } }), '#8E8E93', 'no selected title color: the normal one');
  assert.equal(resolved({ animationTint: 'title', titleTextAttributes: undefined }), '', 'no title color at all: no tint');
  // a fixed tint on the unselected tab; the selected tab takes the title's selected color
  assert.equal(resolved({ animationTint: '#34C759' }), '#34C759');
  assert.equal(resolved({ animationTint: '#34C759', selected: true }), '#007AFF');
  assert.equal(resolved({ animationTint: '#34C759', selected: true, titleTextAttributes: { normal: { color: '#8E8E93' } } }), '#34C759');
  assert.equal(resolved({ animationTint: '#34C759', animationDarkTint: '#112233', isDark: true }), '#112233');
  assert.equal(resolved({ animationTint: 'red' }), '');
  assert.equal(resolved({}), '');
  const m = cylItemModel({ animationTint: ' #34C759 ', animationDarkTint: '#112233', titleTextAttributes, selected: true });
  assert.deepEqual([m.animationTint, m.animationDarkTint, m.animationIconTint, m.animationSelectedIconTint], ['#34C759', '#112233', '#8E8E93', '#007AFF']);
});

test('cyl-tab-bar-item binds the unresolved options and the dark style to cyl-animated-item', () => {
  const fs = require('node:fs');
  const path = require('node:path');
  const template = fs.readFileSync(path.join(__dirname, '../src/cyl-tab-bar-item/index.wxml'), 'utf8');
  for (const attribute of ['animation-tint="{{m.animationTint}}"', 'animation-dark-tint="{{m.animationDarkTint}}"',
    'animation-icon-tint="{{m.animationIconTint}}"', 'animation-selected-icon-tint="{{m.animationSelectedIconTint}}"',
    "user-interface-style=\"{{isDark ? 'dark' : 'light'}}\""]) {
    assert.ok(template.includes(attribute), attribute);
  }
});

test('cyl-tab-bar passes every icon color option to cyl-tab-bar-item (B28)', () => {
  // [EN] The models are tested above, but a value the tab bar computes reaches the item only through the template: the
  //      tint option was computed and never bound, so Rive icons kept their own colors (B28, docs/Animated-Item.md).
  // [CN] 上面测试的是模型，但 TabBar 计算出的值只能通过模板传给 Tab：tint 选项被计算却从未绑定，Rive 图标保持了自身颜色（B28）。
  const fs = require('node:fs');
  const path = require('node:path');
  const template = fs.readFileSync(path.join(__dirname, '../src/cyl-tab-bar/index.wxml'), 'utf8');
  const item = template.slice(template.indexOf('<cyl-tab-bar-item'), template.indexOf('/>', template.indexOf('<cyl-tab-bar-item')));
  for (const [attribute, key] of [['animation-tint', 'animationTint'], ['animation-dark-tint', 'animationDarkTint'], ['icon-tint', 'iconTint'],
    ['selected-icon-tint', 'selectedIconTint'], ['animation-colors', 'animationColors']]) {
    assert.ok(item.includes(`${attribute}="{{item.item.${key}}}"`), `${attribute} is not bound`);
  }
});
