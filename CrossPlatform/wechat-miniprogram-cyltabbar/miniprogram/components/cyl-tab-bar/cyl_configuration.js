/**
 * [EN] Reads a CYLTabBarController configuration (the keys of docs/Configuration-File.md) into the plain data the
 *      cyl-tab-bar component renders. Pure functions without any wx API, so Node tests can run them
 *      (test/cyl_configuration.test.js). Values are validated as the iOS library does: an invalid value is dropped
 *      and the default is used.
 * [CN] 把 CYLTabBarController 配置（docs/Configuration-File.md 中的键）读取为 cyl-tab-bar 组件渲染所需的普通数据。
 *      纯函数，不调用任何 wx API，因此可以在 Node 中测试（test/cyl_configuration.test.js）。取值按 iOS 库的方式校验：
 *      无效值被丢弃，使用默认值。
 */

/**
 * [EN] The platform names this component answers to in `CYLTabBarItemPlatforms`.
 * [CN] 本组件在 `CYLTabBarItemPlatforms` 中认可的平台名称。
 */
const CYL_PLATFORM_NAMES = ['miniprogram', 'wechat', 'weixin', 'wechat-miniprogram', 'all'];

/**
 * [EN] Style types of `CYLTabBarControllerStyleType`, by name and by number (CYLTabBarStyleType).
 * [CN] `CYLTabBarControllerStyleType` 的样式，按名称与数字（CYLTabBarStyleType）。
 */
const CYL_STYLE_TYPES = ['default', 'system', 'flatDesign', 'liquidGlass'];

/**
 * [EN] Tap animations of `CYLTabBarControllerTabButtonTapAnimation`.
 * [CN] `CYLTabBarControllerTabButtonTapAnimation` 的点击动画。
 */
const CYL_TAP_ANIMATIONS = ['none', 'scale', 'zoomIn', 'bounce', 'bounceWithFireworks', 'rotation', 'flip', 'fume'];

/**
 * [EN] Theme value keys the component applies to the whole bar.
 * [CN] 组件应用到整个 TabBar 的皮肤取值键。
 */
const CYL_THEME_KEYS = [
  'CYLTabBarBackgroundColor',
  'CYLTabBarItemTitleColor',
  'CYLTabBarItemSelectedTitleColor',
  'CYLTabBarItemBackgroundColor',
  'CYLTabBarItemSelectedBackgroundColor',
  'CYLTabBarItemIconColor',
  'CYLTabBarItemSelectedIconColor',
];

const CYL_COLOR_PATTERN = /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

/**
 * [EN] A color string as CSS, or '' when it is not "#RGB", "#RRGGBB" or "#RRGGBBAA" (B19).
 * [CN] 颜色字符串转为 CSS；不是 "#RGB"、"#RRGGBB" 或 "#RRGGBBAA" 时返回 ''（B19）。
 */
function cylColor(value) {
  return typeof value === 'string' && CYL_COLOR_PATTERN.test(value.trim()) ? value.trim() : '';
}

/**
 * [EN] An array from an array or an array-like object ({"0": …, "1": …}): the base library may hand an array nested
 *      in an Object property to a component as such an object. null for anything else.
 * [CN] 从数组或类数组对象（{"0": …, "1": …}）得到数组：基础库可能把 Object 属性中嵌套的数组以这种对象传给组件。
 *      其他值返回 null。
 */
function cylArray(value) {
  if (Array.isArray(value)) {
    return value;
  }
  if (!value || typeof value !== 'object') {
    return null;
  }
  const keys = Object.keys(value);
  if (keys.length === 0 || !keys.every((key) => /^\d+$/.test(key))) {
    return null;
  }
  return keys.map(Number).sort((a, b) => a - b).map((key) => value[key]);
}

/**
 * [EN] Numbers from "{a, b, …}", "a, b", [a, b] or a dictionary with the given names; null when invalid.
 * [CN] 从 "{a, b, …}"、"a, b"、[a, b] 或带指定名称的字典中取出数字；无效时返回 null。
 */
function cylNumbers(value, names) {
  let list = cylArray(value);
  if (!list && typeof value === 'string') {
    list = value.replace(/[{}\[\]\s]/g, '').split(',').filter((part) => part !== '');
  } else if (!list && value && typeof value === 'object') {
    list = names.map((name) => value[name]);
  }
  if (!list || list.length !== names.length) {
    return null;
  }
  const numbers = list.map(Number);
  return numbers.every(Number.isFinite) ? numbers : null;
}

