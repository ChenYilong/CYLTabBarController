/**
 * [EN] Me: the demo rows (not on the first tab, AGENTS.md "Demo table rows"). Each row changes the app's tab bar
 *      state, and every tab bar instance follows it: badges, skins, the style type, the tap animation and a
 *      login-required tab.
 * [CN] 我的：演示行（不在第一个 Tab 上，见 AGENTS.md「Demo table rows」）。每一行都会修改 App 的 TabBar 状态，
 *      所有 TabBar 实例都会跟随：角标、皮肤、样式、点击动画与需要登录的 Tab。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylDemoConfiguration, cylAvailablePAGFiles } = require('../../utils/cyl_demo_configuration');

const CYL_STYLE_TYPES = ['default', 'flatDesign', 'liquidGlass'];
const CYL_TAP_ANIMATIONS = [['none', 'None'], ['bounce', 'Bounce'], ['rotation', 'Rotation'], ['scale', 'Scale']];

Component({
  behaviors: [cylTabPage],
  data: {
    skins: [],
    styleTypes: CYL_STYLE_TYPES,
    tapAnimations: [],
    state: {},
    currentStyleType: '',
    currentTapAnimation: '',
    icons: 'lottie',
    pagAvailable: false,
  },
  lifetimes: {
    attached() {
      const themes = Object.keys(cylDemoConfiguration().CYLTabBarControllerThemes || {}).sort();
      this.setData({
        skins: [''].concat(themes),
        tapAnimations: CYL_TAP_ANIMATIONS.map(([value, key]) => ({ value, label: this.t(key) })),
      });
      this.cylUnsubscribe = getApp().cyl_subscribe((state) => this.cyl_showState(state));
      this.cyl_showState(getApp().globalData.cylTabBarState);
    },
    detached() {
      if (this.cylUnsubscribe) {
        this.cylUnsubscribe();
      }
    },
  },
  methods: {
    cyl_showState(state) {
      const configuration = cylDemoConfiguration(state.overrides);
      this.setData({
        state,
        currentStyleType: configuration.CYLTabBarControllerStyleType,
        currentTapAnimation: configuration.CYLTabBarControllerTabButtonTapAnimation,
        icons: (state.overrides || {}).cylDemoIcons || ((state.overrides || {}).cylDemoLottie === false ? 'images' : 'lottie'),
        pagAvailable: cylAvailablePAGFiles().length > 0,
      });
    },
    cyl_update(change) {
      getApp().cyl_updateTabBarState(change);
    },
    cyl_override(change) {
      this.cyl_update({ overrides: Object.assign({}, getApp().globalData.cylTabBarState.overrides, change) });
    },
    cyl_badge(event) {
      const value = event.currentTarget.dataset.value;
      const badges = Object.assign({}, getApp().globalData.cylTabBarState.badges);
      if (value === 'clear') {
        Object.keys(badges).forEach((identifier) => {
          badges[identifier] = '';
        });
      } else {
        badges[event.currentTarget.dataset.identifier] = value;
      }
      this.cyl_update({ badges });
    },
    cyl_skin(event) {
      this.cyl_update({ themeIdentifier: event.currentTarget.dataset.value });
    },
    cyl_style(event) {
      this.cyl_override({ CYLTabBarControllerStyleType: event.currentTarget.dataset.value });
    },
    cyl_tapAnimation(event) {
      this.cyl_override({ CYLTabBarControllerTabButtonTapAnimation: event.currentTarget.dataset.value });
    },
    cyl_openItemPlayground() {
      wx.navigateTo({ url: '/pages/item/index' });
    },
    cyl_openPlayground() {
      wx.navigateTo({ url: '/pages/lottie/index' });
    },
    cyl_icons(event) {
      const icons = event.currentTarget.dataset.value;
      if (icons === 'pag' && !this.data.pagAvailable) {
        wx.showToast({ title: this.t('Run the PAG download first'), icon: 'none' });
        return;
      }
      const state = getApp().globalData.cylTabBarState;
      const change = { overrides: Object.assign({}, state.overrides, { cylDemoIcons: icons, cylDemoLottie: icons !== 'images' }) };
      // [EN] The Rive icons (the iOS examples' icons.riv) are white strokes: like Example-Rive and Example-SwiftUI-Rive,
      //      which run in dark mode, Rive mode picks the dark skin when no other skin was chosen.
      // [CN] Rive 图标（iOS 示例的 icons.riv）是白色线条：与运行在深色模式下的 Example-Rive、Example-SwiftUI-Rive 一样，
      //      未选择其他皮肤时，Rive 模式使用深色皮肤。
      if (icons === 'rive' && (!state.themeIdentifier || state.themeIdentifier === 'light')) {
        change.themeIdentifier = 'dark';
      }
      this.cyl_update(change);
    },
    cyl_swipeOption(event) {
      this.cyl_override({ CYLTabBarControllerSwipeToSwitchTab: event.detail.value });
    },
    cyl_boldTitles(event) {
      this.cyl_override({ cylDemoBoldTitles: event.detail.value });
    },
    cyl_loginRequired(event) {
      this.cyl_override({ CYLTabBarControllerLoginRequiredTabBarItemIdentifiers: event.detail.value ? ['me'] : [] });
      this.cyl_update({ loggedIn: !event.detail.value });
    },
  },
});
