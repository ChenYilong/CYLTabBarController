/**
 * [EN] cyl-glass-lens: the Liquid Glass lens behind a selected item, one component for every place that shows it:
 *      cyl-tab-bar-item (a selected tab, CYLTabBarItemStyle liquidGlass) and cyl-tab-bar (the selected plus button with
 *      CYLPlusButtonShowsSelection on Liquid Glass), so both have the same center, size, insets, color, rim and spring.
 *      It fills the positioned parent (the slot) 5 px from its top and bottom, like the iOS lens. Decoration only:
 *      hidden from accessibility.
 * [CN] cyl-glass-lens：选中项后面的液态玻璃透镜，所有显示它的地方共用这一个组件：cyl-tab-bar-item（选中的 Tab，
 *      CYLTabBarItemStyle liquidGlass）与 cyl-tab-bar（液态玻璃下开启 CYLPlusButtonShowsSelection 时选中的 PlusButton），
 *      因此两者的中心、尺寸、间距、颜色、亮边与弹入动画一致。它占满有定位的父视图（该位置），距上下各 5 px，与 iOS
 *      透镜一致。仅为装饰：对无障碍隐藏。
 */
Component({
  properties: {
    /** [EN] Dark appearance (the bar's skin). [CN] 深色外观（TabBar 的皮肤）。 */
    isDark: { type: Boolean, value: false },
    /**
     * [EN] CYLGlassLensStyle (cyl-tab-bar/cyl_tab_bar_item_style.js): "regular" (default) or "skeuomorphic".
     * [CN] CYLGlassLensStyle（cyl-tab-bar/cyl_tab_bar_item_style.js）："regular"（默认）或 "skeuomorphic"。
     */
    lensStyle: { type: String, value: 'regular' },
  },
});
