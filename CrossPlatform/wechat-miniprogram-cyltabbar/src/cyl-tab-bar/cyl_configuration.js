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
 * [EN] An animation file route as a path: http(s) URLs and absolute package paths ("/…") as they are, a file name
 *      or a relative path under `environment.animationBasePath` (the iOS "file name in the main bundle"); '' when empty.
 * [CN] 把动画文件路由转为路径：http(s) URL 与以 "/" 开头的包内路径保持不变，文件名或相对路径放在
 *      `environment.animationBasePath` 之下（对应 iOS 的「main bundle 中的文件名」）；为空时返回 ''。
 */
function cylAnimationPath(route, environment) {
  if (typeof route !== 'string' || route.trim() === '') {
    return ''
  }
  const value = route.trim().split('#')[0]
  if (/^https?:\/\//.test(value) || value.startsWith('/')) {
    return value
  }
  const base = environment.animationBasePath || ''
  return base ? `${base.replace(/\/$/, '')}/${value}` : value
}

/**
 * [EN] keypath -> color, keeping valid colors only; null when none is left.
 * [CN] keypath -> 颜色，只保留有效颜色；没有剩余时返回 null。
 */
function cylColorMap(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null
  }
  const colors = {}
  Object.keys(value).forEach((keypath) => {
    if (cylColor(value[keypath])) {
      colors[keypath] = value[keypath]
    }
  })
  return Object.keys(colors).length > 0 ? colors : null
}

/**
 * [EN] The Lottie icon of a tab, or null: CYLTabBarLottieURL / CYLTabBarLottieDarkURL / CYLTabBarLottieSize /
 *      CYLTabBarLottieDarkColors / CYLTabBarLottieLoopsWhenUnselected, then the generic keys CYLTabBarAnimationURL,
 *      CYLTabBarAnimationFilePath (and their Dark variants), CYLTabBarAnimationSize, CYLTabBarAnimationColors /
 *      CYLTabBarAnimationDarkColors when the file is a .json (the file type picks the library, as on iOS).
 * [CN] Tab 的 Lottie 图标，没有时返回 null：先读 CYLTabBarLottieURL / CYLTabBarLottieDarkURL / CYLTabBarLottieSize /
 *      CYLTabBarLottieDarkColors / CYLTabBarLottieLoopsWhenUnselected，再读通用键 CYLTabBarAnimationURL、
 *      CYLTabBarAnimationFilePath（及其 Dark 版本）、CYLTabBarAnimationSize、CYLTabBarAnimationColors /
 *      CYLTabBarAnimationDarkColors，前提是文件为 .json（与 iOS 一样由文件类型决定动画库）。
 */
