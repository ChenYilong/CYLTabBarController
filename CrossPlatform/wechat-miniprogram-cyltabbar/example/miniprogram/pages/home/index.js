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
  data: { sections: [] },
  lifetimes: {
    attached() {
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
      const offset = (items[0] && items[0].CYLTabBarItemTitlePositionAdjustment) || '{0, -2}';
      const loginTabs = items.filter((item) => (configuration.CYLTabBarControllerLoginRequiredTabBarItemIdentifiers || [])
        .includes(item.CYLTabBarItemIdentifier)).map((item) => this.t(item.CYLTabBarItemTitle));
      const bar = this.cyl_tabBar();
      const slots = bar ? bar.data.cylSlots : [];
      const selectedIndex = slots.findIndex((slot) => slot.selected);
      const tabIndex = slots.filter((slot) => !slot.isPlusButton).findIndex((slot) => slot.selected);
      return {
        titleOffset: `(${String(offset).replace(/[{}\s]/g, '').split(',').join(', ')})`,
        skin: state.themeIdentifier || configuration.CYLTabBarControllerThemeIdentifier || 'default',
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
      const configuration = cylDemoConfiguration(state.overrides);
      const values = this.cyl_values(state, configuration);
      const skins = Object.keys(configuration.CYLTabBarControllerThemes || {}).sort();
      const currentSkin = values.skin;
      const sections = cylDemoList.sections.map((section) => {
        const rows = section.skins
          ? skins.map((skin) => ({ id: `skin:${skin}`, title: skin, subtitle: '', accessory: 'none', selected: skin === currentSkin }))
          : section.rows.map((row) => ({
            id: row.id,
            title: cylFill(cylListText(row.title), values),
            subtitle: cylFill(cylListText(row.subtitle), values),
            accessory: row.accessory,
            checked: this.cyl_isOn(row.id, state),
          }));
        const title = section.skins
          ? cylListText(section.title).replace(/\d+/, String(skins.length)) : cylListText(section.title);
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
      this.setData({ sections });
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
      const configuration = cylDemoConfiguration(state.overrides);
      if (id.startsWith('skin:')) {
        this.cyl_update({ themeIdentifier: id.slice('skin:'.length) });
        return;
      }
      const actions = {
        language: () => wx.showToast({ title: this.t('Follows the language of WeChat'), icon: 'none' }),
        skin: () => {
          const skins = Object.keys(configuration.CYLTabBarControllerThemes || {}).sort();
          const current = state.themeIdentifier || configuration.CYLTabBarControllerThemeIdentifier;
          this.cyl_update({ themeIdentifier: skins[(skins.indexOf(current) + 1) % skins.length] });
        },
        tapAnimation: () => {
          const current = CYL_TAP_ANIMATIONS.indexOf(configuration.CYLTabBarControllerTabButtonTapAnimation);
          this.cyl_override({ CYLTabBarControllerTabButtonTapAnimation: CYL_TAP_ANIMATIONS[(current + 1) % CYL_TAP_ANIMATIONS.length] });
        },
        selectedIndex: () => {
          const bar = this.cyl_tabBar();
          if (bar) {
            bar.cyl_selectAdjacent(1);
          }
        },
        gallery: () => wx.navigateTo({ url: '/pages/glass/index' }),
        login: () => this.cyl_update({ loggedIn: !state.loggedIn }),
        swipe: () => this.cyl_override({ CYLTabBarControllerSwipeToSwitchTab: !(state.overrides || {}).CYLTabBarControllerSwipeToSwitchTab }),
      };
      if (actions[id]) {
        actions[id]();
      } else {
        wx.showToast({ title: this.t('Only in the iOS example'), icon: 'none' });
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
