/**
 * [EN] cyl-tab-bar-item: an animated icon and a title, the mini program counterpart of the iOS CYLFlatDesignTabBarItem
 *      (CYLTabBarController/CYLFlatDesignTabBar). Its properties and methods keep the iOS names (the comparison table
 *      is in docs/WeChat-Mini-Program.md). The icon is an image, or an animation picked by file type: Lottie (.json)
 *      through cyl-lottie-miniprogram, PAG (.pag) and Rive (.riv) through their components. cyl-tab-bar renders one
 *      per tab; it also works alone. Events: `itemtap`, `change` (CYLFlatDesignTabBarItemDidChange).
 * [CN] cyl-tab-bar-item：动画图标与标题，对应 iOS 的 CYLFlatDesignTabBarItem（CYLTabBarController/CYLFlatDesignTabBar）。
 *      属性与方法沿用 iOS 的名称（对比表见 docs/WeChat-Mini-Program.md）。图标为图片，或按文件类型选择的动画：Lottie（.json）
 *      通过 cyl-lottie-miniprogram，PAG（.pag）与 Rive（.riv）通过各自的组件。cyl-tab-bar 为每个 Tab 渲染一个；
 *      它也可以单独使用。事件：`itemtap`、`change`（CYLFlatDesignTabBarItemDidChange）。
 */
const { cylItemModel, cylStateKey } = require('./cyl_tab_bar_item_model');
const { CYLTabBarItemStyle, cylTabBarItemStyle } = require('../cyl-tab-bar/cyl_tab_bar_item_style');

const CYL_PROPERTIES = ['title', 'image', 'selectedImage', 'index', 'titlePositionAdjustment', 'imagePositionAdjustment',
  'imageInsets', 'lottieFilePath', 'lottieURL', 'lottieSizeValue', 'enabled', 'selected', 'badgeValue', 'badgeColor',
  'badgeSize', 'badgeContentInset', 'badgePositionAdjustment', 'layoutCentered', 'backgroundColor',
  'selectedBackgroundColor', 'titleTextAttributes', 'badgeTextAttributes', 'standardAppearance', 'animationPath',
  'animationSize', 'imageSize', 'iconTint', 'selectedIconTint', 'label', 'animationColors', 'loopsWhenUnselected',
  'animationClass', 'animationDuration', 'itemStyle', 'isDark'];