/**
 * [EN] UIEdgeInsets as {top, left, bottom, right}; zero when invalid.
 * [CN] UIEdgeInsets，返回 {top, left, bottom, right}；无效时为 0。
 */
function cylInsets(value) {
  const numbers = cylNumbers(value, ['top', 'left', 'bottom', 'right']) || [0, 0, 0, 0];
  return { top: numbers[0], left: numbers[1], bottom: numbers[2], right: numbers[3] };
}

/**
 * [EN] UIOffset as {horizontal, vertical}; zero when invalid.
 * [CN] UIOffset，返回 {horizontal, vertical}；无效时为 0。
 */
function cylOffset(value) {
  const numbers = cylNumbers(value, ['horizontal', 'vertical']) || [0, 0];
  return { horizontal: numbers[0], vertical: numbers[1] };
}

/**
 * [EN] CGSize as {width, height}; null when invalid or not above 0.
 * [CN] CGSize，返回 {width, height}；无效或不大于 0 时返回 null。
 */
function cylSize(value) {
  const numbers = cylNumbers(value, ['width', 'height']);
  return numbers && numbers[0] > 0 && numbers[1] > 0 ? { width: numbers[0], height: numbers[1] } : null;
}

/**
 * [EN] A list of strings from an array or one comma-separated string.
 * [CN] 从数组或逗号分隔的字符串中得到字符串列表。
 */
function cylStringList(value) {
  const list = cylArray(value) || (typeof value === 'string' ? value.split(',') : []);
  return list.map((item) => String(item).trim()).filter((item) => item !== '');
}

/**
 * [EN] A boolean from true / false, yes / no, 1 / 0; `fallback` otherwise.
 * [CN] 从 true / false、yes / no、1 / 0 得到布尔值；否则返回 `fallback`。
 */
function cylBool(value, fallback) {
  if (typeof value === 'boolean') {
    return value;
  }
  const text = String(value).trim().toLowerCase();
  if (['true', 'yes', '1'].includes(text)) {
    return true;
  }
  if (['false', 'no', '0'].includes(text)) {
    return false;
  }
  return fallback;
}

/**
 * [EN] -1, 0 or 1, comparing "1.2.10" and "1.10" number by number (B24).
 * [CN] 逐段按数字比较 "1.2.10" 与 "1.10"，返回 -1、0 或 1（B24）。
 */
function cylCompareVersions(left, right) {
  const a = String(left).split('.').map((part) => parseInt(part, 10) || 0);
  const b = String(right).split('.').map((part) => parseInt(part, 10) || 0);
  for (let index = 0; index < Math.max(a.length, b.length); index += 1) {
    const difference = (a[index] || 0) - (b[index] || 0);
    if (difference !== 0) {
      return difference > 0 ? 1 : -1;
    }
  }
  return 0;
}

/**
 * [EN] Whether a tab is shown here: `CYLTabBarItemPlatforms` names this platform (or is missing), and the app is not
 *      older than `CYLTabBarItemMinimumAppVersion` (an unknown app version, as in the DevTools, passes) (B22).
 * [CN] Tab 是否在此显示：`CYLTabBarItemPlatforms` 包含本平台（或未设置），且 App 版本不低于
 *      `CYLTabBarItemMinimumAppVersion`（未知的 App 版本，例如在开发者工具中，视为通过）（B22）。
 */
function cylIsItemEligible(attributes, environment) {
  const platforms = cylStringList(attributes.CYLTabBarItemPlatforms).map((name) => name.toLowerCase());
  if (platforms.length > 0 && !platforms.some((name) => CYL_PLATFORM_NAMES.includes(name))) {
    return false;
  }
  const minimum = attributes.CYLTabBarItemMinimumAppVersion;
  if (minimum && environment.appVersion && cylCompareVersions(environment.appVersion, minimum) < 0) {
    return false;
  }
  return true;
}

/**
 * [EN] An image route as a path the <image> tag loads, or '' when it cannot be resolved:
 *      - "system:<name>": looked up in `environment.symbols` (an SF Symbol has no mini program counterpart);
 *      - http(s) URLs and absolute package paths ("/…") as they are;
 *      - other names and relative paths under `environment.imageBasePath`.
 * [CN] 把图片路由转为 <image> 可加载的路径，无法解析时返回 ''：
 *      - "system:<名称>"：在 `environment.symbols` 中查找（SF Symbol 在小程序中没有对应物）；
 *      - http(s) URL 与以 "/" 开头的代码包路径保持不变；
 *      - 其他名称与相对路径放在 `environment.imageBasePath` 之下。
 */
