/**
 * [EN] cyl-tab-bar: CYLTabBarController for WeChat Mini Program. A custom tab bar component that takes a
 *      CYLTabBarController configuration (the same keys as the iOS and Android libraries, docs/Configuration-File.md)
 *      and renders the tabs, a raised plus button, badges, skins and the style types. Use it inside the mini program's
 *      `custom-tab-bar` (app.json: "tabBar": {"custom": true}). Events: `select`, `reselect`, `plustap`,
 *      `loginrequired`; methods: `cyl_selectIdentifier`, `cyl_showBadgeValue`, `cyl_showBadgeDot`, `cyl_removeBadge`,
 *      `cyl_setThemeIdentifier`.
 * [CN] cyl-tab-bar：微信小程序版 CYLTabBarController。自定义 TabBar 组件，接收 CYLTabBarController 配置（与 iOS、Android
 *      库相同的键，见 docs/Configuration-File.md），渲染 Tab、凸起的 PlusButton、角标、皮肤与样式。在小程序的
 *      `custom-tab-bar` 中使用（app.json："tabBar": {"custom": true}）。事件：`select`、`reselect`、`plustap`、
 *      `loginrequired`；方法：`cyl_selectIdentifier`、`cyl_showBadgeValue`、`cyl_showBadgeDot`、`cyl_removeBadge`、
 *      `cyl_setThemeIdentifier`。
 */
const { cylReadConfiguration } = require('./cyl_configuration');
const { cylTabBarItemStyle, cylTabBarItemStyleForStyleType, cylGlassLensStyle } = require('./cyl_tab_bar_item_style');

/**
 * [EN] Heights in px from the stylesheets: the bar (index.wxss `.cyl-tab`, Liquid Glass `.cyl-style-liquidGlass .cyl-tab`),
 *      a tab's default icon and its title (cyl-tab-bar-item: 2 gap + 12 line) and the plus title (2 gap + 12 line).
 * [CN] 来自样式表的高度（px）：TabBar（index.wxss `.cyl-tab`，液态玻璃 `.cyl-style-liquidGlass .cyl-tab`）、Tab 的默认图标
 *      及其标题（cyl-tab-bar-item：间距 2 + 行 12）以及 PlusButton 标题（间距 2 + 行 12）。
 */
