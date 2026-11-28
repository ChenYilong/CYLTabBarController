/**
 * [EN] The render model of cyl-tab-bar-item, the mini program counterpart of the iOS CYLFlatDesignTabBarItem (an
 *      animated icon and a title): its properties (named as on iOS) become the styles and nodes of the template.
 *      Pure functions without any wx API, tested in Node (test/cyl_tab_bar_item.test.js).
 * [CN] cyl-tab-bar-item 的渲染模型。cyl-tab-bar-item 对应 iOS 的 CYLFlatDesignTabBarItem（动画图标与标题）：把它的属性
 *      （与 iOS 同名）转为模板的样式与节点。纯函数，不调用 wx API，在 Node 中测试（test/cyl_tab_bar_item.test.js）。
 */
const reader = require('../cyl-tab-bar/cyl_configuration');
const { cylBadgeAnimationClass } = require('../cyl-tab-bar/cyl_debug');

// [EN] A mini program code package leaves out .pag, .riv and .svga files, so package copies are named *.pag.bin /
//      *.riv.bin / *.svga.bin.
// [CN] 小程序代码包不包含 .pag、.riv 与 .svga 文件，因此包内副本命名为 *.pag.bin / *.riv.bin / *.svga.bin。
const CYL_ANIMATION_TYPES = [
  ['lottie', /\.json(\?|#|$)/i],
  ['pag', /\.pag(\.bin)?(\?|#|$)/i],
  ['rive', /\.riv(\.bin)?(\?|#|$)/i],
  ['svga', /\.svga(\.bin)?(\?|#|$)/i],
];

/**
 * [EN] The animation library a file needs, by its type (.json Lottie, .pag PAG, .riv Rive, .svga SVGA); '' otherwise.
 * [CN] 按文件类型判断需要的动画库（.json 为 Lottie、.pag 为 PAG、.riv 为 Rive、.svga 为 SVGA）；否则返回 ''。
 */
function cylAnimationType(path) {
  const value = String(path || '').trim();
  const match = CYL_ANIMATION_TYPES.find(([, pattern]) => pattern.test(value));
  return match ? match[0] : '';
}

/**
 * [EN] NSAttributedString-like attributes as CSS: NSForegroundColorAttributeName / foregroundColor / color (a hex
 *      color) and NSFontAttributeName / font (a CYLTabBarItemTitleFont value: 15, "bold:15", "Menlo:12", {name, size,
 *      weight}); '' for nothing valid.
 * [CN] 把类似 NSAttributedString 的属性转为 CSS：NSForegroundColorAttributeName / foregroundColor / color（十六进制颜色）
 *      与 NSFontAttributeName / font（CYLTabBarItemTitleFont 的写法：15、"bold:15"、"Menlo:12"、{name, size, weight}）；
 *      没有有效值时返回 ''。
 */
function cylTextStyle(attributes) {
  if (!attributes || typeof attributes !== 'object') {
    return '';
  }
  const color = reader.cylColor(attributes.NSForegroundColorAttributeName || attributes.foregroundColor || attributes.color);
  const font = reader.cylFont(attributes.NSFontAttributeName !== undefined ? attributes.NSFontAttributeName : attributes.font);
  return `${cylDeclaration('color', color)}${font}`;
}

/**
 * [EN] One CSS declaration, "name: value;", or '' without a value. [CN] 一条 CSS 声明「name: value;」，没有值时为 ''。
 */
function cylDeclaration(name, value) {
  return value ? `${name}: ${value};` : '';
}

/**
 * [EN] The title color of text attributes ({color} / foregroundColor / NSForegroundColorAttributeName); '' without one.
 * [CN] 文本属性中的标题颜色（{color} / foregroundColor / NSForegroundColorAttributeName）；没有时返回 ''。
 */
function cylTextColor(attributes) {
  if (!attributes || typeof attributes !== 'object') {
    return '';
  }
  return reader.cylColor(attributes.NSForegroundColorAttributeName || attributes.foregroundColor || attributes.color);
}

/**
 * [EN] The attributes for a state ("normal" / "selected", or UIControlState 0 / 4) from {normal, selected}.
 * [CN] 从 {normal, selected} 中取出某个状态（"normal" / "selected"，或 UIControlState 0 / 4）的属性。
 */
function cylStateKey(state) {
  return state === 4 || state === 'selected' ? 'selected' : 'normal';
}

/**
 * [EN] The appearance of the selected / normal state from a UITabBarAppearance-like standardAppearance:
 *      {backgroundColor, stackedLayoutAppearance: {normal: {titleTextAttributes, iconColor, badgeBackgroundColor,
 *      badgeTextAttributes}, selected: {…}}}.
 * [CN] 从类似 UITabBarAppearance 的 standardAppearance 中取出选中 / 普通状态的外观：
 *      {backgroundColor, stackedLayoutAppearance: {normal: {titleTextAttributes, iconColor, badgeBackgroundColor,
 *      badgeTextAttributes}, selected: {…}}}。
 */
function cylAppearanceState(appearance, selected) {
  const layout = appearance?.stackedLayoutAppearance;
  return layout?.[selected ? 'selected' : 'normal'] || {};
}

/**
 * [EN] The text attributes of a state, falling back to the normal state's when selected; null without any.
 * [CN] 某个状态的文本属性，选中时回退到普通状态的属性；都没有时为 null。
 */
function cylStateAttributes(attributes, stateKey, selected) {
  return attributes?.[stateKey] || (selected && attributes?.normal) || null;
}

/**
 * [EN] The title color of one state, the icon color "title" follows: the appearance's, then the title attributes' of that
 *      state only (no fallback to the normal state: cyl-animated-item does that for "title", and a fixed tint must not).
 * [CN] 某一状态的标题颜色，即 "title" 所跟随的图标颜色：先取 appearance 的，再取该状态自己的标题属性（不回退到普通状态：
 *      "title" 的回退由 cyl-animated-item 完成，固定着色不应回退）。
 */
function cylStateTitleColor(p, selected) {
  return cylTextColor(cylAppearanceState(p.standardAppearance, selected).titleTextAttributes)
    || cylTextColor(p.titleTextAttributes?.[selected ? 'selected' : 'normal']);
}

/**
 * [EN] The title's style: its offset, then the title attributes and the appearance's. [CN] 标题样式：偏移，然后是标题属性与 appearance 的属性。
 */
function cylTitleStyle(offset, titleAttributes, appearance) {
  return (offset.horizontal || offset.vertical
    ? `transform: translate(${offset.horizontal}px, ${offset.vertical}px);` : '')
    + cylTextStyle(titleAttributes) + cylTextStyle(appearance.titleTextAttributes);
}

/**
 * [EN] The badge's style: content insets, offset (by margins: the badge animations use transform), size, color and
 *      text attributes. [CN] 角标样式：内容边距、偏移（用外边距：角标动画使用 transform）、尺寸、颜色与文本属性。
 */
function cylBadgeStyle(p, appearance, badge) {
  const parts = cylBadgeStyleParts(p, appearance, badge);
  return parts.padding + parts.host + parts.size + parts.look;
}

/**
 * [EN] The badge's style in two places (cyl-badge, docs/Animated-Item-Badge-CrossPlatform.md, phase 1): `host` is the offset (margins), which stays on the node
 *      the item positions; `look` (padding, size, color, text) goes to cyl-badge as `style-text`. Their concatenation is `cylBadgeStyle`, unchanged.
 * [CN] 角标样式分在两个位置（cyl-badge，docs/Animated-Item-Badge-CrossPlatform.md，阶段 1）：`host` 是偏移（外边距），留在 item 定位的节点上；
 *      `look`（内边距、尺寸、颜色、文字）作为 `style-text` 交给 cyl-badge。它们连起来就是 `cylBadgeStyle`，没有改变。
 */
function cylBadgeStyleParts(p, appearance, badge) {
  const { inset, offset, size, attributes } = badge;
  const padding = `padding: ${inset.top}px ${inset.right}px ${inset.bottom}px ${inset.left}px;`;
  const host = offset.horizontal || offset.vertical ? ` margin-left: ${offset.horizontal}px; margin-top: ${offset.vertical}px;` : '';
  const sizeStyle = size ? ` width: ${size.width}px; height: ${size.height}px; min-width: 0; padding: 0;` : '';
  const look = (reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)
    ? ` background-color: ${reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)};` : '')
    + cylTextStyle(attributes) + cylTextStyle(appearance.badgeTextAttributes);
  return { padding, host, size: sizeStyle, look };
}

/**
 * [EN] The icon tint of one state (appearance color first, then the item's own), so cyl-animated-item can keep both static
 *      images mounted, each with its own tint, and a selection change only toggles which one is visible.
 * [CN] 某一状态下的图标着色（先取 appearance 颜色，再取 Item 自己的），使 cyl-animated-item 可以同时保持两张静态图片挂载、各用
 *      自己的着色，选中变化只切换哪一张可见。
 */
function cylStateIconTint(p, selected) {
  return reader.cylColor(cylAppearanceState(p.standardAppearance, selected).iconColor)
    || reader.cylColor(selected ? p.selectedIconTint : p.iconTint);
}

/**
 * [EN] The text of a property: '' when it is undefined or null.
 * [CN] 属性的文本：undefined 或 null 时为 ''。
 */
function cylItemText(value) {
  return String(value === undefined || value === null ? '' : value);
}

/**
 * [EN] The badge's content inset: the default one when the property is not set (undefined, null or '').
 * [CN] 角标的内边距：属性未设置（undefined、null 或 ''）时为默认值。
 */
function cylItemBadgeInset(value) {
  if (value === undefined || value === null || value === '') {
    return { top: 1, left: 6, bottom: 1, right: 6 };
  }
  return reader.cylInsets(value);
}

/**
 * [EN] The render model from the component's properties.
 * [CN] 根据组件属性生成渲染模型。
 */
function cylItemModel(p) {
  const selected = Boolean(p.selected);
  const stateKey = selected ? 'selected' : 'normal';
  const appearance = cylAppearanceState(p.standardAppearance, selected);
  const imageInsets = reader.cylInsets(p.imageInsets);
  const imageOffset = reader.cylOffset(p.imagePositionAdjustment);
  const titleOffset = reader.cylOffset(p.titlePositionAdjustment);
  const badgeOffset = reader.cylOffset(p.badgePositionAdjustment);
  const badgeInset = cylItemBadgeInset(p.badgeContentInset);
  const badgeSize = reader.cylSize(p.badgeSize);
  const animationPath = String(p.lottieURL || p.lottieFilePath || p.animationPath || '');
  const animationSize = reader.cylSize(p.lottieSizeValue) || reader.cylSize(p.animationSize);
  const imageSize = reader.cylSize(p.imageSize);
  const image = (selected && p.selectedImage) || p.image || '';
  const title = cylItemText(p.title);
  const iconBox = animationSize || imageSize || { width: 28, height: 28 };
  const imageMoveX = imageOffset.horizontal + (imageInsets.left - imageInsets.right) / 2;
  const imageMoveY = imageOffset.vertical + (imageInsets.top - imageInsets.bottom) / 2;
  const iconTint = reader.cylColor(appearance.iconColor) || reader.cylColor(selected ? p.selectedIconTint : p.iconTint);
  const titleAttributes = cylStateAttributes(p.titleTextAttributes, stateKey, selected);
  const badgeAttributes = cylStateAttributes(p.badgeTextAttributes, stateKey, selected);
  const badgeValue = cylItemText(p.badgeValue);
  const showsBadge = badgeValue !== '' || Boolean(badgeSize);
  const background = reader.cylColor(selected ? p.selectedBackgroundColor : p.backgroundColor);
  const hasImage = Boolean(image || animationPath);
  const centered = Boolean(p.layoutCentered) && (!hasImage || !title);
  return {
    selected,
    enabled: p.enabled !== false,
    title,
    image,
    // [EN] Both static images, whichever state: they go to cyl-animated-item as `image` and `selectedImage`, which keeps both
    //      mounted (selectedStillImage is '' without an own selected image). [CN] 两张静态图片，与状态无关：作为 `image` 与
    //      `selectedImage` 传给 cyl-animated-item，使两者都保持挂载（没有自己的选中图片时 selectedStillImage 为 ''）。
    normalImage: p.image || '',
    selectedStillImage: p.selectedImage || '',
    normalStillTint: cylStateIconTint(p, false),
    selectedStillTint: cylStateIconTint(p, true),
    animationPath,
    animationType: cylAnimationType(animationPath),
    iconTint,
    // [EN] The tab's configured tint options and its title colors go to cyl-animated-item unresolved: the component is the only
    //      resolver (cylAnimatedItemAnimationTint). [CN] Tab 配置的着色选项与标题颜色原样交给 cyl-animated-item：只有该组件做解析。
    animationTint: cylItemText(p.animationTint).trim(),
    animationDarkTint: cylItemText(p.animationDarkTint).trim(),
    animationRenderingMode: String(p.animationRenderingMode || ''),
    animationIconTint: cylStateTitleColor(p, false),
    animationSelectedIconTint: cylStateTitleColor(p, true),
    iconWidth: iconBox.width,
    iconHeight: iconBox.height,
    centered,
    itemStyle: `${cylDeclaration('background-color', background)}${p.enabled === false ? 'opacity: 0.4;' : ''}`,
    iconBoxStyle: `width: ${iconBox.width}px; height: ${iconBox.height}px;`
      + (imageMoveX || imageMoveY ? ` transform: translate(${imageMoveX}px, ${imageMoveY}px);` : ''),
    titleStyle: cylTitleStyle(titleOffset, titleAttributes, appearance),
    showsBadge,
    badgeIsDot: badgeValue === '•' || (badgeValue === '' && Boolean(badgeSize)),
    badgeText: badgeValue === '•' ? '' : badgeValue,
    badgeClass: /^(breathe|scale|shake|bounce|scaleOnce)$/.test(String(p.badgeAnimation || ''))
      ? cylBadgeAnimationClass(p.badgeAnimation) : '',
    badgeStyle: cylBadgeStyle(p, appearance, { inset: badgeInset, offset: badgeOffset, size: badgeSize, attributes: badgeAttributes }),
    badgeHostStyle: cylBadgeStyleParts(p, appearance, { inset: badgeInset, offset: badgeOffset, size: badgeSize, attributes: badgeAttributes }).host,
    badgeLookStyle: (() => { const parts = cylBadgeStyleParts(p, appearance, { inset: badgeInset, offset: badgeOffset, size: badgeSize, attributes: badgeAttributes }); return parts.padding + parts.size + parts.look; })(),
    accessibilityLabel: String(p.label || title || '') + (badgeValue && badgeValue !== '•' ? `, ${badgeValue}` : ''),
  };
}

module.exports = { cylItemModel, cylAnimationType, cylTextStyle, cylStateKey };
