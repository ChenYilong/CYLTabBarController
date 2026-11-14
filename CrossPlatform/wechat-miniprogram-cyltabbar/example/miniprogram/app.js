/**
 * [EN] The example app. Every tab page has its own custom-tab-bar instance, so the tab bar state that pages change
 *      (badges, skin, configuration overrides, login) lives here, and each instance follows it through
 *      cyl_subscribe().
 * [CN] 示例 App。每个 Tab 页面都有自己的 custom-tab-bar 实例，因此页面会修改的 TabBar 状态（角标、皮肤、配置覆盖项、
 *      登录）保存在这里，每个实例通过 cyl_subscribe() 跟随它。
 */
App({
  globalData: {
    cylTabBarState: {
      badges: {},
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
  },

  /**
   * [EN] Merges a change into the tab bar state and tells every custom-tab-bar instance.
   * [CN] 把修改合并到 TabBar 状态中，并通知每个 custom-tab-bar 实例。
   */
  cyl_updateTabBarState(change) {
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
