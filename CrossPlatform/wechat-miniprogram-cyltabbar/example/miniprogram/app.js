/**
 * [EN] The example app. Every tab page has its own custom-tab-bar instance, so the tab bar state that pages change
 *      (badges, skin, configuration overrides, login) lives here, and each instance follows it through
 *      cyl_subscribe().
 * [CN] 示例 App。每个 Tab 页面都有自己的 custom-tab-bar 实例，因此页面会修改的 TabBar 状态（角标、皮肤、配置覆盖项、
 *      登录）保存在这里，每个实例通过 cyl_subscribe() 跟随它。
 */
const CYL_LOGGED_IN_KEY = 'cyl_loggedIn';
// [EN] As CYLDemoThemes (UserDefaults "CYLDemoThemeIdentifier", "CYLDemoThemeFollowsSystem"), the skin stays across launches.
// [CN] 与 CYLDemoThemes 相同（UserDefaults「CYLDemoThemeIdentifier」「CYLDemoThemeFollowsSystem」），皮肤在重新启动后保留。
const CYL_SKIN_KEY = 'cyl_skin';
const CYL_SKIN_FOLLOWS_SYSTEM_KEY = 'cyl_skinFollowsSystem';

function cylRead(key, fallback) {
  try {
    const value = wx.getStorageSync(key);
    return value === '' || value === undefined ? fallback : value;
  } catch {
    return fallback;
  }
}

function cylWrite(key, value) {
  try {
    wx.setStorageSync(key, value);
  } catch (error) {
    // [EN] Storage full or unavailable: the value lasts until the app quits. [CN] 存储已满或不可用：保留到 App 退出。
  }
}