function cylImagePath(route, environment) {
  if (typeof route !== 'string' || route.trim() === '') {
    return '';
  }
  const value = route.trim();
  if (value.startsWith('system:')) {
    return (environment.symbols || {})[value.slice('system:'.length)] || '';
  }
  if (/^https?:\/\//.test(value) || value.startsWith('/')) {
    return value;
  }
  const base = environment.imageBasePath || '';
  return base ? `${base.replace(/\/$/, '')}/${value}` : value;
}

/**
 * [EN] A title through the configuration's localization table (`environment.strings`), as the iOS library does with
 *      `CYLTabBarControllerLocalization`; the title itself when the table has no entry.
 * [CN] 通过配置的本地化表（`environment.strings`）翻译标题，与 iOS 库的 `CYLTabBarControllerLocalization` 相同；
 *      表中没有时返回标题本身。
 */
function cylLocalizedTitle(title, environment) {
  if (typeof title !== 'string' && typeof title !== 'number') {
    return '';
  }
  const text = String(title);
  return (environment.strings || {})[text] || text;
}

/**
 * [EN] The skins of `CYLTabBarControllerThemes`, as {identifier: values}, from the dictionary form or the list form
 *      `[{CYLTabBarThemeIdentifier, CYLTabBarThemeValues}]`.
 * [CN] `CYLTabBarControllerThemes` 中的皮肤，返回 {标识: 取值}，支持字典写法与列表写法
 *      `[{CYLTabBarThemeIdentifier, CYLTabBarThemeValues}]`。
 */
function cylThemes(value) {
  const themes = {};
  const list = cylArray(value);
  if (list) {
    list.forEach((entry) => {
      if (entry && typeof entry.CYLTabBarThemeIdentifier === 'string' && entry.CYLTabBarThemeValues) {
        themes[entry.CYLTabBarThemeIdentifier] = entry.CYLTabBarThemeValues;
      }
    });
  } else if (value && typeof value === 'object') {
    Object.keys(value).forEach((identifier) => {
      if (value[identifier] && typeof value[identifier] === 'object') {
        themes[identifier] = value[identifier];
      }
    });
  }
  return themes;
}

/**
 * [EN] The identifier of the skin in use: the dark skin in Dark Mode, otherwise `CYLTabBarControllerThemeIdentifier`,
 *      otherwise the first skin alphabetically; '' without skins.
 * [CN] 当前使用的皮肤标识：深色模式下用深色皮肤，否则用 `CYLTabBarControllerThemeIdentifier`，否则按字母顺序的第一个；
 *      没有皮肤时返回 ''。
 */
function cylActiveThemeIdentifier(configuration, themes, isDark, requested) {
  const identifiers = Object.keys(themes).sort();
  if (identifiers.length === 0) {
    return '';
  }
  if (requested && themes[requested]) {
    return requested;
  }
  const dark = configuration.CYLTabBarControllerDarkThemeIdentifier;
  if (isDark && dark && themes[dark]) {
    return dark;
  }
  const light = configuration.CYLTabBarControllerThemeIdentifier;
  return light && themes[light] ? light : identifiers[0];
}

/**
 * [EN] Whether the bar is dark: `CYLTabBarControllerUserInterfaceStyle` (light, dark, system), the system theme for
 *      "system" or a missing value.
 * [CN] TabBar 是否为深色：取 `CYLTabBarControllerUserInterfaceStyle`（light、dark、system），"system" 或未设置时跟随系统。
 */
function cylIsDark(configuration, systemTheme) {
  const style = String(configuration.CYLTabBarControllerUserInterfaceStyle || 'system').toLowerCase();
  if (style === 'light' || style === 'dark') {
    return style === 'dark';
  }
  return systemTheme === 'dark';
}

/**
 * [EN] One tab, or the plus button, as render data.
 * [CN] 一个 Tab 或 PlusButton 的渲染数据。
 */