function cylLottie(attributes, environment) {
  const isJSON = (route) => typeof route === 'string' && /\.json(\?|#|$)/i.test(route.trim())
  const generic = [attributes.CYLTabBarAnimationURL, attributes.CYLTabBarAnimationFilePath].find(isJSON)
  const path = cylAnimationPath(attributes.CYLTabBarLottieURL, environment) || cylAnimationPath(generic, environment)
  if (!path) {
    return null
  }
  const genericDark = [attributes.CYLTabBarAnimationDarkURL, attributes.CYLTabBarAnimationDarkFilePath].find(isJSON)
  const size = cylSize(attributes.CYLTabBarLottieSize) || cylSize(attributes.CYLTabBarAnimationSize)
  return {
    path,
    darkPath: cylAnimationPath(attributes.CYLTabBarLottieDarkURL, environment) || cylAnimationPath(genericDark, environment),
    width: size ? size.width : 28,
    height: size ? size.height : 28,
    colors: cylColorMap(attributes.CYLTabBarAnimationColors),
    darkColors: cylColorMap(attributes.CYLTabBarLottieDarkColors) || cylColorMap(attributes.CYLTabBarAnimationDarkColors),
    loopsWhenUnselected: cylBool(attributes.CYLTabBarLottieLoopsWhenUnselected, false),
  }
}

/**
 * [EN] The GIF icon of a tab (CYLTabBarGIFURL / CYLTabBarGIFFilePath and their Dark variants, or a generic animation
 *      key with a .gif file), shown while the tab is selected; '' without one.
 * [CN] Tab 的 GIF 图标（CYLTabBarGIFURL / CYLTabBarGIFFilePath 及其 Dark 版本，或文件为 .gif 的通用动画键），在 Tab
 *      选中时显示；没有时返回 ''。
 */
function cylGIF(attributes, environment, isDark) {
  const isGIF = (route) => typeof route === 'string' && /\.gif(\?|#|$)/i.test(route.trim())
  const light = [attributes.CYLTabBarGIFURL, attributes.CYLTabBarGIFFilePath, attributes.CYLTabBarAnimationURL,
    attributes.CYLTabBarAnimationFilePath].find(isGIF)
  const dark = [attributes.CYLTabBarGIFDarkURL, attributes.CYLTabBarGIFDarkFilePath, attributes.CYLTabBarAnimationDarkURL,
    attributes.CYLTabBarAnimationDarkFilePath].find(isGIF)
  return cylAnimationPath(isDark && dark ? dark : light, environment)
}

const CYL_FONT_WEIGHTS = {
  ultralight: 100, thin: 200, light: 300, regular: 400, medium: 500, semibold: 600, bold: 700, heavy: 800, black: 900,
};

/**
 * [EN] CYLTabBarItemTitleFont as CSS: a number (size), "bold:15" (a weight and a size), "Menlo-Regular:12" (a font name
 *      and a size) or {name, size, weight}; size 1–200; '' when invalid (B20).
 * [CN] 把 CYLTabBarItemTitleFont 转为 CSS：数字（字号）、"bold:15"（字重与字号）、"Menlo-Regular:12"（字体名与字号）或
 *      {name, size, weight}；字号 1–200；无效时返回 ''（B20）。
 */
function cylFont(value) {
  let name = '';
  let size = NaN;
  let weight = '';
  if (typeof value === 'number' || (typeof value === 'string' && /^\s*\d+(\.\d+)?\s*$/.test(value))) {
    size = Number(value);
  } else if (typeof value === 'string' && value.includes(':')) {
    const index = value.lastIndexOf(':');
    const head = value.slice(0, index).trim();
    size = Number(value.slice(index + 1));
    if (CYL_FONT_WEIGHTS[head.toLowerCase()]) {
      weight = head.toLowerCase();
    } else {
      name = head;
    }
  } else if (value && typeof value === 'object') {
    name = typeof value.name === 'string' ? value.name : '';
    size = Number(value.size);
    weight = typeof value.weight === 'string' ? value.weight.toLowerCase() : '';
  }
  if (!Number.isFinite(size) || size < 1 || size > 200) {
    return '';
  }
  return `font-size: ${size}px; line-height: ${Math.round(size * 1.2)}px;`
    + (CYL_FONT_WEIGHTS[weight] ? ` font-weight: ${CYL_FONT_WEIGHTS[weight]};` : '')
    + (name ? ` font-family: "${name.replace(/"/g, '')}";` : '');
}

/**
 * [EN] CYLTabBarItemIconRenderingMode / CYLTabBarControllerIconRenderingMode: "template", "original" or "automatic"
 *      (case-insensitive); '' when missing or invalid.
 * [CN] CYLTabBarItemIconRenderingMode / CYLTabBarControllerIconRenderingMode："template"、"original" 或 "automatic"
 *      （不区分大小写）；缺失或无效时返回 ''。
 */
function cylRenderingMode(value) {
  const mode = String(value || '').trim().toLowerCase();
  return ['template', 'original', 'automatic'].includes(mode) ? mode : '';
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
    imageInsets,
    titleOffset,
    imageStyle: cylTranslateStyle((imageInsets.left - imageInsets.right) / 2, (imageInsets.top - imageInsets.bottom) / 2),
    titleStyle: cylTranslateStyle(titleOffset.horizontal, titleOffset.vertical),
    accessibilityLabel: String(attributes.CYLTabBarItemAccessibilityLabel || '') || title || identifier,
    accessibilityHint: String(attributes.CYLTabBarItemAccessibilityHint || ''),
    accessibilityIdentifier: String(attributes.CYLTabBarItemAccessibilityIdentifier || '') || identifier,
    lottie: cylLottie(attributes, environment),
    gif: cylGIF(attributes, environment, Boolean(environment.isDark)),
    titleFontStyle: cylFont(attributes.CYLTabBarItemTitleFont),
    selectedTitleFontStyle: cylFont(attributes.CYLTabBarItemSelectedTitleFont) || cylFont(attributes.CYLTabBarItemTitleFont),
    imageSize: cylSize(attributes.CYLTabBarItemImageURLSize),
    ...cylIconTint(attributes, theme, defaults),
  };
}

/**
 * [EN] The icon colors of a tab (#787): with "template" the image is tinted with the state's color, with "original"
 *      it keeps its colors, with "automatic" (or nothing) a "system:" image (a template image on iOS) is tinted when a
 *      color is given. Colors: the tab's
 *      CYLTabBarItemIconColor / CYLTabBarItemSelectedIconColor, then CYLTabBarControllerIconColor /
 *      CYLTabBarControllerSelectedIconColor, then the skin's values.
 * [CN] Tab 的图标颜色（#787）："template" 用当前状态的颜色给图片着色，"original" 保持原色，"automatic"（或未设置）
 *      在提供了颜色时给 "system:" 图片（iOS 上的模板图片）着色。颜色依次取 Tab 的 CYLTabBarItemIconColor / CYLTabBarItemSelectedIconColor，
 *      CYLTabBarControllerIconColor / CYLTabBarControllerSelectedIconColor，以及皮肤中的值。
 */
function cylIconTint(attributes, theme, defaults) {
  const mode = cylRenderingMode(attributes.CYLTabBarItemIconRenderingMode) || defaults.iconRenderingMode || 'automatic';
  const iconColor = cylColor(attributes.CYLTabBarItemIconColor) || defaults.iconColor || cylColor(theme.CYLTabBarItemIconColor);
  const selectedIconColor = cylColor(attributes.CYLTabBarItemSelectedIconColor) || defaults.selectedIconColor
    || cylColor(theme.CYLTabBarItemSelectedIconColor);
  // [EN] "automatic" tints only what iOS draws as a template: SF Symbols ("system:" images).
  // [CN] "automatic" 只给 iOS 按模板绘制的图片着色：SF Symbol（"system:" 图片）。
  const isTemplateImage = String(attributes.CYLTabBarItemImage || '').trim().startsWith('system:');
  if (mode === 'original' || (mode === 'automatic' && !isTemplateImage)) {
    return { iconRenderingMode: mode, iconTint: '', selectedIconTint: '' };
  }
  return {
    iconRenderingMode: mode,
    iconTint: iconColor,
    selectedIconTint: selectedIconColor || iconColor,
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
    showsSelection: cylBool(attributes.CYLPlusButtonShowsSelection, false),
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
    isDark,
    symbols: (env.symbolsByTheme && (env.symbolsByTheme[themeIdentifier] || env.symbolsByTheme.default)) || env.symbols,
  });
  const defaults = {
    imageInsets: cylInsets(source.CYLTabBarControllerImageInsets),
    titleOffset: cylOffset(source.CYLTabBarControllerTitlePositionAdjustment),
    iconRenderingMode: cylRenderingMode(source.CYLTabBarControllerIconRenderingMode),
    iconColor: cylColor(source.CYLTabBarControllerIconColor),
    selectedIconColor: cylColor(source.CYLTabBarControllerSelectedIconColor),
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
  cylFont,
  cylRenderingMode,
  cylLottie,
  cylGIF,
  cylAnimationPath,
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
