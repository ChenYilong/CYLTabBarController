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

/**
 * [EN] The badge text shown for a value: numbers above 99 read "99+"; '' means no badge.
 * [CN] 角标显示的文字：大于 99 的数字显示 "99+"；'' 表示没有角标。
 */
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
    cylIsDark: false,
    cylBarStyle: '',
    cylThemeIdentifier: '',
    cylAnimatingIdentifier: '',
    cylTapAnimation: 'none',
    cylAnimationStyle: '',
  },

  observers: {
    'configuration, strings, symbolsByTheme, imageBasePath, animationBasePath, selectedIdentifier, appVersion': function () {
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
        slots.splice(model.plusButton.index, 0, this.cyl_plusSlot(model.plusButton, selected));
      }
      this.setData({
        cylSlots: slots,
        cylStyleType: model.styleType,
        cylIsDark: model.isDark,
        cylBarStyle: model.backgroundColor ? `background-color: ${model.backgroundColor};` : '',
        cylThemeIdentifier: model.themeIdentifier,
        cylTapAnimation: model.tapAnimation,
        cylAnimationStyle: `animation-duration: ${model.animationDuration}ms;`,
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
      const lottie = this.selectComponent(`#cyl-lottie-${key}`);
      if (lottie) {
        lottie.cyl_playFromStart();
      }
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
      const background = selected ? item.selectedBackgroundColor : item.backgroundColor;
      const lottie = item.lottie;
      const isDarkBar = this.cylModel ? this.cylModel.isDark : false;
      return {
        key: item.identifier,
        isPlusButton: false,
        selected,
        title: selected ? item.selectedTitle : item.title,
        image: selected && item.gif ? item.gif : (selected ? item.selectedImage : item.image),
        lottiePath: lottie ? ((isDarkBar && lottie.darkPath) || lottie.path) : '',
        lottieColors: lottie ? ((isDarkBar && lottie.darkColors) || lottie.colors) : null,
        lottieLoop: Boolean(lottie && !selected && lottie.loopsWhenUnselected),
        lottieAutoplay: Boolean(lottie && !selected && lottie.loopsWhenUnselected),
        lottieResting: selected ? 'last' : 'first',
        lottieStyle: lottie ? `width: ${lottie.width}px; height: ${lottie.height}px;` : '',
        imageStyle: item.imageStyle,
        imageSizeStyle: item.imageSize ? `width: ${item.imageSize.width}px; height: ${item.imageSize.height}px;` : '',
        tint: selected ? item.selectedIconTint : item.iconTint,
        titleStyle: `${item.titleStyle}${color ? `color: ${color};` : ''}${selected ? item.selectedTitleFontStyle : item.titleFontStyle}`,
        itemStyle: background ? `background-color: ${background};` : '',
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
    cyl_plusSlot(plus, selectedIdentifier) {
      const selected = plus.hasPage && plus.identifier === selectedIdentifier;
      const imageWidth = plus.imageWidth || plus.width || 56;
      const imageHeight = plus.imageHeight || plus.height || 56;
      const titleHeight = plus.title && plus.keepsTitleVisible ? 16 : 0;
      const height = plus.height || imageHeight + titleHeight;
      const centerY = 50 * plus.centerYMultiplier + plus.centerYOffset;
      const top = plus.alignsTitle && titleHeight ? 50 - height : centerY - imageHeight / 2;
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
      this.triggerEvent(item.identifier === currentIdentifier ? 'reselect' : 'select', detail);
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