function cylItem(attributes, environment, theme, defaults) {
  const identifier = String(attributes.CYLTabBarItemIdentifier || '');
  const pageIdentifier = String(attributes.CYLTabBarItemPageIdentifier || '') || identifier;
  const title = cylLocalizedTitle(attributes.CYLTabBarItemTitle, environment);
  const selectedTitle = cylLocalizedTitle(attributes.CYLTabBarItemSelectedTitle, environment) || title;
  const image = cylImagePath(attributes.CYLTabBarItemImage, environment);
  const imageInsets = attributes.CYLTabBarItemImageInsets === undefined
    ? defaults.imageInsets
    : cylInsets(attributes.CYLTabBarItemImageInsets);
  const titleOffset = attributes.CYLTabBarItemTitlePositionAdjustment === undefined
    ? defaults.titleOffset
    : cylOffset(attributes.CYLTabBarItemTitlePositionAdjustment);
  return {
    identifier,
    pageIdentifier,
    pageParameters: attributes.CYLTabBarItemPageParameters && typeof attributes.CYLTabBarItemPageParameters === 'object'
      ? attributes.CYLTabBarItemPageParameters
      : null,
    title,
    selectedTitle,
    image,
    selectedImage: cylImagePath(attributes.CYLTabBarItemSelectedImage, environment) || image,
    titleColor: cylColor(attributes.CYLTabBarItemTitleColor) || cylColor(theme.CYLTabBarItemTitleColor),
    selectedTitleColor: cylColor(attributes.CYLTabBarItemSelectedTitleColor)
      || cylColor(theme.CYLTabBarItemSelectedTitleColor),
    backgroundColor: cylColor(attributes.CYLTabBarItemBackgroundColor) || cylColor(theme.CYLTabBarItemBackgroundColor),
    selectedBackgroundColor: cylColor(attributes.CYLTabBarItemSelectedBackgroundColor)
      || cylColor(theme.CYLTabBarItemSelectedBackgroundColor),
    imageStyle: cylTranslateStyle((imageInsets.left - imageInsets.right) / 2, (imageInsets.top - imageInsets.bottom) / 2),
    titleStyle: cylTranslateStyle(titleOffset.horizontal, titleOffset.vertical),
    accessibilityLabel: String(attributes.CYLTabBarItemAccessibilityLabel || '') || title || identifier,
    accessibilityHint: String(attributes.CYLTabBarItemAccessibilityHint || ''),
    accessibilityIdentifier: String(attributes.CYLTabBarItemAccessibilityIdentifier || '') || identifier,
  };
}

/**
 * [EN] A CSS transform that moves a view by (x, y) points; '' when both are 0. Image insets move the image the way
 *      UIEdgeInsets move a tab image (half of top − bottom down, half of left − right to the right); a title offset
 *      moves the title by its value.
 * [CN] 把视图移动 (x, y) 点的 CSS transform；两者都为 0 时返回 ''。图片 insets 的移动方式与 UIEdgeInsets 移动 Tab 图片
 *      相同（向下移动 top − bottom 的一半，向右移动 left − right 的一半）；标题偏移按其数值移动标题。
 */
function cylTranslateStyle(x, y) {
  return x === 0 && y === 0 ? '' : `transform: translate(${x}px, ${y}px);`;
}

/**
 * [EN] The plus button of `CYLTabBarControllerPlusButton`, or null when there is none.
 * [CN] `CYLTabBarControllerPlusButton` 中的 PlusButton；没有时返回 null。
 */
function cylPlusButton(configuration, environment, theme, defaults, tabCount) {
  const attributes = configuration.CYLTabBarControllerPlusButton;
  if (!attributes || typeof attributes !== 'object' || Array.isArray(attributes)) {
    return null;
  }
  const item = cylItem(attributes, environment, theme, defaults);
  const requestedIndex = parseInt(attributes.CYLPlusButtonIndexInTabBar, 10);
  const size = cylSize(attributes.CYLPlusButtonSize);
  const imageSize = cylSize(attributes.CYLPlusButtonImageSize);
  const multiplier = Number(attributes.CYLPlusButtonCenterYMultiplier);
  const offset = Number(attributes.CYLPlusButtonCenterYOffset);
  return Object.assign(item, {
    isPlusButton: true,
    hasPage: Boolean(String(attributes.CYLTabBarItemPageIdentifier || '')),
    backgroundImage: cylImagePath(attributes.CYLPlusButtonBackgroundImage, environment),
    index: Number.isInteger(requestedIndex) && requestedIndex >= 0 && requestedIndex <= tabCount
      ? requestedIndex
      : Math.floor(tabCount / 2),
    width: size ? size.width : 0,
    height: size ? size.height : 0,
    imageWidth: imageSize ? imageSize.width : 0,
    imageHeight: imageSize ? imageSize.height : 0,
    centerYMultiplier: Number.isFinite(multiplier) && multiplier >= 0 && multiplier <= 1 ? multiplier : 0.3,
    centerYOffset: Number.isFinite(offset) ? offset : 0,
    alignsTitle: cylBool(attributes.CYLPlusButtonAlignsTitle, Boolean(item.title) && !attributes.CYLPlusButtonBackgroundImage),
    keepsTitleVisible: cylBool(attributes.CYLPlusButtonKeepsTitleVisible, true),
  });
}

