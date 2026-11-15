/**
 * [EN] Home: the table of the Objective-C example's first tab (Example/Classes/Module/Home/CYLHomeViewController), as
 *      AGENTS.md "Demo table rows" asks: the shared demo sections (UIViewController+CYLSettingsSection), the Tab Bar
 *      Gallery row and the badge rows, in the same order, from Example-Shared/DemoList/demo-list.json (shared/demo_list.js,
 *      made by scripts/cyl_sync_shared.js). Rows the mini program supports act on the app's tab bar state; the others
 *      say they are only in the iOS example.
 * [CN] 首页：Objective-C 示例第一个 Tab 的表格（Example/Classes/Module/Home/CYLHomeViewController），遵循 AGENTS.md
 *      「Demo table rows」：共用的演示 section（UIViewController+CYLSettingsSection）、Tab Bar Gallery 行与角标行，顺序相同，
 *      数据来自 Example-Shared/DemoList/demo-list.json（shared/demo_list.js，由 scripts/cyl_sync_shared.js 生成）。小程序支持的
 *      行会修改 App 的 TabBar 状态；其他行提示仅 iOS 示例提供。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylLanguage } = require('../../utils/cyl_demo_localization');
const { cylDemoConfiguration } = require('../../utils/cyl_demo_configuration');
const cylDemoList = require('../../shared/demo_list');
const { cylHomeAction } = require('../../utils/cyl_home_actions');
const { CYL_DEMO_SKINS, cylEffectiveSkin, cylSkinSummary, cylSkinPreview } = require('../../utils/cyl_demo_skins');

// [EN] UIColor.cyl_randomColor. [CN] 随机颜色。
const cylRandomColor = () => `#${Math.floor(Math.random() * 0xffffff).toString(16).padStart(6, '0')}`;

/**
 * [EN] The navigation bar's frame: below the status bar, as tall as the capsule plus its margins, the capsule's room
 *      kept free on the right; the menu's height leaves the tab bar free.
 * [CN] 导航栏的位置：位于状态栏下方，高度为胶囊按钮加上下边距，右侧留出胶囊按钮的位置；菜单高度不遮住 TabBar。
 */
function cylNavigationFrame() {
  try {
    const window = typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync();
    const capsule = wx.getMenuButtonBoundingClientRect();
    const top = window.statusBarHeight || 20;
    const height = capsule.height + (capsule.top - top) * 2;
    return { top, height, right: window.windowWidth - capsule.left + 8, menuHeight: window.windowHeight - top - height - 150 };
  } catch (error) {
    return { top: 20, height: 44, right: 100, menuHeight: 400 };
  }
}

// [EN] The tap animations the mini program has, in the order the row cycles through them. [CN] 小程序支持的点击动画，按本行切换的顺序。
const CYL_TAP_ANIMATIONS = ['none', 'bounce', 'rotation', 'scale'];

// [EN] Badge animations drawn in CSS (index.wxss); the others show a still badge. [CN] 用 CSS 绘制的角标动画（index.wxss）；其他为静止角标。
const CYL_BADGE_ANIMATIONS = ['scale', 'shake', 'bounce', 'breathe', 'rotation'];

/**
 * [EN] A demo-list text in the current language (the example's languages; English otherwise).
 * [CN] 演示列表文字的当前语言版本（示例支持的语言；否则为英文）。
 */
function cylListText(text) {
  const table = cylDemoList.strings[cylLanguage(cylDemoList.strings)] || {};
  return table[text] || text;
}

/**
 * [EN] `text` with every {name} filled from `values` ("—" for the ones the mini program does not have).
 * [CN] 用 `values` 填入 `text` 中的每个 {name}（小程序没有的值显示为「—」）。
 */
function cylFill(text, values) {
  return text.replace(/\{(\w+)\}/g, (match, name) => (values[name] !== undefined ? String(values[name]) : '—'));
}

