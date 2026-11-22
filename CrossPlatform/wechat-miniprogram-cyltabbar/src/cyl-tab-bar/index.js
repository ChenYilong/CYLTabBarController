/**
 * [EN] cyl-tab-bar: CYLTabBarController for WeChat Mini Program. A custom tab bar component that takes a
 *      CYLTabBarController configuration (the same keys as the iOS and Android libraries, docs/Configuration-File.md)
 *      and renders the tabs, a raised plus button, badges, skins and the style types. Use it inside the mini program's
 *      `custom-tab-bar` (app.json: "tabBar": {"custom": true}). Events: `select`, `reselect`, `plustap`,
 *      `loginrequired`; methods: `cyl_selectIdentifier`, `cyl_showBadgeValue`, `cyl_showBadgeDot`, `cyl_removeBadge`,
 *      `cyl_setThemeIdentifier`, `cyl_setHiddenIdentifiers`, `cyl_setTabBarHidden`.
 * [CN] cyl-tab-bar：微信小程序版 CYLTabBarController。自定义 TabBar 组件，接收 CYLTabBarController 配置（与 iOS、Android
 *      库相同的键，见 docs/Configuration-File.md），渲染 Tab、凸起的 PlusButton、角标、皮肤与样式。在小程序的
 *      `custom-tab-bar` 中使用（app.json："tabBar": {"custom": true}）。事件：`select`、`reselect`、`plustap`、
 *      `loginrequired`；方法：`cyl_selectIdentifier`、`cyl_showBadgeValue`、`cyl_showBadgeDot`、`cyl_removeBadge`、
 *      `cyl_setThemeIdentifier`、`cyl_setHiddenIdentifiers`、`cyl_setTabBarHidden`。
 */
const { cylReadConfiguration } = require('./cyl_configuration');
const { cylBadgeAnimationClass } = require('./cyl_debug');
const { cylTabBarItemStyle, cylTabBarItemStyleForStyleType, cylGlassLensStyle } = require('./cyl_tab_bar_item_style');
// TODO: replace the vendored copy with the npm package after the library is published (owner's OK): see ../cyl-dealloc-block-executor/VENDORED.md.
const { LifecycleController } = require('../cyl-dealloc-block-executor/index');

/**
 * [EN] Heights in px from the stylesheets: the bar (index.wxss `.cyl-tab`, Liquid Glass `.cyl-style-liquidGlass .cyl-tab`),
 *      a tab's default icon and its title (cyl-tab-bar-item: 2 gap + 12 line) and the plus title (2 gap + 12 line).
 * [CN] 来自样式表的高度（px）：TabBar（index.wxss `.cyl-tab`，液态玻璃 `.cyl-style-liquidGlass .cyl-tab`）、Tab 的默认图标
 *      及其标题（cyl-tab-bar-item：间距 2 + 行 12）以及 PlusButton 标题（间距 2 + 行 12）。
 */
/**
 * [EN] The default bar height when the app sets no `tabBarHeight`: 48 px, the WeChat native tab bar's height (measured in
 *      WeChat DevTools 3.17.6, iPhone 12/13 Pro: a page is 82 px shorter with the native tab bar, minus the 34 px safe
 *      area), so the bar matches the system tab bar as on iOS, Android and HarmonyOS. It was 50 px before 2026-11-22.
 * [CN] App 未设置 `tabBarHeight` 时的默认高度：48 px，即微信原生 tabBar 的高度（微信开发者工具 3.17.6、iPhone 12/13 Pro 实测：有原生 tabBar 时
 *      页面矮 82 px，减去 34 px 安全区），与 iOS、Android、鸿蒙一样与系统 TabBar 等高。2026-11-22 之前为 50 px。
 */
const CYL_BAR_HEIGHT = 48;
const CYL_LIQUID_GLASS_BAR_HEIGHT = 62;
const CYL_ITEM_ICON_HEIGHT = 28;
const CYL_ITEM_TITLE_HEIGHT = 14;
const CYL_PLUS_TITLE_HEIGHT = 14;

/**
 * [EN] The line of the tab titles, from the first tab: its icon height (animation or image size, else 28 px, as
 *      cyl-tab-bar-item draws it) and the vertical offset of its title (CYLTabBarItemTitlePositionAdjustment).
 * [CN] Tab 标题所在的行，取自第一个 Tab：其图标高度（动画或图片尺寸，否则 28 px，与 cyl-tab-bar-item 的绘制一致）与其
 *      标题的垂直偏移（CYLTabBarItemTitlePositionAdjustment）。
 */
/**
 * [EN] The classic bar's height: `tabBarHeight` when the app sets one (more than 0), else the system tab bar's 48 px.
 * [CN] 经典 TabBar 的高度：App 设置了 `tabBarHeight`（大于 0）时使用它，否则为系统 tabBar 的 48 px。
 */
function cylBarHeight(tabBarHeight) {
  const value = Number(tabBarHeight);
  return Number.isFinite(value) && value > 0 ? value : CYL_BAR_HEIGHT;
}

function cylTitleLine(slots) {
  const slot = slots.find((candidate) => candidate.item);
  const size = slot ? (slot.item.animationSize || slot.item.imageSize) : null;
  const match = /,\s*([\d.]+)\s*\}/.exec(size || '');
  const offset = slot?.item.titlePositionAdjustment ? Number(slot.item.titlePositionAdjustment.vertical) : 0;
  return {
    iconHeight: match ? Number(match[1]) : CYL_ITEM_ICON_HEIGHT,
    titleOffset: Number.isFinite(offset) ? offset : 0,
  };
}

/**
 * [EN] The badge text shown for a value: numbers above 99 read "99+"; '' means no badge.
 * [CN] 角标显示的文字：大于 99 的数字显示 "99+"；'' 表示没有角标。
 */
/**
 * [EN] The selected icon playback of every tab bar of the app. A mini program gives each tab page its own tab bar, so
 *      the tapped bar starts the icon at once and records when; the bar of the page that appears continues from that
 *      moment instead of starting again (before, the animation started 100-300 ms late on a new bar, half over).
 * [CN] App 中所有 TabBar 共享的选中图标播放记录。小程序中每个 Tab 页面都有自己的 TabBar，因此被点击的 TabBar 立即
 *      开始播放并记录时间；出现的页面的 TabBar 从该时刻继续，而不是重新开始（之前动画在新 TabBar 上晚 100-300 ms
 *      才开始，已过一半）。
 */
const cylPlayback = { key: '', startedAt: 0 };
const CYL_PLAYBACK_WINDOW = 3000;

/**
 * [EN] The tab tapped last, shared by every bar of the app (each tab page has its own bar). A page shown by the tap draws
 *      this selection at once, instead of its own stale one (the lens sat on the previous tab for a moment, then jumped).
 * [CN] 最后被点击的 Tab，App 中所有 TabBar 共享（每个 Tab 页面都有自己的 TabBar）。被点击而显示的页面立即绘制这个选中项，
 *      而不是自己过期的选中项（之前透镜先停在上一个 Tab，随后才跳过去）。
 */
const cylLastSelection = { context: '', identifier: '', time: 0 };

/**
 * [EN] Every attached bar of the app. A tap selects the tab in each bar of the same configuration context at once, so
 *      the page that wx.switchTab shows next, often a cached page drawn before any of its JavaScript runs, already has
 *      the new selection: pageLifetimes.show and the page's onShow come at least one frame too late, and the previous
 *      tab flashed first.
 * [CN] App 中所有已挂载的 TabBar。点击会立即在同一配置上下文的每个 TabBar 中选中该 Tab，因此 wx.switchTab 接下来显示的
 *      页面（通常是在其 JavaScript 运行前就已绘制的缓存页面）已带有新的选中项：pageLifetimes.show 与页面的 onShow
 *      至少晚一帧，之前会先闪现上一个 Tab。
 */