App({
  globalData: {
    cylTabBarState: {
      badges: {},
      // [EN] cyl_showBadgeValue attributes by identifier: {color, animation, radius, centerOffset}. [CN] 按标识的角标属性。
      badgeAttributes: {},
      // [EN] cyl_setCoverImage by identifier: {image, size}. [CN] 按标识的封面。
      covers: {},
      themeIdentifier: '',
      // [EN] The skin of the skin picker (utils/cyl_demo_skins.js), following the system Dark Mode or not, and the
      //      system theme it follows. [CN] 换肤菜单的皮肤（utils/cyl_demo_skins.js）、是否跟随系统深色模式及所跟随的系统主题。
      skin: 'Default',
      skinFollowsSystem: false,
      systemTheme: 'light',
      overrides: {},
      loggedIn: false,
      // [EN] CYLTabBarItemStyle of the core ('' follows the style type). [CN] 核心层的 CYLTabBarItemStyle（'' 跟随样式）。
      itemStyle: '',
      // [EN] CYLGlassLensStyle of the Liquid Glass lens. [CN] 液态玻璃透镜的 CYLGlassLensStyle。
      glassLensStyle: 'regular',
      // [EN] Playback controls of the tab icon animations (docs/Tab-Icon-Animation-Quick-Start.md). [CN] Tab 图标动画的播放控件。
      animationSpeed: 1,
      animationLoop: false,
      // [EN] Tabs left out of every bar (cyl-tab-bar hiddenIdentifiers), e.g. by user role. [CN] 所有 TabBar 都不显示的 Tab（cyl-tab-bar 的 hiddenIdentifiers），例如按用户角色。
      hiddenIdentifiers: [],
      // [EN] Home rows: every bar hidden, the bar hidden while the page scrolls down, haptics on taps.
      // [CN] 首页各行：隐藏所有 TabBar、页面向下滚动时隐藏 TabBar、点击时振动。
      tabBarHidden: false,
      // [EN] CYLTabBarMinimizeBehavior of the Home row (Automatic, OnScrollDown, OnScrollUp, Never). [CN] 首页行的滚动行为。
      scrollBehavior: 'Automatic',
      tapFeedback: false,
    },
  },

  onLaunch() {
    // [EN] First the state every tab bar instance subscribes to: a module that fails to load below must not leave the app
    //      without it (the custom tab bar's cyl_subscribe pushes to cylListeners).
    // [CN] 先创建每个 TabBar 实例订阅的状态：下面的模块加载失败时不能让 App 缺少它（custom-tab-bar 的 cyl_subscribe 会向
    //      cylListeners 添加监听）。
    this.cylListeners = [];
    // [EN] The tab icon animations pause while the user scrolls a page (pages report it with cylPageScrolled).
    // [CN] 用户滚动页面时 Tab 图标动画暂停（页面通过 cylPageScrolled 报告滚动）。
    try {
      require('cyl-tabbar-miniprogram/cyl-animated-item/cyl_animation_events').cylPausesAnimationsWhileUserScrolls(true);
    } catch (error) {
      console.error('cyl_animation_events failed to load', error);
    }
    // [EN] The Rive icons (the iOS examples' icons.riv) are white strokes: with the Rive package installed, the example
    //      starts on the dark skin, as Example-Rive and Example-SwiftUI-Rive run in dark mode.
    // [CN] Rive 图标（iOS 示例的 icons.riv）是白色线条：安装 Rive 包时示例以深色皮肤启动，与运行在深色模式下的
    //      Example-Rive、Example-SwiftUI-Rive 一致。
    const { cylInstalledAnimation } = require('./utils/cyl_demo_configuration');
    if (cylInstalledAnimation() === 'rive') {
      this.globalData.cylTabBarState.themeIdentifier = 'dark';
    }
    // [EN] As `cyl_loggedIn` of the Objective-C example, the login (issue #19) stays across launches.
    // [CN] 与 Objective-C 示例的 `cyl_loggedIn` 相同，登录状态（issue #19）在重新启动后保留。
    const state = this.globalData.cylTabBarState;
    state.loggedIn = Boolean(cylRead(CYL_LOGGED_IN_KEY, false));
    state.skin = String(cylRead(CYL_SKIN_KEY, 'Default'));
    state.skinFollowsSystem = Boolean(cylRead(CYL_SKIN_FOLLOWS_SYSTEM_KEY, false));
    try {
      const info = typeof wx.getAppBaseInfo === 'function' ? wx.getAppBaseInfo() : wx.getSystemInfoSync();
      state.systemTheme = info.theme === 'dark' ? 'dark' : 'light';
    } catch {
      state.systemTheme = 'light';
    }
    if (typeof wx.onThemeChange === 'function') {
      wx.onThemeChange((result) => this.cyl_updateTabBarState({ systemTheme: result.theme === 'dark' ? 'dark' : 'light' }));
    }
    this.cyl_decorateTabBar();
    // [EN] CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning: a real memory warning unloads too.
    // [CN] 真实的内存警告同样卸载未选中的 Tab。
    if (typeof wx.onMemoryWarning === 'function') {
      wx.onMemoryWarning(() => this.cyl_simulateMemoryWarning());
    }
  },

  /**
   * [EN] UIViewController+CYLMemoryWarning (docs/ObjC-Example-Parity item 12): unloads the views of the unselected tab
   *      pages, except Home (-shouldUnloadViewOfViewController: returns NO for it), and returns one line per tab,
   *      "<title>: <status>", as CYLSimulateMemoryWarningReport. `tabs`: [{title, route, selected}] in bar order.
   * [CN] UIViewController+CYLMemoryWarning（第 12 项）：卸载未选中 Tab 页面的视图，首页除外（-shouldUnloadViewOfViewController:
   *      对它返回 NO），并按 CYLSimulateMemoryWarningReport 每个 Tab 返回一行「<标题>: <状态>」。`tabs`：按 TabBar 顺序的
   *      [{title, route, selected}]。
   */
  cyl_simulateMemoryWarning(tabs, translate) {
    const t = translate || ((text) => text);
    const loaded = this.cylLoadedTabPages || {};
    const pages = tabs || Object.keys(loaded).map((route) => ({ title: route, route, selected: false }));
    return pages.map((tab) => {
      let status;
      if (tab.selected) {
        status = t('kept: selected');
      } else if (tab.route === 'pages/home/index') {
        status = t('kept: shouldUnload returned NO');
      } else if (loaded[tab.route] && !loaded[tab.route].data.cylUnloaded) {
        status = loaded[tab.route].cyl_unloadView() ? t('unloaded') : t('not loaded');
      } else {
        status = t('not loaded');
      }
      return `${tab.title}: ${status}`;
    }).join('\n');
  },

  /**
   * [EN] -[CYLMainRootViewController createFlatDesignTabBar] / -createNewTabBarWithContext: (docs/ObjC-Example-Parity
   *      items 7, 8): the navigation bar buttons replace the tab bar with a new one in `styleType` ("flatDesign" or
   *      "liquidGlass"): its own state again (no badges, the first tab, the configuration's values), then the launch
   *      badges 1.5 s later. The skin and the login belong to the app and stay.
   * [CN] -[CYLMainRootViewController createFlatDesignTabBar] / -createNewTabBarWithContext:（第 7、8 项）：导航栏按钮用
   *      `styleType`（"flatDesign" 或 "liquidGlass"）的新 TabBar 替换当前 TabBar：恢复其自身状态（无角标、第一个 Tab、
   *      配置中的值），1.5 秒后再次显示启动角标。皮肤与登录状态属于整个 App，保持不变。
   */
  cyl_rebuildTabBar(styleType) {
    clearTimeout(this.cylCoverTimer);
    this.cyl_updateTabBarState({
      badges: {},
      badgeAttributes: {},
      covers: { home: null },
      overrides: { CYLTabBarControllerStyleType: styleType },
      itemStyle: '',
      hiddenIdentifiers: [],
      tabBarHidden: false,
      scrollBehavior: 'Automatic',
      tapFeedback: false,
    });
    wx.switchTab({ url: '/pages/home/index' });
    this.cyl_decorateTabBar();
  },

  /**
   * [EN] CYLDemoThemes.apply: a skin picked by hand stops following the system. As the Objective-C example, the cover
   *      goes on again after the new icons (1.5 s; 4 s for the network skin, whose icons download).
   * [CN] CYLDemoThemes.apply：手动选择皮肤后不再跟随系统。与 Objective-C 示例相同，封面在新图标之后重新加上
   *      （1.5 秒；网络皮肤需要下载图标，为 4 秒）。
   */
  cyl_setSkin(name) {
    cylWrite(CYL_SKIN_KEY, name);
    cylWrite(CYL_SKIN_FOLLOWS_SYSTEM_KEY, false);
    this.cyl_updateTabBarState({ skin: name, skinFollowsSystem: false });
    this.cyl_coverAgain(name === 'Network icons' ? 4000 : 1500);
  },

  /**
   * [EN] CYLDemoThemes.setFollowsSystem. [CN] 跟随系统深色模式。
   */
  cyl_setSkinFollowsSystem(followsSystem) {
    cylWrite(CYL_SKIN_FOLLOWS_SYSTEM_KEY, Boolean(followsSystem));
    this.cyl_updateTabBarState({ skinFollowsSystem: Boolean(followsSystem) });
    this.cyl_coverAgain(1500);
  },

  cyl_coverAgain(delay) {
    const covers = this.globalData.cylTabBarState.covers || {};
    if (!covers.home) {
      return;
    }
    this.cyl_updateTabBarState({ covers: { ...covers, home: null } });
    clearTimeout(this.cylCoverTimer);
    this.cylCoverTimer = setTimeout(() => {
      this.cyl_updateTabBarState({ covers: { ...this.globalData.cylTabBarState.covers, home: covers.home } });
    }, delay);
  },

  /**
   * [EN] -[MainTabBarController cyl_demo_decorateTabBarController:] (docs/ObjC-Example-Parity items 2, 5, 6): 1.5 s after
   *      launch, the tab badges (Home: a breathing dot in a random color, radius 5.5; Nearby: a purple 8 that scales;
   *      Messages: 100, shown as 99+, bouncing; Me: NEW, breathing, moved by (-1, 3)), the plus button's badge 1
   *      (bounce), and the cover over Home, which hides its dot at once as on iOS.
   * [CN] -[MainTabBarController cyl_demo_decorateTabBarController:]（docs/ObjC-Example-Parity 第 2、5、6 项）：启动 1.5 秒后
   *      显示 Tab 角标（首页：随机颜色的呼吸红点，半径 5.5；同城：缩放的紫色 8；消息：100，显示为 99+，弹跳；我的：NEW，
   *      呼吸，偏移 (-1, 3)）、PlusButton 角标 1（弹跳），以及首页的封面，与 iOS 一样随即遮住首页的红点。
   */
  cyl_decorateTabBar() {
    clearTimeout(this.cylDecorateTimer);
    this.cylDecorateTimer = setTimeout(() => {
      const randomColor = `#${Math.floor(Math.random() * 0xffffff).toString(16).padStart(6, '0')}`;
      this.cyl_updateTabBarState({
        badges: { home: '•', city: '8', message: '100', CYLMineViewController: 'NEW', plus: '1' },
        badgeAttributes: {
          home: { color: randomColor, radius: 5.5, animation: 'breathe' },
          city: { color: '#AF52DE', animation: 'scale' },
          message: { animation: 'bounce' },
          CYLMineViewController: { animation: 'breathe', centerOffset: [-1, 3] },
          plus: { animation: 'bounce' },
        },
        covers: { home: { image: '/shared/objc/home_select_cover.png', size: '{37, 37}' } },
      });
    }, 1500);
  },

  /**
   * [EN] Merges a change into the tab bar state and tells every custom-tab-bar instance.
   * [CN] 把修改合并到 TabBar 状态中，并通知每个 custom-tab-bar 实例。
   */
  cyl_updateTabBarState(change) {
    if ('loggedIn' in change && change.loggedIn !== this.globalData.cylTabBarState.loggedIn) {
      cylWrite(CYL_LOGGED_IN_KEY, Boolean(change.loggedIn));
    }
    this.globalData.cylTabBarState = { ...this.globalData.cylTabBarState, ...change };
    this.cylListeners.forEach((listener) => listener(this.globalData.cylTabBarState));
  },

  /**
   * [EN] Adds a listener of the tab bar state; returns the function that removes it.
   * [CN] 添加 TabBar 状态的监听者；返回移除它的函数。
   */
  cyl_subscribe(listener) {
    this.cylListeners.push(listener);
    return () => {
      this.cylListeners = this.cylListeners.filter((candidate) => candidate !== listener);
    };
  },
});
