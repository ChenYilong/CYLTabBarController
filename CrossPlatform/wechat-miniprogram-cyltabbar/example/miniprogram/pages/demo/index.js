/**
 * [EN] The demo page of a Home row (utils/cyl_demo_cases.js): the note, the input, the result, buttons and a live
 *      cyl-tab-bar for the case.
 * [CN] 首页某一行的演示页（utils/cyl_demo_cases.js）：说明、输入、结果、按钮，以及该用例的实时 cyl-tab-bar。
 */
const cylTabPage = require('../../utils/cyl_tab_page');
const { cylPageScrolled } = require('../../utils/cyl_scroll_pause');
const { cylDemoCase } = require('../../utils/cyl_demo_cases');

Component({
  behaviors: [cylTabPage],
  data: { title: '', subtitle: '', demo: {}, result: '', actions: [], selectedIdentifier: 'home', barHidden: false, slideIndex: 0, slideTitles: ['Home', 'Message', 'Discover', 'Me'] },
  methods: {
    onLoad(query) {
      const id = decodeURIComponent(query.id || '');
      this.cylCase = cylDemoCase(id);
      const { actions = [], ...demo } = this.cylCase;
      const title = decodeURIComponent(query.title || id);
      wx.setNavigationBarTitle({ title });
      this.setData({ title, subtitle: decodeURIComponent(query.subtitle || ''), demo, result: demo.result || '', actions: actions.map((action) => action.label) });
    },

    cyl_runAction(event) {
      this.cylCase.actions[event.currentTarget.dataset.index].run(this);
    },

    cylSelect(event) {
      const identifier = event.detail.identifier;
      const index = this.data.slideTitles.findIndex((title) => title.toLowerCase() === identifier);
      this.setData({ selectedIdentifier: identifier, slideIndex: index < 0 ? this.data.slideIndex : index, result: this.data.demo.slide ? '' : `select: ${identifier}` });
    },

    cyl_plusTap() {
      this.setData({ result: 'plustap' });
    },

    cyl_touchStart() {
      this.cylTouchStart = Date.now();
    },

    // [EN] Long press rows: the tab under the finger reports how long it was held. [CN] 长按行：报告手指按住的时长。
    cyl_longPress() {
      if (this.data.demo.longPress) {
        this.setData({ result: `longpress: ${Date.now() - (this.cylTouchStart || Date.now())} ms` });
        wx.vibrateShort({ type: 'medium' });
      }
    },

    // [EN] Scroll rows: down hides the bar, up shows it, as CYLTabBarController's scroll hiding. [CN] 滚动行：向下隐藏，向上显示。
    onPageScroll(event) {
      cylPageScrolled(this, event);
      if (!this.data.demo.scroll) {
        return;
      }
      const last = this.cylLastTop || 0;
      this.cylLastTop = event.scrollTop;
      const hidden = event.scrollTop > last && event.scrollTop > 40;
      if (hidden !== this.data.barHidden && Math.abs(event.scrollTop - last) > 4) {
        this.setData({ barHidden: hidden, result: hidden ? 'hidden' : 'shown' });
      }
    },

    cyl_toggleNavigation() {
      this.cylNavigationHidden = !this.cylNavigationHidden;
      wx.setNavigationBarTitle({ title: this.cylNavigationHidden ? '' : this.data.title });
      if (this.cylNavigationHidden) {
        wx.showNavigationBarLoading();
      } else {
        wx.hideNavigationBarLoading();
      }
      this.setData({ result: this.cylNavigationHidden ? 'hidden' : 'shown' });
    },

    cyl_findItem(identifier) {
      const bar = this.selectComponent('#cyl-demo-tab-bar');
      const slots = bar ? bar.data.cylSlots : [];
      const index = slots.findIndex((slot) => slot.key === identifier || slot.identifier === identifier || (slot.item && slot.item.identifier === identifier));
      this.setData({ result: index < 0 ? 'not found' : `${identifier}: slot ${index}`, selectedIdentifier: identifier });
    },
  },
});