/**
 * [EN] The whole configuration as render data. `environment`: {systemTheme, appVersion, strings, symbols,
 *      imageBasePath, themeIdentifier} (all optional).
 * [CN] 把整个配置转为渲染数据。`environment`：{systemTheme, appVersion, strings, symbols, imageBasePath,
 *      themeIdentifier}（都可选）。
 */
function cylReadConfiguration(configuration, environment) {
  const source = configuration && typeof configuration === 'object' ? configuration : {};
  const env = environment || {};
  const themes = cylThemes(source.CYLTabBarControllerThemes);
  const followsDark = cylIsDark(source, env.systemTheme);
  const themeIdentifier = cylActiveThemeIdentifier(source, themes, followsDark, env.themeIdentifier);
  const darkIdentifier = source.CYLTabBarControllerDarkThemeIdentifier;
  const isDark = env.themeIdentifier ? Boolean(darkIdentifier) && themeIdentifier === darkIdentifier : followsDark;
  const theme = themes[themeIdentifier] || {};
  const themedEnvironment = Object.assign({}, env, {
    symbols: (env.symbolsByTheme && (env.symbolsByTheme[themeIdentifier] || env.symbolsByTheme.default)) || env.symbols,
  });
  const defaults = {
    imageInsets: cylInsets(source.CYLTabBarControllerImageInsets),
    titleOffset: cylOffset(source.CYLTabBarControllerTitlePositionAdjustment),
  };
  const attributesList = cylArray(source.CYLTabBarControllerTabBarItemsAttributes) || [];
  const items = attributesList
    .filter((attributes) => attributes && typeof attributes === 'object' && cylIsItemEligible(attributes, env))
    .map((attributes) => cylItem(attributes, themedEnvironment, theme, defaults));
  const styleValue = source.CYLTabBarControllerStyleType;
  const styleType = typeof styleValue === 'number' ? CYL_STYLE_TYPES[styleValue] : styleValue;
  const tapAnimation = source.CYLTabBarControllerTabButtonTapAnimation;
  const speed = Number(source.CYLTabBarControllerTabBarItemAnimationSpeed);
  const themeValues = {};
  CYL_THEME_KEYS.forEach((key) => {
    themeValues[key] = cylColor(theme[key]);
  });
  return {
    context: typeof source.CYLTabBarControllerContext === 'string' ? source.CYLTabBarControllerContext : '',
    items,
    plusButton: cylPlusButton(source, themedEnvironment, theme, defaults, items.length),
    styleType: CYL_STYLE_TYPES.includes(styleType) ? styleType : 'default',
    tapAnimation: CYL_TAP_ANIMATIONS.includes(tapAnimation) ? tapAnimation : 'none',
    animationDuration: Math.round(400 / (Number.isFinite(speed) && speed > 0 ? speed : 1)),
    swipeToSwitchTab: cylBool(source.CYLTabBarControllerSwipeToSwitchTab, false),
    loginRequiredIdentifiers: cylStringList(source.CYLTabBarControllerLoginRequiredTabBarItemIdentifiers),
    isDark,
    themeIdentifier,
    themeIdentifiers: Object.keys(themes).sort(),
    backgroundColor: themeValues.CYLTabBarBackgroundColor,
  };
}

module.exports = {
  cylReadConfiguration,
  cylArray,
  cylColor,
  cylInsets,
  cylOffset,
  cylSize,
  cylStringList,
  cylBool,
  cylCompareVersions,
  cylIsItemEligible,
  cylImagePath,
  cylThemes,
  cylActiveThemeIdentifier,
};
