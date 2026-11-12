/**
 * [EN] The render model of cyl-tab-bar-item, the mini program counterpart of the iOS CYLFlatDesignTabBarItem (an
 *      animated icon and a title): its properties (named as on iOS) become the styles and nodes of the template.
 *      Pure functions without any wx API, tested in Node (test/cyl_tab_bar_item.test.js).
 * [CN] cyl-tab-bar-item 的渲染模型。cyl-tab-bar-item 对应 iOS 的 CYLFlatDesignTabBarItem（动画图标与标题）：把它的属性
 *      （与 iOS 同名）转为模板的样式与节点。纯函数，不调用 wx API，在 Node 中测试（test/cyl_tab_bar_item.test.js）。
 */
const reader = require('../cyl-tab-bar/cyl_configuration');

const CYL_ANIMATION_TYPES = [
  ['lottie', /\.json(\?|#|$)/i],
  ['pag', /\.pag(\?|#|$)/i],
  ['rive', /\.riv(\?|#|$)/i],
];

/**
 * [EN] The animation library a file needs, by its type (.json Lottie, .pag PAG, .riv Rive); '' otherwise.
 * [CN] 按文件类型判断需要的动画库（.json 为 Lottie、.pag 为 PAG、.riv 为 Rive）；否则返回 ''。
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
  return `${color ? `color: ${color};` : ''}${font}`;
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
  const layout = appearance && appearance.stackedLayoutAppearance;
  return (layout && layout[selected ? 'selected' : 'normal']) || {};
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
  const badgeInset = p.badgeContentInset === undefined || p.badgeContentInset === null || p.badgeContentInset === ''
    ? { top: 1, left: 6, bottom: 1, right: 6 }
    : reader.cylInsets(p.badgeContentInset);
  const badgeSize = reader.cylSize(p.badgeSize);
  const animationPath = String(p.lottieURL || p.lottieFilePath || p.animationPath || '');
  const animationSize = reader.cylSize(p.lottieSizeValue) || reader.cylSize(p.animationSize);
  const imageSize = reader.cylSize(p.imageSize);
  const image = selected ? (p.selectedImage || p.image || '') : (p.image || '');
  const title = String(p.title === undefined || p.title === null ? '' : p.title);
  const iconBox = animationSize || imageSize || { width: 28, height: 28 };
  const imageMoveX = imageOffset.horizontal + (imageInsets.left - imageInsets.right) / 2;
  const imageMoveY = imageOffset.vertical + (imageInsets.top - imageInsets.bottom) / 2;
  const iconTint = reader.cylColor(appearance.iconColor) || reader.cylColor(selected ? p.selectedIconTint : p.iconTint);
  const titleAttributes = (p.titleTextAttributes && p.titleTextAttributes[stateKey])
    || (selected && p.titleTextAttributes && p.titleTextAttributes.normal) || null;
  const badgeAttributes = (p.badgeTextAttributes && p.badgeTextAttributes[stateKey])
    || (selected && p.badgeTextAttributes && p.badgeTextAttributes.normal) || null;
  const badgeValue = String(p.badgeValue === undefined || p.badgeValue === null ? '' : p.badgeValue);
  const showsBadge = badgeValue !== '' || Boolean(badgeSize);
  const background = reader.cylColor(selected ? p.selectedBackgroundColor : p.backgroundColor);
  const hasImage = Boolean(image || animationPath);
  const centered = Boolean(p.layoutCentered) && (!hasImage || !title);
  return {
    selected,
    enabled: p.enabled !== false,
    title,
    image,
    animationPath,
    animationType: cylAnimationType(animationPath),
    iconTint,
    centered,
    itemStyle: `${background ? `background-color: ${background};` : ''}${p.enabled === false ? 'opacity: 0.4;' : ''}`,
    iconBoxStyle: `width: ${iconBox.width}px; height: ${iconBox.height}px;`
      + (imageMoveX || imageMoveY ? ` transform: translate(${imageMoveX}px, ${imageMoveY}px);` : ''),
    titleStyle: (titleOffset.horizontal || titleOffset.vertical
      ? `transform: translate(${titleOffset.horizontal}px, ${titleOffset.vertical}px);` : '')
      + cylTextStyle(titleAttributes) + cylTextStyle(appearance.titleTextAttributes),
    showsBadge,
    badgeIsDot: badgeValue === '•' || (badgeValue === '' && Boolean(badgeSize)),
    badgeText: badgeValue === '•' ? '' : badgeValue,
    badgeStyle: `padding: ${badgeInset.top}px ${badgeInset.right}px ${badgeInset.bottom}px ${badgeInset.left}px;`
      + (badgeOffset.horizontal || badgeOffset.vertical
        ? ` transform: translate(${badgeOffset.horizontal}px, ${badgeOffset.vertical}px);` : '')
      + (badgeSize ? ` width: ${badgeSize.width}px; height: ${badgeSize.height}px; min-width: 0; padding: 0;` : '')
      + (reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)
        ? ` background-color: ${reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)};` : '')
      + cylTextStyle(badgeAttributes) + cylTextStyle(appearance.badgeTextAttributes),
    accessibilityLabel: String(p.label || title || '') + (badgeValue && badgeValue !== '•' ? `, ${badgeValue}` : ''),
  };
}

module.exports = { cylItemModel, cylAnimationType, cylTextStyle, cylStateKey };
