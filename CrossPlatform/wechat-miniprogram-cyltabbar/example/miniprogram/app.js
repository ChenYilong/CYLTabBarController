/**
 * [EN] The example app. Every tab page has its own custom-tab-bar instance, so the tab bar state that pages change
 *      (badges, skin, configuration overrides, login) lives here, and each instance follows it through
 *      cyl_subscribe().
 * [CN] 示例 App。每个 Tab 页面都有自己的 custom-tab-bar 实例，因此页面会修改的 TabBar 状态（角标、皮肤、配置覆盖项、
 *      登录）保存在这里，每个实例通过 cyl_subscribe() 跟随它。
 */
const CYL_LOGGED_IN_KEY = 'cyl_loggedIn';

App({
  globalData: {
    cylTabBarState: {
      badges: {},
      // [EN] cyl_showBadgeValue attributes by identifier: {color, animation, radius, centerOffset}. [CN] 按标识的角标属性。
      badgeAttributes: {},
      // [EN] cyl_setCoverImage by identifier: {image, size}. [CN] 按标识的封面。
      covers: {},
      themeIdentifier: '',
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
      hidesOnScroll: false,
      tapFeedback: false,
    },
  },

  onLaunch() {
    this.cylListeners = [];
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
    try {
      this.globalData.cylTabBarState.loggedIn = Boolean(wx.getStorageSync(CYL_LOGGED_IN_KEY));
    } catch (error) {
      this.globalData.cylTabBarState.loggedIn = false;
    }
    this.cyl_decorateTabBar();
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
      try {
        wx.setStorageSync(CYL_LOGGED_IN_KEY, Boolean(change.loggedIn));
      } catch (error) {
        // [EN] Storage full or unavailable: the login lasts until the app quits. [CN] 存储已满或不可用：登录状态保留到 App 退出。
      }
    }
    this.globalData.cylTabBarState = Object.assign({}, this.globalData.cylTabBarState, change);
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
