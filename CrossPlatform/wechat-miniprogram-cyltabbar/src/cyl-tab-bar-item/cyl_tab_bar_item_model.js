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
  return `${color ? `color: ${color};` : ''}${font}`;
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
  // [EN] The animation's one color (the `tint` option): "title" takes this state's title color (the appearance's, then
  //      the title attributes'), like iOS and HarmonyOS; a color is used as it is; '' keeps the file's colors.
  // [CN] 动画的单一颜色（`tint` 选项）："title" 取当前状态的标题颜色（先取 appearance，再取标题属性），与 iOS 和鸿蒙一致；
  //      颜色原样使用；'' 保持文件自身的颜色。
  const tintOption = String(p.animationTint || '').trim();
  const animationTint = tintOption.toLowerCase() === 'title'
    ? (cylTextColor(appearance.titleTextAttributes) || cylTextColor(titleAttributes))
    : reader.cylColor(tintOption);
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
    animationTint,
    iconWidth: iconBox.width,
    iconHeight: iconBox.height,
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
    badgeClass: /^(breathe|scale|shake|bounce|scaleOnce)$/.test(String(p.badgeAnimation || ''))
      ? cylBadgeAnimationClass(p.badgeAnimation) : '',
    badgeStyle: `padding: ${badgeInset.top}px ${badgeInset.right}px ${badgeInset.bottom}px ${badgeInset.left}px;`
      // [EN] Moved by margins: the badge animations use transform. [CN] 用外边距移动：角标动画使用 transform。
      + (badgeOffset.horizontal || badgeOffset.vertical
        ? ` margin-left: ${badgeOffset.horizontal}px; margin-top: ${badgeOffset.vertical}px;` : '')
      + (badgeSize ? ` width: ${badgeSize.width}px; height: ${badgeSize.height}px; min-width: 0; padding: 0;` : '')
      + (reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)
        ? ` background-color: ${reader.cylColor(appearance.badgeBackgroundColor || p.badgeColor)};` : '')
      + cylTextStyle(badgeAttributes) + cylTextStyle(appearance.badgeTextAttributes),
    accessibilityLabel: String(p.label || title || '') + (badgeValue && badgeValue !== '•' ? `, ${badgeValue}` : ''),
  };
}

module.exports = { cylItemModel, cylAnimationType, cylTextStyle, cylStateKey };