const cylLiveBars = new Set();

function cylRecentSelection(context) {
  const recent = cylLastSelection.identifier && cylLastSelection.context === context
    && Date.now() - cylLastSelection.time < CYL_PLAYBACK_WINDOW;
  return recent ? cylLastSelection.identifier : '';
}

function cylBadgeText(value) {
  if (value === undefined || value === null || value === '') {
    return '';
  }
  const number = Number(value);
  return Number.isFinite(number) && number > 99 ? '99+' : String(value);
}

/**
 * [EN] The system theme ("light" or "dark") from the base library.
 * [CN] 从基础库读取系统主题（"light" 或 "dark"）。
 */
function cylSystemTheme() {
  try {
    const info = typeof wx.getAppBaseInfo === 'function' ? wx.getAppBaseInfo() : wx.getSystemInfoSync();
    return info.theme === 'dark' ? 'dark' : 'light';
  } catch {
    return 'light';
  }
}

/**
 * [EN] A CSS font weight as its CYLTabBarItemTitleFont name.
 * [CN] 把 CSS 字重转为 CYLTabBarItemTitleFont 的名称。
 */
function cylWeightName(weight) {
  return { 100: 'ultralight', 200: 'thin', 300: 'light', 400: 'regular', 500: 'medium', 600: 'semibold', 700: 'bold',
    800: 'heavy', 900: 'black' }[weight] || '';
}

/**
 * [EN] One CSS declaration, "name: value;", or '' without a value. [CN] 一条 CSS 声明「name: value;」，没有值时为 ''。
 */
function cylDeclaration(name, value) {
  return value ? `${name}: ${value};` : '';
}

/**
 * [EN] The identifiers of `hiddenIdentifiers` (an array, or an object's values) as strings.
 * [CN] `hiddenIdentifiers`（数组，或对象的值）中的标识，转为字符串。
 */
function cylHiddenIdentifiers(value) {
  if (Array.isArray(value)) {
    return value.map(String);
  }
  if (value && typeof value === 'object') {
    return Object.keys(value).map((key) => value[key]).map(String);
  }
  return [];
}

/**
 * [EN] Leaves the hidden tabs out of the model. The plus button's place counts the tabs before it; hidden ones no longer
 *      take a place. [CN] 从模型中去掉隐藏的 Tab。PlusButton 的位置按其前面的 Tab 计算；隐藏的 Tab 不再占位。
 */
function cylHideItems(model, hidden) {
  if (model.plusButton) {
    const hiddenBefore = model.items.slice(0, model.plusButton.index).filter((item) => hidden.includes(item.identifier)).length;
    model.plusButton = hidden.includes(model.plusButton.identifier)
      ? null : { ...model.plusButton, index: model.plusButton.index - hiddenBefore };
  }
  model.items = model.items.filter((item) => !hidden.includes(item.identifier));
}

/** [EN] The first tab's identifier, '' without tabs. [CN] 第一个 Tab 的标识，没有 Tab 时为 ''。 */
function cylFirstIdentifier(model) {
  return model.items[0] ? model.items[0].identifier : '';
}

/**
 * [EN] The bar's style type: the item style decides the glass capsule too. [CN] TabBar 的样式类型：Item 样式同时决定玻璃胶囊。
 */
function cylBarStyleType(itemStyle, styleType) {
  if (itemStyle === 'liquidGlass') {
    return 'liquidGlass';
  }
  return styleType === 'liquidGlass' ? 'default' : styleType;
}

/** [EN] A title font style as a cyl-tab-bar-item font ({name, size, weight}). [CN] 把标题字体样式转为 cyl-tab-bar-item 的字体（{name, size, weight}）。 */
function cylTitleFont(fontStyle) {
  const size = /font-size: ([\d.]+)px/.exec(fontStyle || '');
  const weight = /font-weight: (\d+)/.exec(fontStyle || '');
  const family = /font-family: "([^"]+)"/.exec(fontStyle || '');
  if (!size) {
    return undefined;
  }
  return { name: family ? family[1] : '', size: Number(size[1]), weight: weight ? cylWeightName(Number(weight[1])) : '' };
}

/**
 * [EN] The animation properties of a tab for cyl-tab-bar-item; a dark bar takes the dark path, colors and tint when set.
 * [CN] Tab 的动画属性，供 cyl-tab-bar-item 使用；深色 TabBar 有深色路径、颜色与着色时使用它们。
 */
function cylAnimationProperties(lottie, isDarkBar) {
  if (!lottie) {
    return { animationPath: '', animationSize: null, animationColors: null, loopsWhenUnselected: false, animationTint: '' };
  }
  return {
    animationPath: (isDarkBar && lottie.darkPath) || lottie.path,
    animationSize: `{${lottie.width}, ${lottie.height}}`,
    animationColors: (isDarkBar && lottie.darkColors) || lottie.colors,
    loopsWhenUnselected: Boolean(lottie.loopsWhenUnselected),
    // [EN] The `tint` option; a dark bar takes `darkTint` when set. [CN] `tint` 选项；深色 TabBar 有 `darkTint` 时用它。
    animationTint: (isDarkBar && lottie.darkTint) || lottie.tint || '',
  };
}

/** [EN] A tab's image: the GIF, then the selected image, when selected. [CN] Tab 的图片：选中时先取 GIF，再取选中图片。 */
function cylSlotImage(item, selected) {
  if (selected && item.gif) {
    return item.gif;
  }
  return selected ? item.selectedImage : item.image;
}

/** [EN] The plus button's title: '' unless it keeps its title visible. [CN] PlusButton 的标题：不保持标题可见时为 ''。 */
function cylPlusTitle(plus, selected) {
  if (!plus.keepsTitleVisible) {
    return '';
  }
  return selected ? plus.selectedTitle : plus.title;
}

/**
 * [EN] The touchable area around the plus button, multiplied by touchableAreaScale, red when shown (issue #91).
 * [CN] PlusButton 周围的可点击区域，按 touchableAreaScale 放大，显示时为红色（issue #91）。
 */
function cylPlusHitStyle(plus) {
  if (!(plus.touchableAreaScale > 1 || plus.showsTouchableArea)) {
    return '';
  }
  const shown = plus.showsTouchableArea ? ' background-color: rgba(255, 59, 48, 0.35);' : '';
  return `width: ${plus.touchableAreaScale * 100}%; height: ${plus.touchableAreaScale * 100}%; left: ${(1 - plus.touchableAreaScale) * 50}%; top: ${(1 - plus.touchableAreaScale) * 50}%;${shown}`;
}