Component({
  behaviors: [cylTabPage],
  data: { sections: [], nav: { top: 20, height: 44, right: 100, menuHeight: 400, dots: [] }, navigationTitle: '', skinMenu: null },
  lifetimes: {
    attached() {
      // [EN] -[CYLHomeViewController viewDidLoad]: dots in random colors on "Flat Design" and "Liquid Glass".
      // [CN] 「Flat Design」与「Liquid Glass」按钮上的随机颜色红点。
      this.setData({ nav: Object.assign(cylNavigationFrame(), { dots: [cylRandomColor(), cylRandomColor()] }) });
      this.cylUnsubscribe = getApp().cyl_subscribe(() => this.cyl_render());
    },
    detached() {
      if (this.cylUnsubscribe) {
        this.cylUnsubscribe();
      }
    },
  },
  pageLifetimes: {
    show() {
      this.cyl_render();
    },
  },
  methods: {
    /**
     * [EN] The values of the {name} parts, from the app's tab bar state and its configuration.
     * [CN] {name} 部分的取值，来自 App 的 TabBar 状态及其配置。
     */
    cyl_values(state, configuration) {
      const items = configuration.CYLTabBarControllerTabBarItemsAttributes || [];
      // [EN] Item 13: the bar's titlePositionAdjustment, "(%g, %g)". [CN] 第 13 项：TabBar 的 titlePositionAdjustment，「(%g, %g)」。
      const offset = /\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}/.exec(String(configuration.CYLTabBarControllerTitlePositionAdjustment || '{0, 0}'));
      const loginTabs = items.filter((item) => (configuration.CYLTabBarControllerLoginRequiredTabBarItemIdentifiers || [])
        .includes(item.CYLTabBarItemIdentifier)).map((item) => this.t(item.CYLTabBarItemTitle));
      const bar = this.cyl_tabBar();
      const slots = bar ? bar.data.cylSlots : [];
      const selectedIndex = slots.findIndex((slot) => slot.selected);
      const tabIndex = slots.filter((slot) => !slot.isPlusButton).findIndex((slot) => slot.selected);
      return {
        titleOffset: offset ? `(${Number(offset[1])}, ${Number(offset[2])})` : '(0, 0)',
        // [EN] Item 14: the standardAppearance theme's name. [CN] 第 14 项：standardAppearance 主题名。
        appearance: this.t((state.overrides || {}).cylDemoAppearance || 'Original'),
        // [EN] Item 16: the code name, not translated, as iOS. [CN] 第 16 项：代码名，与 iOS 一样不翻译。
        scrollBehavior: state.scrollBehavior || 'Automatic',
        // [EN] cyl_themeSettingsCell: the skin, " · Follow the system Dark Mode" when it does. [CN] 当前皮肤；跟随系统时加上「 · 跟随系统深色模式」。
        skin: this.t(cylEffectiveSkin(state).name) + (state.skinFollowsSystem ? ` · ${this.t('Follow the system Dark Mode')}` : ''),
        login: this.t(state.loggedIn ? 'Logged in' : 'Logged out'),
        loginTabs: loginTabs.join(', ') || '—',
        tapAnimation: configuration.CYLTabBarControllerTabButtonTapAnimation || 'none',
        indexWithoutPlus: tabIndex < 0 ? '-' : tabIndex,
        selectedIndex: selectedIndex < 0 ? '-' : selectedIndex,
        selectedTitle: selectedIndex < 0 ? '-' : (slots[selectedIndex].item ? slots[selectedIndex].item.title : slots[selectedIndex].title) || '-',
      };
    },

    cyl_tabBar() {
      const tabBar = typeof this.getTabBar === 'function' ? this.getTabBar() : null;
      return tabBar ? tabBar.selectComponent('#cyl-tab-bar') : null;
    },

    cyl_render() {
      const state = getApp().globalData.cylTabBarState;
      const skin = cylEffectiveSkin(state);
      const configuration = cylDemoConfiguration(state.overrides, skin);
      const values = this.cyl_values(state, configuration);
      const sections = cylDemoList.sections.map((section) => {
        // [EN] Issue #216: every skin, one row each (cyl_themeListCell): name, what it changes, icon or swatch, a check on the current one.
        // [CN] Issue #216：所有皮肤，每行一个（cyl_themeListCell）：名字、修改的内容、图标或色块，当前皮肤带勾号。
        const rows = section.skins
          ? CYL_DEMO_SKINS.map((candidate) => ({
            id: `skin:${candidate.name}`,
            title: this.t(candidate.name),
            subtitle: this.t(cylSkinSummary(candidate)),
            preview: cylSkinPreview(candidate),
            accessory: candidate.name === skin.name ? 'check' : 'none',
          }))
          : section.rows.map((row) => this.cyl_row(row, values, state, configuration));
        const title = section.skins
          ? this.t('Skins: holidays and colors (%@)').replace('%@', String(CYL_DEMO_SKINS.length)) : cylListText(section.title);
        return { id: section.id, title, rows };
      });
      // [EN] The badge rows of CYLHomeViewController, after the demo sections. [CN] CYLHomeViewController 的角标行，在演示 section 之后。
      sections.push({
        id: 'badges',
        title: this.t('Badges'),
        badges: cylDemoList.badgeSamples.map((sample, index) => ({
          key: index,
          title: cylListText(sample.title),
          text: this.cyl_badgeText(sample),
          dot: !sample.value,
          animation: CYL_BADGE_ANIMATIONS.find((name) => sample.animation && sample.animation.startsWith(name)) || '',
          style: this.cyl_badgeStyle(sample),
          position: sample.position || 'topRight',
        })),
      });
      // [EN] MainTabBarController: the first page's title gets " (Liquid)" on Liquid Glass; a badge row sets "Home (N)".
      // [CN] MainTabBarController：液态玻璃下第一个页面的标题加上「 (Liquid)」；角标行设为「首页(N)」。
      const liquidGlass = state.itemStyle ? state.itemStyle === 'liquidGlass' : configuration.CYLTabBarControllerStyleType === 'liquidGlass';
      const navigationTitle = this.cylBadgeTitle || (liquidGlass ? `${this.t('Home')} (Liquid)` : this.t('Home'));
      this.setData({ sections, navigationTitle, skinMenu: this.data.skinMenu ? this.cyl_skinMenuRows(state) : null });
    },

    // [EN] -[CYLHomeViewController flatDesignTabBar:]. [CN] 用新的扁平样式 TabBar 替换当前 TabBar。
    cyl_onFlatDesign() {
      this.cylBadgeTitle = '';
      getApp().cyl_rebuildTabBar('flatDesign');
    },

    // [EN] -[CYLHomeViewController refreshTabBar:]. [CN] 重新创建液态玻璃 TabBar。
    cyl_onLiquidGlass() {
      this.cylBadgeTitle = '';
      getApp().cyl_rebuildTabBar('liquidGlass');
    },

    // [EN] -[CYLHomeViewController showThemePicker:]. [CN] 打开换肤菜单。
    cyl_onSkinButton() {
      this.setData({ skinMenu: this.cyl_skinMenuRows(getApp().globalData.cylTabBarState) });
    },

    cyl_closeSkinMenu() {
      this.setData({ skinMenu: null });
    },

    /**
     * [EN] The menu rows (cyl_themeMenuElements): every skin with its icon or swatch, a check on the current one (none
     *      while following the system), then "Follow the system Dark Mode".
     * [CN] 菜单行（cyl_themeMenuElements）：每个皮肤及其图标或色块，当前皮肤带勾号（跟随系统时不带），然后是「跟随系统深色模式」。
     */
    cyl_skinMenuRows(state) {
      const current = cylEffectiveSkin(state).name;
      return CYL_DEMO_SKINS.map((skin) => ({
        id: skin.name,
        title: this.t(skin.name),
        preview: cylSkinPreview(skin),
        checked: !state.skinFollowsSystem && skin.name === current,
      })).concat([{ id: 'system', title: this.t('Follow the system Dark Mode'), preview: { swatch: '#8E8E93', glyph: '◐' }, checked: Boolean(state.skinFollowsSystem) }]);
    },

    cyl_onSkinMenuRow(event) {
      const id = event.currentTarget.dataset.id;
      const app = getApp();
      this.setData({ skinMenu: null });
      if (id === 'system') {
        app.cyl_setSkinFollowsSystem(!app.globalData.cylTabBarState.skinFollowsSystem);
      } else {
        app.cyl_setSkin(id);
      }
    },

    /**
     * [EN] A demo row: its texts with the current values, a checkmark on the update rows that are on
     *      (UIViewController+CYLTabBarItemUpdate.swift), and the FlatDesign-only rows dimmed with their note outside
     *      FlatDesign (CYLFlatDesignTableViewController).
     * [CN] 演示行：带当前值的文字；已开启的更新行带勾号（UIViewController+CYLTabBarItemUpdate.swift）；非扁平样式下，
     *      仅扁平样式支持的行变灰并显示说明（CYLFlatDesignTableViewController）。
     */
    cyl_row(row, values, state, configuration) {
      const updates = (state.overrides || {}).cylDemoUpdates || {};
      const on = {
        changeTabTitle: updates.changeTabTitle,
        switchTabIcon: updates.homeIcon === 'custom',
        downloadNetworkIcon: updates.homeIcon === 'network',
        gifIcon: updates.homeIcon === 'gif',
        allNetworkIcons: updates.allIcons === 'network',
        allLocalIcons: updates.allIcons === 'local',
        allTitles: updates.allTitles,
      };
      const flatOnly = row.id === 'flatBackground';
      const unsupported = flatOnly && configuration.CYLTabBarControllerStyleType !== 'flatDesign';
      return {
        id: row.id,
        title: cylFill(cylListText(row.title), values),
        subtitle: flatOnly && !unsupported ? '' : cylFill(cylListText(row.subtitle), values),
        accessory: row.id in on ? (on[row.id] ? 'check' : 'none') : row.accessory,
        checked: this.cyl_isOn(row.id, state),
        dimmed: unsupported,
      };
    },

    // [EN] Switch rows that the mini program has. [CN] 小程序支持的开关行。
    cyl_isOn(id, state) {
      if (id === 'login') {
        return Boolean(state.loggedIn);
      }
      if (id === 'swipe') {
        return Boolean((state.overrides || {}).CYLTabBarControllerSwipeToSwitchTab);
      }
      return false;
    },

    cyl_badgeText(sample) {
      const maximum = sample.maximum || 99;
      const number = Number(sample.value);
      return Number.isFinite(number) && sample.value !== '' && number > maximum ? `${maximum}+` : sample.value;
    },

    cyl_badgeStyle(sample) {
      let style = '';
      if (sample.color) {
        style += `background-color: ${sample.color};`;
      }
      if (sample.textColor) {
        style += `color: ${sample.textColor};`;
      }
      if (sample.italic) {
        style += 'font-style: italic;';
      }
      if (sample.fontSize) {
        style += `font-size: ${sample.fontSize}px;`;
      }
      if (sample.borderWidth) {
        style += `border: ${sample.borderWidth}px solid ${sample.borderColor === 'dynamic' ? 'var(--cyl-background, #ffffff)' : sample.borderColor};`;
      }
      if (sample.radius) {
        style += `width: ${sample.radius * 2}px; height: ${sample.radius * 2}px;`;
      }
      if (sample.margin) {
        style += `padding: 0 ${sample.margin / 2}px;`;
      }
      if (sample.cornerRadius) {
        style += `border-radius: ${sample.cornerRadius}px;`;
      }
      return style;
    },

    cyl_update(change) {
      getApp().cyl_updateTabBarState(change);
    },

    cyl_override(change) {
      this.cyl_update({ overrides: Object.assign({}, getApp().globalData.cylTabBarState.overrides, change) });
    },

    cyl_onRow(event) {
      const id = event.currentTarget.dataset.id;
      const state = getApp().globalData.cylTabBarState;
      const configuration = cylDemoConfiguration(state.overrides, cylEffectiveSkin(state));
      if (id.startsWith('skin:')) {
        getApp().cyl_setSkin(id.slice('skin:'.length));
        return;
      }
      const actions = {
        language: () => wx.showToast({ title: this.t('Follows the language of WeChat'), icon: 'none' }),
        // [EN] cyl_presentThemePickerFromView:completion: (issue #216). [CN] 打开换肤菜单（issue #216）。
        skin: () => this.cyl_onSkinButton(),
        tapAnimation: () => {
          const current = CYL_TAP_ANIMATIONS.indexOf(configuration.CYLTabBarControllerTabButtonTapAnimation);
          this.cyl_override({ CYLTabBarControllerTabButtonTapAnimation: CYL_TAP_ANIMATIONS[(current + 1) % CYL_TAP_ANIMATIONS.length] });
        },
        // [EN] Item 28: cyl_selectedIndexIgnoringPlusButton = (current + 1) % count: the next tab without the plus
        //      button, back to the first after the last. [CN] 第 28 项：选中不含 PlusButton 的下一个 Tab，最后一个之后回到第一个。
        selectedIndex: () => {
          const bar = this.cyl_tabBar();
          if (!bar) {
            return;
          }
          const tabs = bar.data.cylSlots.filter((slot) => !slot.isPlusButton);
          const current = tabs.findIndex((slot) => slot.selected);
          const next = tabs[current < 0 ? 0 : (current + 1) % tabs.length];
          bar.cyl_onTap({ currentTarget: { dataset: { key: next.key } } });
        },
        gallery: () => wx.navigateTo({ url: '/pages/glass/index' }),
        login: () => this.cyl_update({ loggedIn: !state.loggedIn }),
        swipe: () => this.cyl_override({ CYLTabBarControllerSwipeToSwitchTab: !(state.overrides || {}).CYLTabBarControllerSwipeToSwitchTab }),
      };
      if (actions[id]) {
        actions[id]();
      } else {
        cylHomeAction(id)(this.cyl_actionContext(id));
      }
    },

    /**
     * [EN] What the actions of utils/cyl_home_actions.js may use.
     * [CN] utils/cyl_home_actions.js 中各行为可以使用的接口。
     */
    cyl_actionContext(id) {
      const app = getApp();
      const row = this.data.sections.reduce((found, section) => found
        || (section.rows || []).find((candidate) => candidate.id === id), null) || { title: id, subtitle: '' };
      return {
        state: () => app.globalData.cylTabBarState,
        overrides: () => app.globalData.cylTabBarState.overrides || {},
        configuration: () => cylDemoConfiguration(app.globalData.cylTabBarState.overrides, cylEffectiveSkin(app.globalData.cylTabBarState)),
        update: (change) => this.cyl_update(change),
        override: (change) => this.cyl_override(change),
        tabBar: () => this.cyl_tabBar(),
        toast: (title) => wx.showToast({ title, icon: 'none' }),
        open: (caseId) => wx.navigateTo({
          url: `/pages/demo/index?id=${encodeURIComponent(caseId)}&title=${encodeURIComponent(row.title)}&subtitle=${encodeURIComponent(row.subtitle || '')}`,
        }),
      };
    },

    /**
     * [EN] A badge row: shows its sample badge on the Discover tab (tap again to remove it).
     * [CN] 角标行：在「发现」Tab 上显示该示例角标（再次点击移除）。
     */
    // [EN] CYLHomeViewController: the navigation title becomes "Home (N)", then an orange page without navigation bar is pushed.
    // [CN] CYLHomeViewController：导航标题变为「首页(N)」，然后 push 一个无导航栏的橙色页面。
    cyl_onBadge(event) {
      const index = Number(event.currentTarget.dataset.index);
      this.cylBadgeTitle = this.t('Home (%@)').replace('%@', index);
      this.setData({ navigationTitle: this.cylBadgeTitle });
      wx.navigateTo({ url: `/pages/pushed/index?color=orange&note=${encodeURIComponent('Pushed by Home: the navigation bar is hidden')}` });
    },

    /**
     * [EN] The Home row "Minimize / hide the TabBar on scroll": down hides the bar, up shows it.
     * [CN] 首页「滚动时隐藏 TabBar」行：向下滚动隐藏，向上显示。
     */
    onPageScroll(event) {
      const state = getApp().globalData.cylTabBarState;
      const top = event.scrollTop;
      const last = this.cylLastScrollTop || 0;
      this.cylLastScrollTop = top;
      // [EN] Item 16: OnScrollDown hides on a scroll down and shows on a scroll up, OnScrollUp the other way; Automatic
      //      and Never leave the bar (on iOS Liquid Glass the system minimizes the bar instead of hiding it).
      // [CN] 第 16 项：OnScrollDown 向下滚动隐藏、向上显示，OnScrollUp 相反；Automatic 与 Never 不改变 TabBar（iOS 液态
      //      玻璃下由系统缩小 TabBar 而不是隐藏）。
      const behavior = state.scrollBehavior || 'Automatic';
      if ((behavior !== 'OnScrollDown' && behavior !== 'OnScrollUp') || Math.abs(top - last) < 8) {
        return;
      }
      const down = top > last && top > 60;
      const hidden = behavior === 'OnScrollDown' ? down : !down && top > 60;
      if (hidden !== Boolean(state.tabBarHidden)) {
        this.cyl_update({ tabBarHidden: hidden });
      }
    },

    // [EN] A tap on a switch stays on the switch (its change event acts). [CN] 点击开关不传给所在行（由其 change 事件处理）。
    cyl_noop() {},

    // [EN] A switch was flipped: the same as tapping its row. [CN] 拨动开关：与点击该行相同。
    cyl_onSwitch(event) {
      this.cyl_onRow(event);
    },
  },
});