Component({
  properties: {
    /** [EN] UITabBarItem / CYLFlatDesignTabBarItem `title`. [CN] 标题。 */
    title: { type: String, value: '' },
    /** [EN] `image`: a path or URL. [CN] 图片：路径或 URL。 */
    image: { type: String, value: '' },
    /** [EN] `selectedImage`. [CN] 选中图片。 */
    selectedImage: { type: String, value: '' },
    /** [EN] `index` in the tab bar. [CN] 在 TabBar 中的序号。 */
    index: { type: Number, value: 0 },
    /** [EN] `titlePositionAdjustment`: "{h, v}", [h, v] or {horizontal, vertical}. [CN] 标题偏移。 */
    titlePositionAdjustment: { type: null, value: null },
    /** [EN] `imagePositionAdjustment`: as above. [CN] 图片偏移。 */
    imagePositionAdjustment: { type: null, value: null },
    /** [EN] `imageInsets`: "{t, l, b, r}", a list or a dictionary. [CN] 图片内边距。 */
    imageInsets: { type: null, value: null },
    /** [EN] `lottieFilePath`: a package path. [CN] Lottie 文件路径（包内路径）。 */
    lottieFilePath: { type: String, value: '' },
    /** [EN] `lottieURL`: a network URL. [CN] Lottie 网络地址。 */
    lottieURL: { type: String, value: '' },
    /** [EN] `lottieSizeValue`: "{w, h}". [CN] Lottie 尺寸。 */
    lottieSizeValue: { type: null, value: null },
    /** [EN] `enabled` (default YES). [CN] 是否可用（默认 YES）。 */
    enabled: { type: Boolean, value: true },
    /** [EN] The selected state (UIControl `selected` of the tab bar button). [CN] 选中状态。 */
    selected: { type: Boolean, value: false },
    /** [EN] `badgeValue`: a text, or "•" for a dot; "" hides it. [CN] 角标文字，"•" 为小红点；"" 隐藏。 */
    badgeValue: { type: String, value: '' },
    /** [EN] `badgeColor`. [CN] 角标颜色。 */
    badgeColor: { type: String, value: '' },
    /** [EN] `badgeSize`: "{w, h}"; zero sizes itself. [CN] 角标尺寸；为 0 时自动计算。 */
    badgeSize: { type: null, value: null },
    /** [EN] `badgeContentInset` (default {1, 6, 1, 6}). [CN] 角标内容内边距（默认 {1, 6, 1, 6}）。 */
    badgeContentInset: { type: null, value: null },
    /** [EN] `badgePositionAdjustment`. [CN] 角标偏移。 */
    badgePositionAdjustment: { type: null, value: null },
    /** [EN] `layoutCentered`: centers the title without an image, or the image without a title. [CN] 无图片时标题居中，或无标题时图片居中。 */
    layoutCentered: { type: Boolean, value: false },
    /** [EN] `backgroundColor`. [CN] 背景色。 */
    backgroundColor: { type: String, value: '' },
    /** [EN] `selectedBackgroundColor`. [CN] 选中背景色。 */
    selectedBackgroundColor: { type: String, value: '' },
    /** [EN] `setTitleTextAttributes:forState:` as {normal: {…}, selected: {…}}. [CN] 各状态的标题文字属性。 */
    titleTextAttributes: { type: Object, value: null },
    /** [EN] `setBadgeTextAttributes:forState:` as {normal: {…}, selected: {…}}. [CN] 各状态的角标文字属性。 */
    badgeTextAttributes: { type: Object, value: null },
    /** [EN] `standardAppearance` (UITabBarAppearance-like), used while selected. [CN] 选中时使用的外观。 */
    standardAppearance: { type: Object, value: null },
    /** [EN] An animation file of any library (.json, .pag, .riv), like CYLTabBarAnimationFilePath. [CN] 任意动画库的文件。 */
    animationPath: { type: String, value: '' },
    /** [EN] The animation's size, like CYLTabBarAnimationSize. [CN] 动画尺寸。 */
    animationSize: { type: null, value: null },
    /** [EN] The image's size (CYLTabBarItemImageURLSize). [CN] 图片尺寸。 */
    imageSize: { type: null, value: null },
    /** [EN] keypath -> color for the animation (CYLTabBarAnimationColors). [CN] 动画的 keypath -> 颜色。 */
    animationColors: { type: Object, value: null },
    /** [EN] Loops while unselected (CYLTabBarLottieLoopsWhenUnselected). [CN] 未选中时循环播放。 */
    loopsWhenUnselected: { type: Boolean, value: false },
    /** [EN] The icon tint (CYLTabBarItemIconColor), "" for none. [CN] 图标着色。 */
    iconTint: { type: String, value: '' },
    /** [EN] The selected icon tint (CYLTabBarItemSelectedIconColor). [CN] 选中图标着色。 */
    selectedIconTint: { type: String, value: '' },
    /** [EN] The accessibility label (default: the title, with the badge). [CN] 无障碍标签（默认：标题与角标）。 */
    label: { type: String, value: '' },
    /** [EN] The tap animation class name (CYLTabBarControllerTabButtonTapAnimation). [CN] 点击动画类名。 */
    animationClass: { type: String, value: '' },
    /** [EN] The tap animation's duration in ms. [CN] 点击动画时长（毫秒）。 */
    animationDuration: { type: Number, value: 400 },
    /**
     * [EN] CYLTabBarItemStyle (cyl-tab-bar/cyl_tab_bar_item_style.js): "flat" (default) or "liquidGlass", the selected
     *      item on a frosted glass lens. cyl-tab-bar sets it for every item.
     * [CN] CYLTabBarItemStyle（cyl-tab-bar/cyl_tab_bar_item_style.js）："flat"（默认）或 "liquidGlass"，选中的 Item 位于
     *      磨砂玻璃透镜上。cyl-tab-bar 为每个 Item 设置。
     */
    itemStyle: { type: String, value: CYLTabBarItemStyle.flat },
    /** [EN] Dark appearance of the glass (cyl-tab-bar passes its skin). [CN] 玻璃的深色外观（cyl-tab-bar 传入其皮肤）。 */
    isDark: { type: Boolean, value: false },
  },

  data: {
    m: {},
    cylItemStyle: CYLTabBarItemStyle.flat,
  },

  observers: {
    [CYL_PROPERTIES.join(', ')]: function () {
      this.cyl_update();
    },
    itemStyle(value) {
      this.setData({ cylItemStyle: cylTabBarItemStyle(value) });
    },
  },

  lifetimes: {
    attached() {
      this.cylAttributes = { title: {}, badge: {} };
      this.cyl_update();
    },
  },

  methods: {
    cyl_update() {
      const properties = Object.assign({}, this.data);
      ['title', 'badge'].forEach((kind) => {
        const set = this.cylAttributes && this.cylAttributes[kind];
        if (set && Object.keys(set).length > 0) {
          properties[`${kind}TextAttributes`] = Object.assign({}, properties[`${kind}TextAttributes`] || {}, set);
        }
      });
      const model = cylItemModel(properties);
      model.itemStyle += `animation-duration: ${this.data.animationDuration}ms;`;
      const signature = JSON.stringify(CYL_PROPERTIES.map((key) => this.data[key]));
      this.setData({ m: model });
      if (this.cylSignature !== undefined && this.cylSignature !== signature) {
        // [EN] CYLFlatDesignTabBarItemDidChange. [CN] 对应 CYLFlatDesignTabBarItemDidChange。
        this.triggerEvent('change', { index: this.data.index });
      }
      this.cylSignature = signature;
    },

    cyl_onTap() {
      if (this.data.enabled === false) {
        return;
      }
      this.triggerEvent('itemtap', { index: this.data.index });
    },

    /**
     * [EN] `-setTitleTextAttributes:forState:`; state: "normal" / "selected" or UIControlState 0 / 4.
     * [CN] `-setTitleTextAttributes:forState:`；state 为 "normal" / "selected"，或 UIControlState 0 / 4。
     */
    cyl_setTitleTextAttributes(attributes, state) {
      this.cylAttributes.title[cylStateKey(state)] = attributes || null;
      this.cyl_update();
    },

    /** [EN] `-titleTextAttributesForState:`. [CN] 返回指定状态的标题文字属性。 */
    cyl_titleTextAttributesForState(state) {
      const key = cylStateKey(state);
      return this.cylAttributes.title[key] || (this.data.titleTextAttributes || {})[key] || null;
    },

    /** [EN] `-setBadgeTextAttributes:forState:`. [CN] 设置指定状态的角标文字属性。 */
    cyl_setBadgeTextAttributes(attributes, state) {
      this.cylAttributes.badge[cylStateKey(state)] = attributes || null;
      this.cyl_update();
    },

    /** [EN] `-badgeTextAttributesForState:`. [CN] 返回指定状态的角标文字属性。 */
    cyl_badgeTextAttributesForState(state) {
      const key = cylStateKey(state);
      return this.cylAttributes.badge[key] || (this.data.badgeTextAttributes || {})[key] || null;
    },

    /**
     * [EN] `-actualBadgeSuperView`: the node that hosts the badge, as {component, selector}.
     * [CN] `-actualBadgeSuperView`：承载角标的节点，返回 {component, selector}。
     */
    cyl_actualBadgeSuperView() {
      return { component: this, selector: '.cyl-item-icon-box' };
    },

    /** [EN] `tabBarButton`: this component. [CN] `tabBarButton`：本组件。 */
    cyl_tabBarButton() {
      return this;
    },

    /** [EN] `cylflatdesign_tabBarController`: the cyl-tab-bar that holds this item, or null. [CN] 所属的 cyl-tab-bar，没有时为 null。 */
    cyl_tabBarController() {
      // [EN] The component whose template holds this item: cyl-tab-bar, or a page when the item is used alone.
      // [CN] 模板中包含本 Item 的组件：cyl-tab-bar；单独使用时为页面。
      const owner = typeof this.selectOwnerComponent === 'function' ? this.selectOwnerComponent() : null;
      return owner && typeof owner.cyl_selectAdjacent === 'function' ? owner : null;
    },

    /** [EN] The animation component (cyl-lottie, cyl-pag or cyl-rive), or null. [CN] 动画组件，没有时为 null。 */
    cyl_animationView() {
      return this.selectComponent('#cyl-item-animation');
    },

    /**
     * [EN] Plays the animation from its first frame (a tab that becomes selected), or `offset` seconds in, to continue
     *      a playback another tab bar started.
     * [CN] 从首帧播放动画（Tab 被选中时），或从第 `offset` 秒开始，以继续另一个 TabBar 已开始的播放。
     */
    cyl_playAnimation(offset) {
      const view = this.cyl_animationView();
      if (view && typeof view.cyl_playFromStart === 'function') {
        view.cyl_playFromStart(offset);
      }
    },

    /** [EN] Stops the animation on its resting frame. [CN] 停止动画并显示静止帧。 */
    cyl_stopAnimation() {
      const view = this.cyl_animationView();
      if (view && typeof view.cyl_stop === 'function') {
        view.cyl_stop();
      }
    },
  },
});