Component({
  options: {
    addGlobalClass: false,
    multipleSlots: false,
  },

  properties: {
    /**
     * [EN] The CYLTabBarController configuration (a parsed JSON object).
     * [CN] CYLTabBarController 配置（已解析的 JSON 对象）。
     */
    configuration: { type: Object, value: {} },
    /**
     * [EN] The bar's height in px (`tabBarHeight`); 0 or less: the default, the WeChat native tab bar's 48 px. Not used by
     *      the Liquid Glass style, whose capsule has its own height.
     * [CN] TabBar 高度（px，`tabBarHeight`）；0 或更小：默认值，即微信原生 tabBar 的 48 px。液态玻璃样式不使用，其胶囊有自己的高度。
     */
    tabBarHeight: { type: Number, value: 0 },
    /**
     * [EN] The localization table of the configuration for the current language (title -> translation).
     * [CN] 当前语言的配置本地化表（标题 -> 译文）。
     */
    strings: { type: Object, value: {} },
    /**
     * [EN] "system:<name>" image routes per skin: {themeIdentifier: {name: path}}, with "default" as the fallback.
     * [CN] 每个皮肤的 "system:<名称>" 图片路由：{皮肤标识: {名称: 路径}}，"default" 为兜底。
     */
    symbolsByTheme: { type: Object, value: {} },
    /**
     * [EN] The folder of image names and relative image paths of the configuration.
     * [CN] 配置中图片名称与相对图片路径所在的文件夹。
     */
    imageBasePath: { type: String, value: '' },
    /**
     * [EN] The folder of animation file names (CYLTabBarLottieURL "tab_home.json"), like the iOS main bundle.
     * [CN] 动画文件名（CYLTabBarLottieURL "tab_home.json"）所在的文件夹，相当于 iOS 的 main bundle。
     */
    animationBasePath: { type: String, value: '' },
    /**
     * [EN] CYLTabBarItemStyle (cyl_tab_bar_item_style.js) of every item at initialization: "flat" or "liquidGlass"
     *      (also its number, 0 or 1). Empty: from CYLTabBarControllerStyleType ("liquidGlass" gives liquidGlass). With
     *      liquidGlass the bar is a floating glass capsule. cyl_setItemStyle() switches it later.
     * [CN] 初始化时每个 Item 的 CYLTabBarItemStyle（cyl_tab_bar_item_style.js）："flat" 或 "liquidGlass"（也可用其数字
     *      0 或 1）。为空时由 CYLTabBarControllerStyleType 推出（"liquidGlass" 对应 liquidGlass）。liquidGlass 时 TabBar
     *      为悬浮的玻璃胶囊。之后用 cyl_setItemStyle() 切换。
     */
    itemStyle: { type: null, value: '' },
    /**
     * [EN] CYLGlassLensStyle (cyl_tab_bar_item_style.js) of the Liquid Glass lens, for tabs and the plus button:
     *      "regular" (default, nearly opaque, the same on any bar) or "skeuomorphic" (see-through, like real glass); also
     *      its number, 0 or 1. Used with the liquidGlass item style only. cyl_setGlassLensStyle() switches it later.
     * [CN] 液态玻璃透镜的 CYLGlassLensStyle（cyl_tab_bar_item_style.js），Tab 与 PlusButton 共用："regular"（默认，
     *      接近不透明，在任何 TabBar 上一致）或 "skeuomorphic"（半透明，像真实的玻璃）；也可用其数字 0 或 1。仅在
     *      liquidGlass Item 样式下使用。之后用 cyl_setGlassLensStyle() 切换。
     */
    glassLensStyle: { type: null, value: '' },
    /**
     * [EN] Playback speed of every tab icon animation (Lottie, PAG, Rive), above 0, applied live; GIF has none.
     * [CN] 所有 Tab 图标动画（Lottie、PAG、Rive）的播放速度，大于 0，实时生效；GIF 不支持。
     */
    animationSpeed: { type: Number, value: 1 },
    /**
     * [EN] Repeats the tab icon animations until turned off (off: they play once and stop), applied live.
     * [CN] 重复播放 Tab 图标动画直到关闭（关闭时播放一次后停止），实时生效。
     */
    animationLoop: { type: Boolean, value: false },
    /**
     * [EN] The identifier of the selected tab (CYLTabBarItemIdentifier).
     * [CN] 选中 Tab 的标识（CYLTabBarItemIdentifier）。
     */
    selectedIdentifier: { type: String, value: '' },
    /**
     * [EN] Whether the user is logged in; tabs in CYLTabBarControllerLoginRequiredTabBarItemIdentifiers need it.
     * [CN] 用户是否已登录；CYLTabBarControllerLoginRequiredTabBarItemIdentifiers 中的 Tab 需要登录。
     */
    loggedIn: { type: Boolean, value: false },
    /**
     * [EN] The app version compared with CYLTabBarItemMinimumAppVersion; '' skips the check.
     * [CN] 与 CYLTabBarItemMinimumAppVersion 比较的 App 版本；'' 表示不检查。
     */
    appVersion: { type: String, value: '' },
    /**
     * [EN] Identifiers (CYLTabBarItemIdentifier, or the plus button's) left out of the bar, e.g. tabs the user's role
     *      may not see. Their pages stay in app.json; the bar only stops showing them. A hidden selected tab selects the
     *      first shown one.
     * [CN] 不在 TabBar 中显示的标识（CYLTabBarItemIdentifier 或 PlusButton 的标识），例如用户角色无权看到的 Tab。其页面仍在
     *      app.json 中，只是 TabBar 不再显示。隐藏选中的 Tab 时选中第一个显示的 Tab。
     */
    // [EN] `type: null`: an array made in another JavaScript context (a test driver, a worker) is not an Array for
    //      WeChat: `type: Array` turns it into [], and here it arrives as an object ({0: 'a'}), which cyl_render reads too.
    // [CN] `type: null`：其他 JavaScript 上下文（测试驱动、worker）创建的数组在微信看来不是 Array：`type: Array` 会把它
    //      变成 []，在这里则以对象（{0: 'a'}）到达，cyl_render 同样能读取。
    hiddenIdentifiers: { type: null, value: [] },
    /**
     * [EN] Hides the whole bar (iOS -setTabBarHidden:); each tab page has its own bar, so it hides it on that page only.
     * [CN] 隐藏整个 TabBar（iOS -setTabBarHidden:）；每个 Tab 页面有自己的 TabBar，因此只在该页面隐藏。
     */
    tabBarHidden: { type: Boolean, value: false },
  },

  data: {
    cylSlots: [],
    cylStyleType: 'default',
    cylItemStyle: 'flat',
    cylGlassLensStyle: 'regular',
    cylIsDark: false,
    cylBarStyle: '',
    cylThemeIdentifier: '',
    cylAnimatingIdentifier: '',
    cylTapAnimation: 'none',
    cylAnimationStyle: '',
  },

  observers: {
    'configuration, strings, symbolsByTheme, imageBasePath, animationBasePath, selectedIdentifier, appVersion, itemStyle, glassLensStyle, hiddenIdentifiers, tabBarHeight': function () {
      this.cyl_render();
    },
  },

  pageLifetimes: {
    /**
     * [EN] A cached tab page is shown again with the selection it had: follow the tab that was just tapped before its own
     *      onShow syncs the route.
     * [CN] 被缓存的 Tab 页面再次显示时带着旧的选中项：在页面自己的 onShow 同步路由之前，先跟随刚被点击的 Tab。
     */
    show() {
      const recent = this.cylModel ? cylRecentSelection(this.cylModel.context || '') : '';
      if (recent && recent !== this.data.selectedIdentifier) {
        this.setData({ selectedIdentifier: recent });
      }
    },
  },

  lifetimes: {
    attached() {
      this.cylBadges = {};
      this.cylBadgeAttributes = {};
      this.cylCovers = {};
      this.cylSystemTheme = cylSystemTheme();
      this.cylRequestedTheme = '';
      // [EN] CYLDeallocBlockExecutor: each resource registers its own cleanup, keyed, where it is created; `detached` runs them.
      // [CN] CYLDeallocBlockExecutor：每个资源在创建处注册各自带 key 的清理；`detached` 时运行。
      this.cylLifecycle = new LifecycleController(this);
      this.cylLifecycle.onLoad();
      this.cylThemeListener = (result) => {
        this.cylSystemTheme = result.theme === 'dark' ? 'dark' : 'light';
        this.cyl_render();
      };
      if (typeof wx.onThemeChange === 'function') {
        wx.onThemeChange(this.cylThemeListener);
        this.cylLifecycle.registry.addDeallocCallback((bar) => {
          if (typeof wx.offThemeChange === 'function') {
            wx.offThemeChange(bar.cylThemeListener);
          }
        }, { key: 'cyl.core.themeListener' });
      }
      cylLiveBars.add(this);
      this.cylLifecycle.registry.addDeallocCallback((bar) => cylLiveBars.delete(bar), { key: 'cyl.core.liveBar' });
      this.cyl_render();
    },
    detached() {
      this.cylLifecycle.onUnload();
    },
  },

  methods: {
    /**
     * [EN] Rebuilds the render data from the configuration, the badges and the skin.
     * [CN] 根据配置、角标与皮肤重新生成渲染数据。
     */
    cyl_render() {
      if (!this.cylBadges) {
        return;
      }
      const model = cylReadConfiguration(this.data.configuration, {
        systemTheme: this.cylSystemTheme,
        appVersion: this.data.appVersion,
        strings: this.data.strings,
        symbolsByTheme: this.data.symbolsByTheme,
        imageBasePath: this.data.imageBasePath,
        animationBasePath: this.data.animationBasePath,
        themeIdentifier: this.cylRequestedTheme,
      });
      const hidden = cylHiddenIdentifiers(this.data.hiddenIdentifiers);
      if (hidden.length > 0) {
        cylHideItems(model, hidden);
      }
      this.cylModel = model;
      const recent = this.cylRendered ? '' : cylRecentSelection(model.context || '');
      this.cylRendered = true;
      // [EN] The first render of a bar follows the tab just tapped, and keeps it as its selection.
      // [CN] TabBar 的首次渲染跟随刚被点击的 Tab，并把它保存为自己的选中项。
      const requested = recent || this.data.selectedIdentifier;
      const shown = model.items.some((item) => item.identifier === requested)
        || (model.plusButton && model.plusButton.identifier === requested);
      const selected = shown ? requested : cylFirstIdentifier(model);
      const slots = model.items.map((item) => this.cyl_slot(item, selected));
      if (model.plusButton) {
        slots.splice(model.plusButton.index, 0, this.cyl_plusSlot(model.plusButton, selected,
          this.cyl_itemStyle(model) === 'liquidGlass' ? CYL_LIQUID_GLASS_BAR_HEIGHT : cylBarHeight(this.data.tabBarHeight),
          cylTitleLine(slots)));
      }
      slots.forEach((slot, index) => {
        if (slot.item) {
          slot.item.index = index;
        }
      });
      // [EN] One enum for the bar and its items: the item style decides the glass capsule too.
      // [CN] TabBar 与 Item 共用一个枚举：Item 样式同时决定玻璃胶囊。
      const itemStyle = this.cyl_itemStyle(model);
      const styleType = cylBarStyleType(itemStyle, model.styleType);
      this.setData({
        ...(recent && recent !== this.data.selectedIdentifier ? { selectedIdentifier: recent } : {}),
        cylSlots: slots,
        cylItemStyle: itemStyle,
        cylGlassLensStyle: cylGlassLensStyle(this.cylRequestedGlassLensStyle !== undefined
          ? this.cylRequestedGlassLensStyle : this.data.glassLensStyle),
        cylStyleType: styleType,
        cylIsDark: model.isDark,
        cylBarStyle: (itemStyle === 'liquidGlass' ? '' : `--cyl-bar-height: ${cylBarHeight(this.data.tabBarHeight)}px;`)
          + (model.backgroundColor ? `background-color: ${model.backgroundColor};` : '')
          + (model.shadowColor ? `border-top-color: ${model.shadowColor};` : ''),
        cylThemeIdentifier: model.themeIdentifier,
        cylTapAnimation: model.tapAnimation,
        cylFlipDirection: model.flipDirection,
        cylAnimationStyle: `animation-duration: ${model.animationDuration}ms;`,
        cylAnimationDuration: model.animationDuration,
      }, () => this.cyl_syncLottie(selected));
    },

    /**
     * [EN] Plays the Lottie icon of a tab that just became selected (once, staying on its last frame), and rests or
     *      loops (CYLTabBarLottieLoopsWhenUnselected) the others.
     * [CN] 播放刚被选中的 Tab 的 Lottie 图标（播放一次，停在最后一帧），其他 Tab 停在首帧或循环播放
     *      （CYLTabBarLottieLoopsWhenUnselected）。
     */
    cyl_syncLottie(selected) {
      const previous = this.cylLottieSelected;
      this.cylLottieSelected = selected;
      if (previous !== undefined && previous !== selected) {
        // [EN] The iOS contract: a switch stops and resets every other tab first, then the selected one plays, so a tab tapped
        //      mid-animation never keeps playing next to the new one (and exactly one tab looks selected).
        // [CN] iOS 约定：切换时先停止并重置其他所有 Tab，再播放选中的 Tab，因此动画途中被切走的 Tab 不会与新 Tab 同时播放
        //      （且只有一个 Tab 看起来是选中的）。
        this.cyl_stopOtherAnimations(selected);
        this.cyl_playLottie(selected);
      }
    },

    /**
     * [EN] Stops every tab except `selected` and shows its resting frame; a tab that loops while unselected
     *      (CYLTabBarLottieLoopsWhenUnselected) keeps looping.
     * [CN] 停止除 `selected` 以外的所有 Tab 并显示其静止帧；未选中时循环的 Tab（CYLTabBarLottieLoopsWhenUnselected）继续循环。
     */
    cyl_stopOtherAnimations(selected) {
      const model = this.cylModel;
      if (!model) {
        return;
      }
      const keys = model.items.filter((item) => !item.lottie?.loopsWhenUnselected).map((item) => item.identifier);
      keys.filter((key) => key !== selected).forEach((key) => {
        const item = this.selectComponent(`#cyl-item-${key}`);
        if (item && typeof item.cyl_stopAnimation === 'function') {
          item.cyl_stopAnimation();
        }
      });
    },

    /**
     * [EN] Plays the Lottie icon of the tab with this identifier from its first frame (default: the selected tab);
     *      a page shown with switchTab calls it, because each tab page has its own tab bar instance.
     * [CN] 从首帧播放该标识的 Tab 的 Lottie 图标（默认：选中的 Tab）；通过 switchTab 显示的页面会调用它，因为每个
     *      Tab 页面都有自己的 TabBar 实例。
     */
    cyl_playLottie(identifier) {
      const key = identifier || this.cylLottieSelected;
      const item = this.selectComponent(`#cyl-item-${key}`);
      if (!item) {
        return;
      }
      const recordKey = `${this.cylModel?.context || ''}/${key}`;
      const elapsed = Date.now() - cylPlayback.startedAt;
      if (cylPlayback.key === recordKey && elapsed < CYL_PLAYBACK_WINDOW) {
        item.cyl_playAnimation(elapsed / 1000);
        return;
      }
      cylPlayback.key = recordKey;
      cylPlayback.startedAt = Date.now();
      item.cyl_playAnimation(0);
    },

    /**
     * [EN] Render data of one tab: the state's image, title and colors, the badge, and its accessibility label
     *      (the badge is read as part of the tab, e.g. "Message, 3").
     * [CN] 一个 Tab 的渲染数据：当前状态的图片、标题与颜色、角标，以及无障碍标签（角标作为 Tab 的一部分朗读，
     *      例如 "Message, 3"）。
     */
    cyl_slot(item, selectedIdentifier) {
      const selected = item.identifier === selectedIdentifier;
      const badge = cylBadgeText(this.cylBadges[item.identifier]);
      const isDot = badge === '•';
      const color = selected ? item.selectedTitleColor : item.titleColor;
      const lottie = item.lottie;
      const isDarkBar = this.cylModel ? this.cylModel.isDark : false;
      // [EN] The tab is drawn by cyl-tab-bar-item, with the iOS CYLFlatDesignTabBarItem property names.
      // [CN] Tab 由 cyl-tab-bar-item 绘制，使用 iOS CYLFlatDesignTabBarItem 的属性名。
      const itemProperties = {
        index: 0,
        title: selected ? item.selectedTitle : item.title,
        image: item.image,
        selectedImage: item.gif || item.selectedImage,
        selected,
        ...cylAnimationProperties(lottie, isDarkBar),
        imageSize: item.imageSize ? `{${item.imageSize.width}, ${item.imageSize.height}}` : null,
        imageInsets: item.imageInsets,
        titlePositionAdjustment: item.titleOffset,
        iconTint: item.iconTint,
        selectedIconTint: item.selectedIconTint,
        backgroundColor: item.backgroundColor,
        selectedBackgroundColor: item.selectedBackgroundColor,
        titleTextAttributes: {
          normal: { color: item.titleColor || '#8E8E93', font: cylTitleFont(item.titleFontStyle) },
          selected: { color: item.selectedTitleColor || (isDarkBar ? '#0A84FF' : '#007AFF'), font: cylTitleFont(item.selectedTitleFontStyle) },
        },
      };
      return {
        key: item.identifier,
        isPlusButton: false,
        selected,
        item: itemProperties,
        title: selected ? item.selectedTitle : item.title,
        image: cylSlotImage(item, selected),
        imageStyle: item.imageStyle,
        imageSizeStyle: item.imageSize ? `width: ${item.imageSize.width}px; height: ${item.imageSize.height}px;` : '',
        tint: selected ? item.selectedIconTint : item.iconTint,
        titleStyle: `${item.titleStyle}${cylDeclaration('color', color)}${selected ? item.selectedTitleFontStyle : item.titleFontStyle}`,
        // [EN] cyl-tab-bar-item draws the background. [CN] 背景由 cyl-tab-bar-item 绘制。
        itemStyle: '',
        badge: isDot ? '' : badge,
        showsDot: isDot,
        badgeItem: this.cyl_badgeItem(item.identifier, isDot),
        cover: this.cylCovers[item.identifier] ? this.cyl_cover(this.cylCovers[item.identifier]) : null,
        accessibilityLabel: badge && !isDot ? `${item.accessibilityLabel}, ${badge}` : item.accessibilityLabel,
        accessibilityIdentifier: item.accessibilityIdentifier,
      };
    },

    /**
     * [EN] The badge attributes of cyl_showBadgeValue for cyl-tab-bar-item: `color`, `animation` (CYLBadgeAnimationType
     *      name), `radius` (of a dot) and `centerOffset` ([x, y], from the default place).
     * [CN] cyl_showBadgeValue 的角标属性，供 cyl-tab-bar-item 使用：`color`、`animation`（CYLBadgeAnimationType 名称）、
     *      `radius`（小红点半径）与 `centerOffset`（[x, y]，相对默认位置）。
     */
    cyl_badgeItem(identifier, isDot) {
      const attributes = this.cylBadgeAttributes[identifier] || {};
      const offset = Array.isArray(attributes.centerOffset) ? attributes.centerOffset : null;
      const radius = Number(attributes.radius);
      const model = this.cylModel || {};
      // [EN] The skin's badge color and offset apply to badges without their own (UITabBarAppearance). [CN] 皮肤的角标颜色与偏移用于没有自定值的角标。
      return {
        color: attributes.color || model.badgeBackgroundColor || '',
        animation: attributes.animation || '',
        size: isDot && radius > 0 ? `{${radius * 2}, ${radius * 2}}` : null,
        positionAdjustment: offset ? `{${Number(offset[0]) || 0}, ${Number(offset[1]) || 0}}` : (model.badgePositionAdjustment || null),
      };
    },

    /** [EN] Render data of a cover (cyl_setCoverImage). [CN] 封面（cyl_setCoverImage）的渲染数据。 */
    cyl_cover(cover) {
      const match = /\{\s*([\d.]+)\s*,\s*([\d.]+)\s*\}/.exec(cover.size);
      const width = match ? Number(match[1]) : 37;
      const height = match ? Number(match[2]) : 37;
      return { image: cover.image, style: `width: ${width}px; height: ${height}px; margin: ${-height / 2}px 0 0 ${-width / 2}px;` };
    },

    /**
     * [EN] Render data of the plus button's badge (cyl_showBadgeValue with the plus button's identifier), at the top
     *      right of its image, as the tabs' badges.
     * [CN] PlusButton 角标（使用 PlusButton 标识调用 cyl_showBadgeValue）的渲染数据，位于其图片右上角，与 Tab 的角标相同。
     */
    cyl_plusBadge(identifier) {
      const text = cylBadgeText(this.cylBadges[identifier]);
      if (!text) {
        return null;
      }
      const isDot = text === '•';
      const badge = this.cyl_badgeItem(identifier, isDot);
      const offset = /\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}/.exec(badge.positionAdjustment || '');
      const size = /\{\s*([\d.]+)\s*,/.exec(badge.size || '');
      return {
        text: isDot ? '' : text,
        isDot,
        className: cylBadgeAnimationClass(badge.animation),
        style: (badge.color ? `background-color: ${badge.color};` : '')
          + (offset ? ` margin-left: ${offset[1]}px; margin-top: ${offset[2]}px;` : '')
          + (size ? ` width: ${size[1]}px; height: ${size[1]}px; border-radius: ${Number(size[1]) / 2}px;` : ''),
      };
    },

    /**
     * [EN] Render data of the plus button: raised by CYLPlusButtonCenterYMultiplier (of a 50 pt bar) and
     *      CYLPlusButtonCenterYOffset, sized by CYLPlusButtonSize / CYLPlusButtonImageSize.
     * [CN] PlusButton 的渲染数据：按 CYLPlusButtonCenterYMultiplier（50 pt 高的 TabBar）与 CYLPlusButtonCenterYOffset
     *      凸起，尺寸由 CYLPlusButtonSize / CYLPlusButtonImageSize 决定。
     */
    cyl_plusSlot(plus, selectedIdentifier, barHeight = CYL_BAR_HEIGHT, tabTitleLine = null) {
      const titleLine = tabTitleLine || { iconHeight: CYL_ITEM_ICON_HEIGHT, titleOffset: 0 };
      const selected = plus.hasPage && plus.identifier === selectedIdentifier;
      const imageWidth = plus.imageWidth || plus.width || 56;
      const imageHeight = plus.imageHeight || plus.height || 56;
      const titleHeight = plus.title && plus.keepsTitleVisible ? 16 : 0;
      const height = plus.height || imageHeight + titleHeight;
      const centerY = 50 * plus.centerYMultiplier + plus.centerYOffset;
      // [EN] CYLPlusButtonAlignsTitle (default: a title and no background image): the title on the same line as the tab
      //      titles. A tab centers its icon and title in the bar, so its title ends half of (icon + title) below the
      //      bar's middle, moved by its title offset; the plus title ends CYL_PLUS_TITLE_HEIGHT below the plus image.
      // [CN] CYLPlusButtonAlignsTitle（默认：有标题且没有背景图）：标题与 Tab 标题在同一行。Tab 的图标与标题在 TabBar
      //      中居中，因此其标题底边位于 TabBar 中线下方（图标 + 标题）的一半处，再加上其标题偏移；PlusButton 标题底边位于其图片下方
      //      CYL_PLUS_TITLE_HEIGHT。
      const alignedTop = barHeight / 2 + (titleLine.iconHeight + CYL_ITEM_TITLE_HEIGHT) / 2 + titleLine.titleOffset
        - CYL_PLUS_TITLE_HEIGHT - imageHeight;
      const top = plus.alignsTitle && titleHeight ? alignedTop : centerY - imageHeight / 2;
      const color = selected ? plus.selectedTitleColor : plus.titleColor;
      const widthStyle = plus.width ? ` width: ${plus.width}px;` : '';
      return {
        key: plus.identifier || 'cyl-plus-button',
        isPlusButton: true,
        selected,
        showsSelection: selected && plus.showsSelection,
        title: cylPlusTitle(plus, selected),
        image: selected ? plus.selectedImage : plus.image,
        backgroundImage: plus.backgroundImage,
        buttonStyle: `top: ${top}px; height: ${height}px;${widthStyle}`,
        hitStyle: cylPlusHitStyle(plus),
        imageStyle: `width: ${imageWidth}px; height: ${imageHeight}px;`,
        titleStyle: `${cylDeclaration('color', color)}${(selected ? plus.selectedTitleFontStyle : plus.titleFontStyle) || ''}`,
        badge: this.cyl_plusBadge(plus.identifier || 'cyl-plus-button'),
        accessibilityLabel: plus.accessibilityLabel,
        accessibilityIdentifier: plus.accessibilityIdentifier,
      };
    },

    /**
     * [EN] A tap on a tab or the plus button: checks login, plays the tap animation and emits the event.
     * [CN] 点击 Tab 或 PlusButton：检查登录、播放点击动画并发出事件。
     */
    /**
     * [EN] Long press and double tap (issue #535 / #152): a touch held for cyl_tabBarItemLongPressDuration emits
     *      `longpress` instead of the tap; two taps within cyl_tabBarItemDoubleTapInterval emit `doubletap` after the
     *      second tap.
     * [CN] 长按与双击（issue #535 / #152）：按住达到长按时长时发出 `longpress`，代替点击；双击间隔内的两次点击在第二次
     *      点击后发出 `doubletap`。
     */
    cyl_onTouchStart(event) {
      const key = event.currentTarget.dataset.key;
      const model = this.cylModel;
      clearTimeout(this.cylLongPressTimer);
      this.cylLongPressed = false;
      if (!model) {
        return;
      }
      this.cylLongPressTimer = setTimeout(() => {
        this.cylLongPressed = true;
        this.triggerEvent('longpress', this.cyl_detail(key));
      }, model.longPressDuration * 1000);
    },

    cyl_onTouchEnd() {
      clearTimeout(this.cylLongPressTimer);
    },

    /**
     * [EN] The event detail of the tab or plus button `key`. [CN] Tab 或 PlusButton `key` 的事件详情。
     */
    cyl_detail(key) {
      const model = this.cylModel;
      const plus = model.plusButton;
      const isPlusButton = Boolean(plus) && key === (plus.identifier || 'cyl-plus-button');
      const item = isPlusButton ? plus : model.items.find((candidate) => candidate.identifier === key);
      return item ? {
        index: this.data.cylSlots.findIndex((slot) => slot.key === key),
        identifier: item.identifier,
        title: item.title,
        pageIdentifier: item.pageIdentifier,
        pageParameters: item.pageParameters,
        context: model.context,
        isPlusButton,
      } : null;
    },

    /**
     * [EN] Records a tap; the second tap on the same key within the double tap interval emits `doubletap`.
     * [CN] 记录一次点击；在双击间隔内对同一项的第二次点击发出 `doubletap`。
     */
    cyl_recordTap(key) {
      const now = Date.now();
      const last = this.cylLastTap || {};
      if (last.key === key && now - last.time <= this.cylModel.doubleTapInterval * 1000) {
        this.cylLastTap = null;
        const doubleTapDetail = this.cyl_detail(key);
        setTimeout(() => this.triggerEvent('doubletap', doubleTapDetail), 0);
      } else {
        this.cylLastTap = { key, time: now };
      }
    },

    cyl_onTap(event) {
      const key = event.currentTarget.dataset.key;
      if (this.cylLongPressed && event.type === 'tap') {
        // [EN] The touch was a long press. [CN] 本次触摸是长按。
        this.cylLongPressed = false;
        return;
      }
      if (event.type === 'tap' && this.cylModel) {
        this.cyl_recordTap(key);
      }
      const model = this.cylModel;
      const plus = model.plusButton;
      const isPlusButton = Boolean(plus) && key === (plus.identifier || 'cyl-plus-button');
      const item = isPlusButton ? plus : model.items.find((candidate) => candidate.identifier === key);
      if (!item) {
        return;
      }
      const index = this.data.cylSlots.findIndex((slot) => slot.key === key);
      const detail = {
        index,
        identifier: item.identifier,
        // [EN] The localized title, e.g. for the login alert ("Log in to view “Me”"). [CN] 本地化后的标题，例如用于登录提示。
        title: item.title,
        pageIdentifier: item.pageIdentifier,
        pageParameters: item.pageParameters,
        context: model.context,
        isPlusButton,
      };
      if (model.loginRequiredIdentifiers.includes(item.identifier) && !this.data.loggedIn) {
        this.triggerEvent('loginrequired', detail);
        return;
      }
      this.cyl_playTapAnimation(key);
      this.cyl_playTabButtonTapFeedback();
      if (isPlusButton && !plus.hasPage) {
        this.triggerEvent('plustap', detail);
        return;
      }
      const currentIdentifier = this.data.selectedIdentifier || cylFirstIdentifier(model);
      if (item.identifier === currentIdentifier) {
        this.triggerEvent('reselect', detail);
        return;
      }
      // [EN] Select and play at once on the tapped bar; the page's own bar continues the playback (cylPlayback).
      // [CN] 在被点击的 TabBar 上立即选中并播放；页面自己的 TabBar 继续该播放（cylPlayback）。
      cylLastSelection.context = model.context || '';
      cylLastSelection.identifier = item.identifier;
      cylLastSelection.time = Date.now();
      this.setData({ selectedIdentifier: item.identifier });
      cylLiveBars.forEach((bar) => {
        if (bar !== this) {
          bar.cyl_followSelection(model.context || '', item.identifier);
        }
      });
      this.triggerEvent('select', detail);
    },

    /**
     * [EN] Selects a tab tapped on another bar of the same context (see cylLiveBars), when this bar shows it.
     * [CN] 选中同一上下文中另一个 TabBar 上被点击的 Tab（见 cylLiveBars），前提是本 TabBar 显示该 Tab。
     */
    cyl_followSelection(context, identifier) {
      const model = this.cylModel;
      if (!model || (model.context || '') !== context || identifier === this.data.selectedIdentifier) {
        return;
      }
      const shown = model.items.some((candidate) => candidate.identifier === identifier)
        || (model.plusButton && model.plusButton.identifier === identifier);
      if (shown) {
        this.setData({ selectedIdentifier: identifier });
      }
    },

    /**
     * [EN] Plays CYLTabBarControllerTabButtonTapAnimation on the tapped item.
     * [CN] 在被点击的项上播放 CYLTabBarControllerTabButtonTapAnimation。
     */
    cyl_playTapAnimation(key) {
      const model = this.cylModel;
      if (!model) {
        return;
      }
      const item = model.items.find((candidate) => candidate.identifier === key);
      // [EN] A tab's own animation wins (viewController.cyl_tabButtonAnimation). [CN] Tab 自己的动画优先。
      const name = item?.tapAnimation || model.tapAnimation;
      if (!name || name === 'none') {
        return;
      }
      clearTimeout(this.cylAnimationTimer);
      const fireworks = model.playsFireworks && !item?.tapAnimation ? this.cyl_fireworks(key) : null;
      this.setData({ cylAnimatingIdentifier: '', cylFireworks: null }, () => {
        this.setData({ cylAnimatingIdentifier: key, cylAnimatingName: name, cylFireworks: fireworks });
        this.cylAnimationTimer = setTimeout(() => this.setData({ cylAnimatingIdentifier: '', cylFireworks: null }),
          model.animationDuration + (fireworks ? 900 : 100));
        // [EN] The timer is a resource of its own: cleared when the bar detaches (the keyed callback is replaced per timer).
        // [CN] 定时器是独立的资源：TabBar detached 时清除（每个定时器替换同 key 的回调）。
        if (this.cylLifecycle && !this.cylLifecycle.isDetached) {
          this.cylLifecycle.registry.addDeallocCallback((bar) => clearTimeout(bar.cylAnimationTimer), { key: 'cyl.core.animationTimer' });
        }
      });
    },

    /**
     * [EN] Plays the tap animation once on the selected tab (the Home row plays a new animation this way).
     * [CN] 在选中的 Tab 上播放一次点击动画（首页行以此展示新的动画）。
     */
    cyl_playSelectedTapAnimation() {
      const model = this.cylModel;
      const key = this.data.selectedIdentifier || (model?.items[0] ? model.items[0].identifier : '');
      this.cyl_playTapAnimation(key);
    },

    /**
     * [EN] The fireworks of CYLTabButtonAnimation (playsFireworks): 10 particles in the icon's selected color (or the
     *      fireworks image) that gather on the icon after the animation, then burst out.
     * [CN] CYLTabButtonAnimation 的烟花（playsFireworks）：10 个使用图标选中颜色（或烟花图片）的粒子，动画后聚到图标上，然后散开。
     */
    cyl_fireworks(key) {
      const model = this.cylModel;
      const plus = model.plusButton;
      const item = plus && key === (plus.identifier || 'cyl-plus-button') ? plus : model.items.find((candidate) => candidate.identifier === key);
      const color = (item && (item.selectedIconTint || item.selectedTitleColor)) || '#FF9500';
      const delay = model.animationDuration;
      const background = model.fireworksImage ? '' : ` background-color: ${color};`;
      return {
        key,
        image: model.fireworksImage,
        particles: Array.from({ length: 10 }, (unused, index) => {
          const angle = (index / 10) * Math.PI * 2;
          const dx = Math.round(Math.cos(angle) * 26);
          const dy = Math.round(Math.sin(angle) * 26);
          return { index, style: `--cyl-dx: ${dx}px; --cyl-dy: ${dy}px; animation-delay: ${delay}ms;${background}` };
        }),
      };
    },

    /**
     * [EN] cyl_playTabButtonTapFeedback: the tap sound (CYLTabBarControllerTabButtonTapSoundURL) and the haptic
     *      (CYLTabBarControllerTabButtonTapHapticStyle; a phone vibrates, DevTools does not).
     * [CN] cyl_playTabButtonTapFeedback：点击声音（CYLTabBarControllerTabButtonTapSoundURL）与触感
     *      （CYLTabBarControllerTabButtonTapHapticStyle；真机振动，开发者工具不振动）。
     */
    cyl_playTabButtonTapFeedback() {
      const model = this.cylModel;
      if (!model) {
        return;
      }
      if (model.tapHapticStyle && typeof wx.vibrateShort === 'function') {
        wx.vibrateShort({ type: model.tapHapticStyle });
      }
      if (model.tapSoundURL && typeof wx.createInnerAudioContext === 'function') {
        if (!this.cylTapSound || this.cylTapSoundURL !== model.tapSoundURL) {
          if (this.cylTapSound) {
            this.cylTapSound.destroy();
          }
          this.cylTapSound = wx.createInnerAudioContext();
          this.cylTapSound.src = model.tapSoundURL;
          this.cylTapSoundURL = model.tapSoundURL;
        }
        this.cylTapSound.stop();
        this.cylTapSound.play();
      }
    },

    /**
     * [EN] CYLTabBarControllerSwipeToSwitchTab: selects the tab next to the selected one (step 1 = the next one,
     *      -1 = the previous one), skipping the plus button, by emitting `select` like a tap; does nothing when the
     *      key is off or at either end. Pages call it from a horizontal swipe (cyl_swipe_behavior.js).
     * [CN] CYLTabBarControllerSwipeToSwitchTab：选中与当前 Tab 相邻的 Tab（1 为下一个，-1 为上一个），跳过 PlusButton，
     *      像点击一样发出 `select`；该键关闭或已到两端时不做任何事。页面在水平滑动时调用（cyl_swipe_behavior.js）。
     */
    /**
     * [EN] cyl_switchToAdjacentTabWithStep: (issue #535): selects the next (1) or previous (-1) tab, the plus button
     *      included when it has a page, like a tap: a tab that needs login starts the login (`loginrequired`) and
     *      returns false; at either end it returns false (no wrapping). Swipe or not.
     * [CN] cyl_switchToAdjacentTabWithStep:（issue #535）：像点击一样选中下一个（1）或上一个（-1）Tab；PlusButton 有页面时
     *      也算在内；需要登录的 Tab 开始登录（`loginrequired`）并返回 false；到两端时返回 false（不循环）。与是否开启滑动无关。
     */
    cyl_switchToAdjacentTab(step) {
      const model = this.cylModel;
      if (!model) {
        return false;
      }
      const plus = model.plusButton;
      const slots = this.data.cylSlots.filter((slot) => !slot.isPlusButton || plus?.hasPage);
      const current = this.data.selectedIdentifier || (model.items[0] ? model.items[0].identifier : '');
      const index = slots.findIndex((slot) => slot.key === current);
      const next = slots[index + (step > 0 ? 1 : -1)];
      if (index < 0 || !next) {
        return false;
      }
      const item = next.isPlusButton ? plus : model.items.find((candidate) => candidate.identifier === next.key);
      const needsLogin = item && model.loginRequiredIdentifiers.includes(item.identifier) && !this.data.loggedIn;
      this.cyl_onTap({ currentTarget: { dataset: { key: next.key } } });
      return !needsLogin;
    },

    cyl_selectAdjacent(step) {
      const model = this.cylModel;
      if (!model?.swipeToSwitchTab) {
        return false;
      }
      const current = this.data.selectedIdentifier || (model.items[0] ? model.items[0].identifier : '');
      const index = model.items.findIndex((item) => item.identifier === current);
      const next = model.items[index + (step > 0 ? 1 : -1)];
      if (index < 0 || !next) {
        return false;
      }
      this.cyl_onTap({ currentTarget: { dataset: { key: next.identifier } } });
      return true;
    },

    /**
     * [EN] Selects a tab by its identifier, as `selectedIdentifier` does.
     * [CN] 按标识选中 Tab，与 `selectedIdentifier` 相同。
     */
    cyl_selectIdentifier(identifier) {
      this.setData({ selectedIdentifier: identifier || '' });
    },

    /**
     * [EN] Shows a badge with a number or a text on the tab with this identifier; "" or null removes it.
     * [CN] 在该标识的 Tab 上显示数字或文字角标；"" 或 null 移除角标。
     */
    cyl_showBadgeValue(identifier, value, attributes) {
      this.cylBadges[identifier] = value;
      // [EN] As iOS, attributes set before cyl_showBadgeValue stay until the badge is removed: pass them to change them.
      // [CN] 与 iOS 一样，在 cyl_showBadgeValue 之前设置的属性一直保留到角标被移除：传入属性以修改。
      if (attributes) {
        this.cylBadgeAttributes[identifier] = { ...attributes };
      }
      this.cyl_render();
    },

    /**
     * [EN] The badge value of the tab or plus button with this identifier ("•" for a dot), or '' when it has none,
     *      as -cyl_isShowBadge / -cyl_badgeValue.
     * [CN] 该标识的 Tab 或 PlusButton 的角标值（小红点为 "•"），没有角标时为 ''，对应 -cyl_isShowBadge / -cyl_badgeValue。
     */
    cyl_badgeValue(identifier) {
      const value = this.cylBadges[identifier];
      return value === undefined || value === null ? '' : String(value);
    },

    /**
     * [EN] Covers the tab with this identifier with an image (-cyl_coverVisiableTabImageViewOrTabButton:, the cover of
     *      the iOS example's first tab): the image, at `size` ("{w, h}", default 37 x 37), centered on the tab, which
     *      it hides; it stays in any selected state. '' or null removes it.
     * [CN] 用图片覆盖该标识的 Tab（-cyl_coverVisiableTabImageViewOrTabButton:，iOS 示例第一个 Tab 的封面）：图片按 `size`
     *      （"{w, h}"，默认 37 x 37）居中显示在 Tab 上并遮住该 Tab；在任何选中状态下都保持。'' 或 null 移除封面。
     */
    cyl_setCoverImage(identifier, image, size) {
      if (image) {
        this.cylCovers[identifier] = { image, size: size || '{37, 37}' };
      } else {
        delete this.cylCovers[identifier];
      }
      this.cyl_render();
    },

    /**
     * [EN] Shows a dot badge on the tab with this identifier.
     * [CN] 在该标识的 Tab 上显示小红点。
     */
    cyl_showBadgeDot(identifier) {
      this.cyl_showBadgeValue(identifier, '•');
    },

    /**
     * [EN] Removes the badge of the tab with this identifier.
     * [CN] 移除该标识的 Tab 的角标。
     */
    cyl_removeBadge(identifier) {
      delete this.cylBadges[identifier];
      delete this.cylBadgeAttributes[identifier];
      this.cyl_render();
    },

    /**
     * [EN] The item style in use: the one set by cyl_setItemStyle(), else the `itemStyle` property, else the one
     *      CYLTabBarControllerStyleType implies.
     * [CN] 当前使用的 Item 样式：cyl_setItemStyle() 设置的，否则为 `itemStyle` 属性，否则由 CYLTabBarControllerStyleType
     *      推出。
     */
    cyl_itemStyle(model) {
      const requested = this.cylRequestedItemStyle !== undefined ? this.cylRequestedItemStyle : this.data.itemStyle;
      if (requested !== '' && requested !== null && requested !== undefined) {
        return cylTabBarItemStyle(requested);
      }
      return cylTabBarItemStyleForStyleType((model || this.cylModel)?.styleType);
    },

    /**
     * [EN] Plays every tab icon animation once from progress 0 (with `animationLoop`, they repeat). The playback
     *      controls of the examples call it ("Play all").
     * [CN] 让所有 Tab 图标动画从进度 0 播放一次（开启 `animationLoop` 时重复）。示例的播放控件调用它（"Play all"）。
     */
    cyl_playAll() {
      (this.data.cylSlots || []).forEach((slot) => {
        const item = slot.item ? this.selectComponent(`#cyl-item-${slot.key}`) : null;
        if (item && typeof item.cyl_playAnimation === 'function') {
          item.cyl_playAnimation(0);
        }
      });
    },

    /**
     * [EN] Sets `hiddenIdentifiers` at run time: the tabs (or the plus button) to leave out of the bar.
     * [CN] 在运行时设置 `hiddenIdentifiers`：不在 TabBar 中显示的 Tab（或 PlusButton）。
     */
    cyl_setHiddenIdentifiers(identifiers) {
      this.setData({ hiddenIdentifiers: Array.isArray(identifiers) ? identifiers.slice() : [] });
    },

    /**
     * [EN] Hides or shows the whole bar at run time (iOS -setTabBarHidden:).
     * [CN] 在运行时隐藏或显示整个 TabBar（iOS -setTabBarHidden:）。
     */
    cyl_setTabBarHidden(hidden) {
      this.setData({ tabBarHidden: Boolean(hidden) });
    },

    /** [EN] Sets `animationSpeed` at run time. [CN] 在运行时设置 `animationSpeed`。 */
    cyl_setAnimationSpeed(speed) {
      if (Number(speed) > 0) {
        this.setData({ animationSpeed: Number(speed) });
      }
    },

    /** [EN] Sets `animationLoop` at run time. [CN] 在运行时设置 `animationLoop`。 */
    cyl_setAnimationLoop(loop) {
      this.setData({ animationLoop: Boolean(loop) });
    },

    /**
     * [EN] Switches every item to a CYLTabBarItemStyle at run time ("flat" or "liquidGlass"); '' goes back to the
     *      initial style.
     * [CN] 在运行时把所有 Item 切换为某个 CYLTabBarItemStyle（"flat" 或 "liquidGlass"）；'' 恢复初始样式。
     */
    cyl_setItemStyle(style) {
      this.cylRequestedItemStyle = style === '' || style === null ? undefined : cylTabBarItemStyle(style);
      this.cyl_render();
    },

    /**
     * [EN] Switches the Liquid Glass lens to a CYLGlassLensStyle at run time ("regular" or "skeuomorphic"); '' goes back
     *      to the `glassLensStyle` property.
     * [CN] 在运行时把液态玻璃透镜切换为某个 CYLGlassLensStyle（"regular" 或 "skeuomorphic"）；'' 恢复 `glassLensStyle`
     *      属性。
     */
    cyl_setGlassLensStyle(style) {
      this.cylRequestedGlassLensStyle = style === '' || style === null ? undefined : cylGlassLensStyle(style);
      this.cyl_render();
    },

    /**
     * [EN] Switches to a skin of CYLTabBarControllerThemes; '' goes back to the configured skin (and Dark Mode).
     * [CN] 切换到 CYLTabBarControllerThemes 中的皮肤；'' 恢复配置的皮肤（以及深色模式）。
     */
    cyl_setThemeIdentifier(identifier) {
      this.cylRequestedTheme = identifier || '';
      this.cyl_render();
    },

    /**
     * [EN] The skin in use and every skin of the configuration.
     * [CN] 当前使用的皮肤与配置中的所有皮肤。
     */
    cyl_themeIdentifiers() {
      return {
        current: this.cylModel ? this.cylModel.themeIdentifier : '',
        all: this.cylModel ? this.cylModel.themeIdentifiers : [],
      };
    },
  },
});
