/**
 * [EN] The Liquid Glass gallery: pages modeled on the UI of three open mini program / web projects, switched by the
 *      core's cyl-tab-bar with CYLTabBarItemStyle liquidGlass (the glass bar and lens come from the core, not from this
 *      page). Panels: Check-in (Akenaiai/sports-checkin-miniprogram: big check-in button, sport grid, stats, week),
 *      Feed (tyfuser/chatnote-miniprogram notes and community: navigation bar, search box, tag pills, feed list),
 *      Cards (a collection view grid) and Landing (1994Umbrella/mirror-landing: floating light blobs, hero card), plus
 *      the core tap animations and both item styles. Their animations (fade in, slide up, scale in, floating blobs)
 *      are written here again; no code of those projects was copied. Data: local JSON files in /data.
 * [CN] 液态玻璃画廊：参考三个开源小程序 / 网页项目 UI 的页面，由核心层的 cyl-tab-bar（CYLTabBarItemStyle liquidGlass）
 *      切换（玻璃 TabBar 与透镜来自核心层，而不是本页）。面板：打卡（Akenaiai/sports-checkin-miniprogram：大打卡按钮、
 *      运动网格、统计、本周）、动态（tyfuser/chatnote-miniprogram 的笔记与社区：导航栏、搜索框、标签、信息流）、卡片
 *      （集合视图网格）与落地页（1994Umbrella/mirror-landing：浮动光晕、主卡片），以及核心层的点击动画与两种 Item 样式。
 *      其中的动画（淡入、上滑、缩放进入、浮动光晕）在此重新编写；未复制这些项目的代码。数据：/data 中的本地 JSON 文件。
 */
const { t } = require('../../utils/cyl_demo_localization');
const cylDemoStrings = require('../../utils/cyl_demo_strings');
const cylSymbols = require('../../shared/symbols');
const { CYLTabBarItemStyle } = require('cyl-tabbar-miniprogram/cyl-tab-bar/cyl_tab_bar_item_style');

/**
 * [EN] Reads a JSON file of the code package (a mini program cannot require .json files).
 * [CN] 读取代码包内的 JSON 文件（小程序不能 require .json 文件）。
 */
function cylReadJSON(path) {
  try {
    return JSON.parse(wx.getFileSystemManager().readFileSync(path, 'utf8'));
  } catch (error) {
    console.error(`cyl glass gallery: reading ${path} failed: ${error.message || error.errMsg}`);
    return {};
  }
}

const CYL_PANELS = [
  { identifier: 'checkin', title: 'Check-in', symbol: 'house' },
  { identifier: 'feed', title: 'Feed', symbol: 'message' },
  { identifier: 'cards', title: 'Cards', symbol: 'safari' },
  { identifier: 'landing', title: 'Landing', symbol: 'person' },
];

/**
 * [EN] The gallery's tab bar configuration: the same keys as every CYLTabBarController configuration.
 * [CN] 画廊 TabBar 的配置：与所有 CYLTabBarController 配置相同的键。
 */
function cylGalleryConfiguration() {
  return {
    CYLTabBarControllerTabBarItemsAttributes: CYL_PANELS.map((panel) => ({
      CYLTabBarItemTitle: t(panel.title),
      CYLTabBarItemImage: `system:${panel.symbol}`,
      CYLTabBarItemSelectedImage: `system:${panel.symbol}.fill`,
      CYLTabBarItemIdentifier: panel.identifier,
    })),
    CYLTabBarControllerTabButtonTapAnimation: 'bounce',
  };
}