const CYL_BAR_HEIGHT = 50;
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
function cylTitleLine(slots) {
  const slot = slots.find((candidate) => candidate.item);
  const size = slot ? (slot.item.animationSize || slot.item.imageSize) : null;
  const match = /,\s*([\d.]+)\s*\}/.exec(size || '');
  const offset = slot && slot.item.titlePositionAdjustment ? Number(slot.item.titlePositionAdjustment.vertical) : 0;
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
  } catch (error) {
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
    'configuration, strings, symbolsByTheme, imageBasePath, animationBasePath, selectedIdentifier, appVersion, itemStyle, glassLensStyle': function () {
      this.cyl_render();
    },
  },

  lifetimes: {
    attached() {
      this.cylBadges = {};
      this.cylSystemTheme = cylSystemTheme();
      this.cylRequestedTheme = '';
      this.cylThemeListener = (result) => {
        this.cylSystemTheme = result.theme === 'dark' ? 'dark' : 'light';
        this.cyl_render();
      };
      if (typeof wx.onThemeChange === 'function') {
        wx.onThemeChange(this.cylThemeListener);
      }
      this.cyl_render();
    },
    detached() {
      if (typeof wx.offThemeChange === 'function') {
        wx.offThemeChange(this.cylThemeListener);
      }
      clearTimeout(this.cylAnimationTimer);
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
      this.cylModel = model;
      const selected = this.data.selectedIdentifier || (model.items[0] ? model.items[0].identifier : '');
      const slots = model.items.map((item) => this.cyl_slot(item, selected));
      if (model.plusButton) {
        slots.splice(model.plusButton.index, 0, this.cyl_plusSlot(model.plusButton, selected,
          this.cyl_itemStyle(model) === 'liquidGlass' ? CYL_LIQUID_GLASS_BAR_HEIGHT : CYL_BAR_HEIGHT,
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
      let styleType = model.styleType;
      if (itemStyle === 'liquidGlass') {
        styleType = 'liquidGlass';
      } else if (styleType === 'liquidGlass') {
        styleType = 'default';
      }
      this.setData({
        cylSlots: slots,
        cylItemStyle: itemStyle,
        cylGlassLensStyle: cylGlassLensStyle(this.cylRequestedGlassLensStyle !== undefined
          ? this.cylRequestedGlassLensStyle : this.data.glassLensStyle),
        cylStyleType: styleType,
        cylIsDark: model.isDark,
        cylBarStyle: model.backgroundColor ? `background-color: ${model.backgroundColor};` : '',
        cylThemeIdentifier: model.themeIdentifier,
        cylTapAnimation: model.tapAnimation,
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
        this.cyl_playLottie(selected);
      }
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
      const recordKey = `${(this.cylModel && this.cylModel.context) || ''}/${key}`;
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
      const titleFont = (fontStyle) => {
        const size = /font-size: ([\d.]+)px/.exec(fontStyle || '');
        const weight = /font-weight: (\d+)/.exec(fontStyle || '');
        const family = /font-family: "([^"]+)"/.exec(fontStyle || '');
        if (!size) {
          return undefined;
        }
        return { name: family ? family[1] : '', size: Number(size[1]), weight: weight ? cylWeightName(Number(weight[1])) : '' };
      };
      // [EN] The tab is drawn by cyl-tab-bar-item, with the iOS CYLFlatDesignTabBarItem property names.
      // [CN] Tab 由 cyl-tab-bar-item 绘制，使用 iOS CYLFlatDesignTabBarItem 的属性名。
      const itemProperties = {
        index: 0,
        title: selected ? item.selectedTitle : item.title,
        image: item.image,
        selectedImage: item.gif || item.selectedImage,
        selected,
        animationPath: lottie ? ((isDarkBar && lottie.darkPath) || lottie.path) : '',
        animationSize: lottie ? `{${lottie.width}, ${lottie.height}}` : null,
        animationColors: lottie ? ((isDarkBar && lottie.darkColors) || lottie.colors) : null,
        loopsWhenUnselected: Boolean(lottie && lottie.loopsWhenUnselected),
        imageSize: item.imageSize ? `{${item.imageSize.width}, ${item.imageSize.height}}` : null,
        imageInsets: item.imageInsets,
        titlePositionAdjustment: item.titleOffset,
        iconTint: item.iconTint,
        selectedIconTint: item.selectedIconTint,
        backgroundColor: item.backgroundColor,
        selectedBackgroundColor: item.selectedBackgroundColor,
        titleTextAttributes: {
          normal: { color: item.titleColor || '#8E8E93', font: titleFont(item.titleFontStyle) },
          selected: { color: item.selectedTitleColor || (isDarkBar ? '#0A84FF' : '#007AFF'), font: titleFont(item.selectedTitleFontStyle) },
        },
      };
      return {
        key: item.identifier,
        isPlusButton: false,
        selected,
        item: itemProperties,
        title: selected ? item.selectedTitle : item.title,
        image: selected && item.gif ? item.gif : (selected ? item.selectedImage : item.image),
        imageStyle: item.imageStyle,
        imageSizeStyle: item.imageSize ? `width: ${item.imageSize.width}px; height: ${item.imageSize.height}px;` : '',
        tint: selected ? item.selectedIconTint : item.iconTint,
        titleStyle: `${item.titleStyle}${color ? `color: ${color};` : ''}${selected ? item.selectedTitleFontStyle : item.titleFontStyle}`,
        // [EN] cyl-tab-bar-item draws the background. [CN] 背景由 cyl-tab-bar-item 绘制。
        itemStyle: '',
        badge: isDot ? '' : badge,
        showsDot: isDot,
        accessibilityLabel: badge && !isDot ? `${item.accessibilityLabel}, ${badge}` : item.accessibilityLabel,
        accessibilityIdentifier: item.accessibilityIdentifier,
      };
    },

    /**
     * [EN] Render data of the plus button: raised by CYLPlusButtonCenterYMultiplier (of a 50 pt bar) and
     *      CYLPlusButtonCenterYOffset, sized by CYLPlusButtonSize / CYLPlusButtonImageSize.
     * [CN] PlusButton 的渲染数据：按 CYLPlusButtonCenterYMultiplier（50 pt 高的 TabBar）与 CYLPlusButtonCenterYOffset
     *      凸起，尺寸由 CYLPlusButtonSize / CYLPlusButtonImageSize 决定。
     */
    cyl_plusSlot(plus, selectedIdentifier, barHeight = CYL_BAR_HEIGHT, titleLine = { iconHeight: CYL_ITEM_ICON_HEIGHT, titleOffset: 0 }) {
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
      return {
        key: plus.identifier || 'cyl-plus-button',
        isPlusButton: true,
        selected,
        showsSelection: selected && plus.showsSelection,
        title: plus.keepsTitleVisible ? (selected ? plus.selectedTitle : plus.title) : '',
        image: selected ? plus.selectedImage : plus.image,
        backgroundImage: plus.backgroundImage,
        buttonStyle: `top: ${top}px; height: ${height}px;${plus.width ? ` width: ${plus.width}px;` : ''}`,
        imageStyle: `width: ${imageWidth}px; height: ${imageHeight}px;`,
        titleStyle: `${color ? `color: ${color};` : ''}${(selected ? plus.selectedTitleFontStyle : plus.titleFontStyle) || ''}`,
        accessibilityLabel: plus.accessibilityLabel,
        accessibilityIdentifier: plus.accessibilityIdentifier,
      };
    },

    /**
     * [EN] A tap on a tab or the plus button: checks login, plays the tap animation and emits the event.
     * [CN] 点击 Tab 或 PlusButton：检查登录、播放点击动画并发出事件。
     */
    cyl_onTap(event) {
      const key = event.currentTarget.dataset.key;
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
      if (isPlusButton && !plus.hasPage) {
        this.triggerEvent('plustap', detail);
        return;
      }
      const currentIdentifier = this.data.selectedIdentifier || (model.items[0] ? model.items[0].identifier : '');
      if (item.identifier === currentIdentifier) {
        this.triggerEvent('reselect', detail);
        return;
      }
      // [EN] Select and play at once on the tapped bar; the page's own bar continues the playback (cylPlayback).
      // [CN] 在被点击的 TabBar 上立即选中并播放；页面自己的 TabBar 继续该播放（cylPlayback）。
      this.setData({ selectedIdentifier: item.identifier });
      this.triggerEvent('select', detail);
    },

    /**
     * [EN] Plays CYLTabBarControllerTabButtonTapAnimation on the tapped item.
     * [CN] 在被点击的项上播放 CYLTabBarControllerTabButtonTapAnimation。
     */
    cyl_playTapAnimation(key) {
      if (this.data.cylTapAnimation === 'none') {
        return;
      }
      clearTimeout(this.cylAnimationTimer);
      this.setData({ cylAnimatingIdentifier: '' }, () => {
        this.setData({ cylAnimatingIdentifier: key });
        this.cylAnimationTimer = setTimeout(() => this.setData({ cylAnimatingIdentifier: '' }), 1000);
      });
    },

    /**
     * [EN] CYLTabBarControllerSwipeToSwitchTab: selects the tab next to the selected one (step 1 = the next one,
     *      -1 = the previous one), skipping the plus button, by emitting `select` like a tap; does nothing when the
     *      key is off or at either end. Pages call it from a horizontal swipe (cyl_swipe_behavior.js).
     * [CN] CYLTabBarControllerSwipeToSwitchTab：选中与当前 Tab 相邻的 Tab（1 为下一个，-1 为上一个），跳过 PlusButton，
     *      像点击一样发出 `select`；该键关闭或已到两端时不做任何事。页面在水平滑动时调用（cyl_swipe_behavior.js）。
     */
    cyl_selectAdjacent(step) {
      const model = this.cylModel;
      if (!model || !model.swipeToSwitchTab) {
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
    cyl_showBadgeValue(identifier, value) {
      this.cylBadges[identifier] = value;
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
      return cylTabBarItemStyleForStyleType((model || this.cylModel || {}).styleType);
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
     * [EN] Puts the canvases of the animated icons back inside the bar. WeChat DevTools leaves them where they were
     *      during a page scroll, so they move with the gesture; cyl_scroll_behavior.js calls this while the page scrolls.
     * [CN] 让动画图标的画布回到 TabBar 内。微信开发者工具在页面滚动时会把它们留在原处，使其随手势移动；
     *      cyl_scroll_behavior.js 在页面滚动期间调用本方法。
     */
    cyl_refreshAnimationLayout() {
      (this.data.cylSlots || []).forEach((slot) => {
        const item = slot.item ? this.selectComponent(`#cyl-item-${slot.key}`) : null;
        if (item && typeof item.cyl_refreshAnimationLayout === 'function') {
          item.cyl_refreshAnimationLayout();
        }
      });
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