Page({
  data: {
    texts: {},
    panel: 'checkin',
    panelTitle: '',
    configuration: {},
    symbolsByTheme: cylSymbols,
    itemStyle: CYLTabBarItemStyle.liquidGlass,
    navigation: { statusBar: 20, height: 44, capsuleRight: 96 },
    checkin: { sports: [], stats: {}, week: [] },
    checkedIn: false,
    selectedSport: '',
    tags: [],
    tag: 'All',
    keyword: '',
    posts: [],
    allPosts: [],
    cards: [],
    reviewed: {},
    tapAnimations: ['bounce', 'rotation', 'scale'],
    playing: {},
  },

  onLoad(options) {
    const texts = {};
    Object.keys(cylDemoStrings.en).forEach((key) => {
      texts[key] = t(key);
    });
    const feed = cylReadJSON('/data/cyl_glass_feed.json');
    this.setData({
      texts,
      navigation: this.cyl_navigationMetrics(),
      configuration: cylGalleryConfiguration(),
      checkin: cylReadJSON('/data/cyl_glass_checkin.json'),
      tags: feed.tags || [],
      allPosts: feed.posts || [],
      posts: feed.posts || [],
      cards: (cylReadJSON('/data/cyl_glass_cards.json').cards || []),
    });
    this.cyl_showPanel((options && options.panel) || 'checkin');
  },

  /**
   * [EN] The custom navigation bar sits under the status bar and beside the menu button.
   * [CN] 自定义导航栏位于状态栏下方、胶囊按钮旁边。
   */
  cyl_navigationMetrics() {
    try {
      const window = typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync();
      const capsule = wx.getMenuButtonBoundingClientRect();
      const statusBar = window.statusBarHeight || 20;
      const height = (capsule.top - statusBar) * 2 + capsule.height;
      return { statusBar, height, capsuleRight: window.windowWidth - capsule.left + 8 };
    } catch (error) {
      return { statusBar: 20, height: 44, capsuleRight: 96 };
    }
  },

  cyl_showPanel(identifier) {
    const panel = CYL_PANELS.find((candidate) => candidate.identifier === identifier) || CYL_PANELS[0];
    this.setData({ panel: panel.identifier, panelTitle: t(panel.title) });
  },

  cyl_onSelect(event) {
    this.cyl_showPanel(event.detail.identifier);
  },

  cyl_back() {
    wx.navigateBack({ fail: () => wx.switchTab({ url: '/pages/home/index' }) });
  },

  cyl_checkIn() {
    this.setData({ checkedIn: !this.data.checkedIn });
  },

  cyl_selectSport(event) {
    this.setData({ selectedSport: event.currentTarget.dataset.id });
  },

  cyl_search(event) {
    this.setData({ keyword: event.detail.value }, () => this.cyl_filter());
  },

  cyl_selectTag(event) {
    this.setData({ tag: event.currentTarget.dataset.tag }, () => this.cyl_filter());
  },

  /**
   * [EN] The feed filtered by tag and keyword (title, preview, author).
   * [CN] 按标签与关键词（标题、摘要、作者）过滤的信息流。
   */
  cyl_filter() {
    const keyword = this.data.keyword.trim().toLowerCase();
    const posts = this.data.allPosts.filter((post) => (this.data.tag === 'All' || post.tag === this.data.tag)
      && (!keyword || `${post.title} ${post.preview} ${post.author}`.toLowerCase().includes(keyword)));
    this.setData({ posts });
  },

  cyl_toggleCard(event) {
    const id = event.currentTarget.dataset.id;
    this.setData({ [`reviewed.${id}`]: !this.data.reviewed[id] });
  },

  /**
   * [EN] Replays a core tap animation (CYLTabBarControllerTabButtonTapAnimation) on a standalone cyl-tab-bar-item.
   * [CN] 在单独的 cyl-tab-bar-item 上重放核心层的点击动画（CYLTabBarControllerTabButtonTapAnimation）。
   */
  cyl_playTapAnimation(event) {
    const name = event.currentTarget.dataset.name;
    this.setData({ [`playing.${name}`]: '' }, () => {
      this.setData({ [`playing.${name}`]: `cyl-animate-${name}` });
    });
  },

  cyl_toggleItemStyle() {
    this.setData({
      itemStyle: this.data.itemStyle === CYLTabBarItemStyle.liquidGlass ? CYLTabBarItemStyle.flat : CYLTabBarItemStyle.liquidGlass,
    });
  },
});
