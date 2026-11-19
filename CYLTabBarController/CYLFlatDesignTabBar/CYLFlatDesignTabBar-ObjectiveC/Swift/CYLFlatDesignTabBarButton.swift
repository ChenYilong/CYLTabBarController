//
//  CYLFlatDesignTabBarButton.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif
#if canImport(CYLAnimatedItemViews)
// [EN] SwiftPM: CYLAnimatedItemView is in the views target. [CN] SwiftPM：CYLAnimatedItemView 位于 views target。
import CYLAnimatedItemViews
#endif

// [EN] The button of a FlatDesign tab, translated from Objective-C together with its item (docs/Swift-Migration.md,
//      step 49). Objective-C names, selectors and Swift names are kept; `-_updateTabBarButton` keeps its selector for
//      CYLFlatDesignTabBar.m.
// [CN] 扁平样式 Tab 的按钮，与其 item 一起从 Objective-C 翻译（docs/Swift-Migration.md，第 49 步）。保留 Objective-C 名称、selector 与
//      Swift 名称；`-_updateTabBarButton` 为 CYLFlatDesignTabBar.m 保留其 selector。

/**
 * [EN] Private methods of `CYLFlatDesignTabBar` (Objective-C) that the button calls.
 * [CN] 按钮调用的 `CYLFlatDesignTabBar`（Objective-C）私有方法。
 */
@objc private protocol CYLFlatDesignTabBarButtonPrivateAPI {
    /// [EN] Implemented in CYLFlatDesignTabBar.m (#477). [CN] 在 CYLFlatDesignTabBar.m 中实现（#477）。
    @objc(stopAllTabBarItemAnimations) func stopAllTabBarItemAnimations()
}

/**
 * [EN] One tab of the FlatDesign tab bar: draws its item (image, title, background, badge, animation) and maps the
 *      bar's `UITabBarAppearance` onto it. It is the shared animated item component, `CYLAnimatedItemView`
 *      (docs/Animated-Item.md, TODO 4; Android: `CYLTabBarItemButton`): the item's image and title go into the
 *      component's content (`image`, `title`), shown by its `imageView` and `titleLabel` (the same properties the button
 *      had); the tab bar's own layout replaces the component's (`-layoutContentInRect:`), and the tab icon animation still
 *      comes from the tab bar. The component's long press is off: the tab bar handles its own gestures.
 * [CN] 扁平样式 TabBar 的一个 Tab：绘制其 item（图片、标题、背景、角标、动画），并把 TabBar 的 `UITabBarAppearance` 映射到其上。它就是共用的
 *      动效条目组件 `CYLAnimatedItemView`（docs/Animated-Item.md，TODO 4；Android 为 `CYLTabBarItemButton`）：item 的图片与标题写入组件的
 *      内容（`image`、`title`），由其 `imageView` 与 `titleLabel` 显示（与按钮原有的属性相同）；TabBar 自己的布局代替组件的布局
 *      （`-layoutContentInRect:`），Tab 图标动画仍由 TabBar 提供。组件的长按已关闭：TabBar 自行处理手势。
 */
@objc(CYLFlatDesignTabBarButton)
open class CYLFlatDesignTabBarButton: CYLAnimatedItemView {

    private var tabBarItemStorage: CYLFlatDesignTabBarItem?

    /**
     * [EN] The item this button shows. As before, setting it does nothing while the button has no item yet (use
     *      `-initWithTabBarItem:`).
     * [CN] 本按钮显示的 item。与以前相同，按钮还没有 item 时设置无效（请使用 `-initWithTabBarItem:`）。
     */
    @objc open var tabBarItem: CYLFlatDesignTabBarItem! {
        get { tabBarItemStorage }
        set {
            guard tabBarItemStorage != nil else { return }
            tabBarItemStorage = newValue
            cylUpdateTabBarButton()
            if let item = tabBarItemStorage, item.tabBarButton == nil {
                item.tabBarButton = self
            }
        }
    }

    /// [EN] Drawn behind the selected item for `UITabBarAppearance.selectionIndicatorImage`.
    /// [CN] 按 `UITabBarAppearance.selectionIndicatorImage` 绘制在选中 item 背后。
    private var selectionIndicatorView: UIImageView?
    /// [EN] The badge values this button set from an appearance, so they can be given back when it no longer sets them.
    /// [CN] 本按钮按 appearance 设置过的角标属性，appearance 不再设置时可以还原。
    private var appliedAppearanceBadgeBackgroundColor = false
    private var appliedAppearanceBadgeTextColor = false
    private var appliedAppearanceBadgeFont = false
    private var appliedAppearanceBadgeOffset = false

    /**
     * [EN] Creates a flat-design tab bar button for `tabBarItem` and links the item back to this button.
     * [CN] 使用 tabBarItem 创建扁平化 TabBar 按钮，并将该 Item 关联回此按钮。
     */
    @objc(initWithTabBarItem:)
    public convenience init(tabBarItem: CYLFlatDesignTabBarItem) {
        self.init(frame: .zero)
        tabBarItemStorage = tabBarItem
        clipsToBounds = false
        cylUpdateTabBarButton()
        tabBarItem.tabBarButton = self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addTabSubviews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTabSubviews()
    }

    /**
     * [EN] The component made `imageView` and `titleLabel`; they keep the tab bar's look: unclipped, the appearance's
     *      title font (no Dynamic Type, as the system tab bar), no long press of the component, no identifier of its own.
     * [CN] `imageView` 与 `titleLabel` 由组件创建；保持 TabBar 的外观：不裁剪，使用 appearance 的标题字体（与系统 TabBar 相同，不随动态字体变化），
     *      不使用组件的长按，也不使用组件的标识符。
     */
    private func addTabSubviews() {
        imageView.clipsToBounds = false
        imageView.contentMode = .scaleToFill
        titleLabel.clipsToBounds = false
        titleLabel.adjustsFontForContentSizeCategory = false
        longPressGestureRecognizer.isEnabled = false
        accessibilityIdentifier = nil
    }

    /**
     * [EN] The tab bar's layout instead of the component's. [CN] 使用 TabBar 的布局代替组件的布局。
     */
    open override func layoutContent(in _: CGRect) {
        updateLayout()
    }

    open override func tintColorDidChange() {
        super.tintColorDidChange()
        if isSelected {
            titleLabel.textColor = titleTextAttributesForCurrentState()[.foregroundColor] as? UIColor
            applyIconTintColor(iconColorForCurrentState())
        }
    }

    open override var isSelected: Bool {
        get { super.isSelected }
        set {
            guard super.isSelected != newValue else { return }
            super.isSelected = newValue
            cylUpdateTabBarButton()
            // [EN] A GIF given as the tab image plays when its tab is selected, as on the classic tab bar (915bddbd).
            // [CN] 作为 Tab 图片传入的 GIF 在选中其 Tab 时播放，与经典 TabBar 相同（915bddbd）。
            if newValue, tabBarAnimationURL == nil { playAnimatedImage(animatedTabImage) }
        }
    }

    // MARK: - [EN] UITabBarAppearance mapping [CN] UITabBarAppearance 映射

    /// [EN] A `UITabBarAppearance` as created, to tell values an app customized from the defaults.
    /// [CN] 新建的 `UITabBarAppearance`，用于区分 App 自定义的值与默认值。
    private static let defaultItemAppearance = UITabBarAppearance().stackedLayoutAppearance

    private static func stateAppearance(_ itemAppearance: UITabBarItemAppearance,
                                        for state: UIControl.State) -> UITabBarItemStateAppearance {
        if state.contains(.disabled) {
            return itemAppearance.disabled
        }
        if state.contains(.selected) {
            return itemAppearance.selected
        }
        return itemAppearance.normal
    }

    private static func isCustomized(_ value: AnyObject?, default defaultValue: AnyObject?) -> Bool {
        guard let value else { return false }
        return !(defaultValue.map { value.isEqual($0) } ?? false)
    }

    /// [EN] The flat design tab bar this button is in, nil before it is added. [CN] 本按钮所在的扁平样式 TabBar；添加前为 nil。
    private var flatDesignTabBar: CYLFlatDesignTabBar? {
        var view = superview
        while let current = view, !(current is CYLFlatDesignTabBar) {
            view = current.superview
        }
        return view as? CYLFlatDesignTabBar
    }

    /**
     * [EN] The appearance the bar is drawn with, see `-[CYLFlatDesignTabBar standardAppearance]`: the selected item's own,
     *      else the bar's. The selected item comes from the bar, so every button follows it.
     * [CN] TabBar 绘制所用的 appearance，见 `-[CYLFlatDesignTabBar standardAppearance]`：选中 item 自身的，否则为 TabBar 的。
     *      选中 item 取自 TabBar，因此所有按钮保持一致。
     */
    private var effectiveAppearance: UITabBarAppearance? {
        guard let tabBar = flatDesignTabBar else {
            return tabBarItemStorage?.standardAppearance
        }
        return tabBar.selectedItem?.standardAppearance ?? tabBar.standardAppearance
    }

    /// [EN] The state appearance of the current state, nil without an appearance: the component's (`itemAppearance`, set from
    ///      `effectiveAppearance` on every update), so the icon and title part lives in `CYLAnimatedItemView`.
    /// [CN] 当前状态的 state appearance，没有 appearance 时为 nil：即组件的（`itemAppearance`，每次更新时由 `effectiveAppearance` 设置），图标与标题部分
    ///      位于 `CYLAnimatedItemView`。
    private var currentStateAppearance: UITabBarItemStateAppearance? {
        currentItemStateAppearance
    }

    private var defaultStateAppearance: UITabBarItemStateAppearance {
        Self.stateAppearance(Self.defaultItemAppearance, for: currentState)
    }

    /// [EN] `iconColor` of the appearance, else the flat design default (tint color when selected, gray otherwise).
    /// [CN] appearance 的 `iconColor`，否则使用扁平样式默认值（选中为 tintColor，否则为灰色）。
    private func iconColorForCurrentState() -> UIColor {
        if let iconColor = currentStateAppearance?.iconColor {
            return iconColor
        }
        return isSelected ? tintColor : .systemGray
    }

    /// [EN] `titlePositionAdjustment` of the appearance, used when the item has no offset of its own.
    /// [CN] item 没有自身偏移时使用的 appearance `titlePositionAdjustment`。
    private var appearanceTitlePositionAdjustment: UIOffset {
        currentStateAppearance?.titlePositionAdjustment ?? .zero
    }

    /**
     * [EN] `selectionIndicatorImage` / `selectionIndicatorTintColor` of the appearance, behind the selected item. A resizable
     *      image fills the button, any other is centered. Only shown while selected.
     * [CN] appearance 的 `selectionIndicatorImage` / `selectionIndicatorTintColor`，绘制在选中 item 背后。可拉伸图片铺满按钮，其他图片居中。
     *      仅在选中时显示。
     */
    private func updateSelectionIndicator() {
        let appearance = isSelected ? effectiveAppearance : nil
        guard var image = appearance?.selectionIndicatorImage else {
            selectionIndicatorView?.removeFromSuperview()
            selectionIndicatorView = nil
            return
        }
        let tintColor = appearance?.selectionIndicatorTintColor
        if tintColor != nil && image.renderingMode != .alwaysOriginal {
            image = image.withRenderingMode(.alwaysTemplate)
        }
        let indicatorView = selectionIndicatorView ?? {
            let view = UIImageView()
            view.isUserInteractionEnabled = false
            return view
        }()
        selectionIndicatorView = indicatorView
        indicatorView.image = image
        indicatorView.tintColor = tintColor
        let isResizable = image.capInsets != .zero
        indicatorView.contentMode = isResizable ? .scaleToFill : .center
        indicatorView.frame = bounds
        insertSubview(indicatorView, at: 0)
    }

    /**
     * [EN] Badge values of the appearance: background color, text color and font, center offset. A value that is not
     *      customized (equal to a new `UITabBarAppearance`) is left to the badge's own settings and `CYLBadgeAppearance`; one
     *      set here earlier is given back to them (nil restores the global value).
     * [CN] appearance 的角标属性：背景色、文字颜色与字体、中心偏移。未自定义的值（与新建的 `UITabBarAppearance` 相同）交给角标自身设置
     *      与 `CYLBadgeAppearance`；之前在这里设置过的会还给它们（nil 恢复全局值）。
     */
    private func updateBadgeAppearance() {
        var backgroundColor: UIColor?
        var textColor: UIColor?
        var font: UIFont?
        var offset: UIOffset?
        if let stateAppearance = currentStateAppearance {
            let defaults = defaultStateAppearance
            if Self.isCustomized(stateAppearance.badgeBackgroundColor, default: defaults.badgeBackgroundColor) {
                backgroundColor = stateAppearance.badgeBackgroundColor
            }
            let attributes = stateAppearance.badgeTextAttributes
            let defaultAttributes = defaults.badgeTextAttributes
            if Self.isCustomized(attributes[.foregroundColor] as AnyObject?, default: defaultAttributes[.foregroundColor] as AnyObject?) {
                textColor = attributes[.foregroundColor] as? UIColor
            }
            if Self.isCustomized(attributes[.font] as AnyObject?, default: defaultAttributes[.font] as AnyObject?) {
                font = attributes[.font] as? UIFont
            }
            if stateAppearance.badgePositionAdjustment != .zero {
                offset = stateAppearance.badgePositionAdjustment
            }
        }
        let badgeSuperView = actualBadgeSuperView()
        if backgroundColor != nil || appliedAppearanceBadgeBackgroundColor {
            badgeSuperView.cyl_badgeBackgroundColor = backgroundColor
            appliedAppearanceBadgeBackgroundColor = backgroundColor != nil
        }
        if textColor != nil || appliedAppearanceBadgeTextColor {
            badgeSuperView.cyl_badgeTextColor = textColor
            appliedAppearanceBadgeTextColor = textColor != nil
        }
        if font != nil || appliedAppearanceBadgeFont {
            badgeSuperView.cyl_badgeFont = font
            appliedAppearanceBadgeFont = font != nil
        }
        if offset != nil || appliedAppearanceBadgeOffset {
            let value = offset ?? .zero
            badgeSuperView.cyl_badgeCenterOffset = CGPoint(x: value.horizontal, y: value.vertical)
            appliedAppearanceBadgeOffset = offset != nil
        }
    }

    // MARK: - [EN] Drawing [CN] 绘制

    /**
     * [EN] Shows the item: enabled state, image, title, background, selection indicator, badge appearance and animation.
     *      Badges are set through the view controller, not through the item.
     * [CN] 显示 item：可用状态、图片、标题、背景、选中指示、角标外观与动画。角标通过视图控制器设置，不通过 item。
     */
    @objc(_updateTabBarButton)
    func cylUpdateTabBarButton() {
        let item = tabBarItemStorage
        isEnabled = item?.isEnabled ?? false
        // [EN] The bar's (or the selected item's) appearance, icon and title part, to the component. [CN] 把 TabBar（或选中 item）外观的图标与标题部分交给组件。
        itemAppearance = effectiveAppearance?.stackedLayoutAppearance

        var image = item?.image
        if isSelected, let selectedImage = item?.selectedImage {
            image = selectedImage
        }
        // [EN] Through the component's content, which shows it in `imageView`. [CN] 通过组件的内容写入，由组件显示在 `imageView` 中。
        self.image = image
        // [EN] The icon and its animation, through the component (the animation view takes it when its `tint` option asks).
        // [CN] 图标及其动画，通过组件着色（动画视图在其 `tint` 选项需要时使用）。
        applyIconTintColor(iconColorForCurrentState())

        let titleAttributes = titleTextAttributesForCurrentState()
        self.title = item?.title
        titleLabel.textColor = titleAttributes[.foregroundColor] as? UIColor
        titleLabel.font = titleAttributes[.font] as? UIFont

        if let item {
            backgroundColor = isSelected ? (item.selectedBackgroundColor ?? item.backgroundColor) : item.backgroundColor
        }
        updateSelectionIndicator()
        updateBadgeAppearance()
        updateTabBarItemAnimation()
        setNeedsLayout()
    }

    private func updateLayout() {
        guard !bounds.isEmpty else { return }
        selectionIndicatorView?.frame = bounds
        let item = tabBarItemStorage

        // [EN] An animation-only item has no image, but the animation view is centered on `imageView`, so still lay the
        //      image slot out, sized to the animation size; otherwise it collapses to zero and the animation is drawn around
        //      the button's top-left corner.
        // [CN] 只有动画的 item 没有图片，但动画视图以 `imageView` 为中心，因此仍按动画尺寸布局图片位置；否则它会缩成零，动画绘制在按钮左上角附近。
        let animationSize = item?.lottieSizeValue?.cgSizeValue ?? .zero
        let isAnimationOnly = imageView.image == nil && animationSize.width > 0 && animationSize.height > 0 && tabBarAnimationURL != nil
        let showsImage = imageView.image != nil || isAnimationOnly
        let showsTitle = !(titleLabel.text ?? "").isEmpty

        if isAnimationOnly {
            imageView.frame = CGRect(origin: .zero, size: animationSize)
        } else if showsImage {
            imageView.sizeToFit()
        }

        let title = showsTitle ? (titleLabel.text ?? "") : "height"
        let font = titleLabel.font ?? UIFont.systemFont(ofSize: 10, weight: .medium)
        let titleSize = (title as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                                         options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
        var titleX = (bounds.width - titleSize.width) / 2
        var titleY = bounds.height - titleSize.height - 2
        if !showsImage && item?.layoutCentered == true {
            titleY = (bounds.height - titleSize.height) / 2
        }
        // [EN] The item's own offset (CYLTabBarController's `titlePositionAdjustment`) wins, else the appearance's: on the
        //      system tab bar CYL writes its offset into the appearance (issue #475), so both styles show the same offset.
        // [CN] item 自身的偏移（CYLTabBarController 的 `titlePositionAdjustment`）优先，否则使用 appearance 的：系统 TabBar 上 CYL 会把
        //      偏移写入 appearance（issue #475），两种样式显示的偏移一致。
        var titleOffset = item?.titlePositionAdjustment ?? .zero
        if titleOffset == .zero {
            titleOffset = appearanceTitlePositionAdjustment
        }
        titleX += titleOffset.horizontal
        titleY += titleOffset.vertical
        titleLabel.frame = CGRect(x: titleX, y: titleY, width: titleSize.width, height: titleSize.height)

        if showsImage {
            let imageWidth = imageView.frame.width
            let imageHeight = imageView.frame.height
            var imageX = (bounds.width - imageWidth) / 2
            var imageY = (titleLabel.frame.minY - imageHeight) / 2
            if let item {
                if !showsTitle && item.layoutCentered {
                    imageY = (bounds.height - imageHeight) / 2
                }
                imageX += item.imagePositionAdjustment.horizontal
                imageY += item.imagePositionAdjustment.vertical
            }
            var frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
            let insets = item?.imageInsets ?? .zero
            if insets != .zero {
                // [CN] 仅修改的size,xy值不变
                // [EN] Only the size is changed; x and y stay the same
                frame.size.width -= insets.left + insets.right
                frame.size.height -= insets.top + insets.bottom
            }
            imageView.frame = frame
        } else {
            imageView.frame = .zero
        }
        initTabBarItemAnimation()
        // [EN] The tab's animation view is made here, after the button was tinted: it takes the icon color now (a tab that
        //      never changed state kept the file's own white strokes on a light bar).
        // [CN] Tab 的动画视图在这里创建，晚于按钮着色：此时为其着色（从未改变状态的 Tab 曾在浅色 TabBar 上保持文件自身的白色线条）。
        applyIconTintColor(iconColorForCurrentState())
    }

    private func titleTextAttributesForCurrentState() -> [NSAttributedString.Key: Any] {
        let state = currentState
        let item = tabBarItemStorage
        var attributes = item?.titleTextAttributes(for: state) ?? item?.titleTextAttributes(for: .normal)
        // [EN] The appearance's attributes override the item's, as on `UITabBar` (which ignores the item's once it has an
        //      appearance).
        // [CN] appearance 的属性覆盖 item 的属性，与 `UITabBar` 相同（有 appearance 后忽略 item 的属性）。
        if let appearanceAttributes = currentStateAppearance?.titleTextAttributes, !appearanceAttributes.isEmpty {
            attributes = (attributes ?? [:]).merging(appearanceAttributes) { _, new in new }
        }
        var result = attributes ?? [:]
        if result[.font] == nil {
            result[.font] = UIFont.systemFont(ofSize: 10, weight: .medium)
        }
        if result[.foregroundColor] == nil {
            result[.foregroundColor] = state == .selected ? tintColor : UIColor.systemGray
        }
        return result
    }

    private var currentState: UIControl.State {
        var current = state
        if state.contains(.selected) {
            current = .selected
        }
        if state.contains(.disabled) {
            current = .disabled
        }
        return current
    }

    // MARK: - [EN] Tab icon animation [CN] Tab 图标动画

    // [EN] docs/Animated-Item.md TODO 4, second step: the component's animation is the tab's. The tab bar keeps making and
    //      driving the tab's animation view (late failures, speed, loops, dark colors, themes, the classic tab bar shares
    //      it), and the component's animation members answer with that view, so callers and the component's own icon logic
    //      see one animation view; the component never makes or removes a second one.
    // [CN] docs/Animated-Item.md TODO 4 第二步：组件的动画就是 Tab 的动画。Tab 的动画视图仍由 TabBar 创建与驱动（加载后失败、速度、循环、深色颜色、
    //      主题，经典 TabBar 也共用），组件的动画成员返回该视图，调用方与组件自己的图标逻辑看到的是同一个动画视图；组件从不创建或移除第二个。

    /**
     * [EN] The tab's animation view (`-cyl_tabBarItemAnimationView`), nil without one.
     * [CN] Tab 的动画视图（`-cyl_tabBarItemAnimationView`），没有时为 nil。
     */
    open override var animationView: UIView? {
        cyl_tabBarItemAnimationView()
    }

    /**
     * [EN] Whether this tab has an animation view and the tab bar's animations are loaded (`-cyl_isTabBarItemAnimationReady`
     *      alone is about the whole tab bar, YES also for a tab without an animation).
     * [CN] 本 Tab 是否有动画视图且 TabBar 的动画已加载（单独的 `-cyl_isTabBarItemAnimationReady` 针对整个 TabBar，没有动画的 Tab 也返回 YES）。
     */
    open override var isAnimationReady: Bool {
        animationView != nil && cyl_isTabBarItemAnimationReady()
    }

    /**
     * [EN] Rebuilds the tab's animation view for the current style. [CN] 按当前样式重建 Tab 的动画视图。
     */
    open override func reloadAnimation() {
        cyl_reloadTabBarItemAnimationViewForCurrentStyle()
    }

    /**
     * [EN] Plays the tab's animation, as a selection does. [CN] 播放 Tab 的动画，与选中时相同。
     */
    open override func playAnimation() {
        guard CYLTabBarItemAnimationCore.service != nil, let url = tabBarAnimationURL else {
            // [EN] No animation file: an animated tab image plays. [CN] 没有动画文件：播放动图 Tab 图片。
            playAnimatedImage(animatedTabImage)
            return
        }
        cyl_addTabBarItemAnimation(with: url, size: tabBarAnimationSize, contentMode: animationContentMode,
                                   animationSpeed: tabBarAnimationSpeed)
        cyl_playTabBarItemAnimation(with: url, size: tabBarAnimationSize, defaultSelected: false,
                                    contentMode: animationContentMode)
    }

    /**
     * [EN] Plays the tab's animation again from the start. [CN] 从头再次播放 Tab 的动画。
     */
    open override func restartAnimation() {
        if tabBarAnimationURL == nil, playAnimatedImage(animatedTabImage) { return }
        cyl_restartTabBarItemAnimation()
    }

    /**
     * [EN] Stops the tab's animation. [CN] 停止 Tab 的动画。
     */
    open override func stopAnimation() {
        stopAnimatedImage()
        cyl_stopTabBarItemAnimation()
    }

    /// [EN] The tab's animated image (a GIF given as the tab image): the selected one when it is animated, else the normal
    ///      one, as the classic tab bar plays it (a still selected copy plays the normal image's frames).
    /// [CN] Tab 的动图（作为 Tab 图片传入的 GIF）：选中图片是动图时取选中图片，否则取普通图片，与经典 TabBar 的播放方式相同（静态的选中副本播放普通图片的帧）。
    private var animatedTabImage: UIImage? {
        let item = tabBarItemStorage
        if let selected = item?.selectedImage, (selected.images?.count ?? 0) > 1 { return selected }
        if let normal = item?.image, (normal.images?.count ?? 0) > 1 { return normal }
        return nil
    }

    /// [EN] The item's animation size (`CYLTabBarLottieSize`). [CN] item 的动画尺寸（`CYLTabBarLottieSize`）。
    private var tabBarAnimationSize: CGSize {
        tabBarItemStorage?.lottieSizeValue?.cgSizeValue ?? .zero
    }


    /// [EN] The animation URL first, as on the system tab bar, then the local path. [CN] 与系统 TabBar 相同，先取动画 URL，再取本地路径。
    private var tabBarAnimationURL: URL? {
        guard let item = tabBarItemStorage else { return nil }
        return item.lottieURL ?? CYLConstants.cyl_getURL(from: item.lottieFilePath)
    }

    /**
     * [EN] The tab bar controller that owns this button, in any style. `-cyl_tabBarController` finds only system styles, so
     *      FlatDesign reads the controller the item was given (`-cylflatdesign_setTabBarController:`), then its child's
     *      (the way `CYLPlusButton` resolves it, #650).
     * [CN] 拥有本按钮的 TabBarController，适用于任意样式。`-cyl_tabBarController` 只查找系统样式，因此扁平样式读取 item 被赋予的控制器
     *      （`-cylflatdesign_setTabBarController:`），再读取其子控制器的（与 `CYLPlusButton` 的查找方式相同，#650）。
     */
    private var animationTabBarController: CYLTabBarController? {
        if let controller = cylTabBarController() {
            return controller
        }
        let item = tabBarItemStorage
        return (item?.cylflatdesign_tabBarController ?? item?.childViewController?.cylflatdesign_tabBarController) as? CYLTabBarController
    }

    /**
     * [EN] The controller's `contentMode` for the animation view; without a controller, the documented default (aspect fit),
     *      never 0 (scale to fill). Only the first call matters: the animation view keeps the mode it was created with.
     * [CN] 控制器为动画视图设置的 `contentMode`；没有控制器时使用文档中的默认值（aspect fit），绝不是 0（scale to fill）。只有第一次调用有效：
     *      动画视图保留创建时的 mode。
     */
    private var animationContentMode: UIView.ContentMode {
        animationTabBarController?.tabBarItemAnimationViewContentMode() ?? .scaleAspectFit
    }

    /// FIX: issue #428 — `-[CYLTabBarController tabBarItemAnimationSpeed]` in flat design, resolved like the content mode.
    private var tabBarAnimationSpeed: CGFloat {
        animationTabBarController?.tabBarItemAnimationSpeed ?? 1
    }

    private func initTabBarItemAnimation() {
        // FIX: issue #604 — only with the `CYLTabBarItemAnimation` subspec. 仅在包含 `CYLTabBarItemAnimation` 子库时。
        guard CYLTabBarItemAnimationCore.service != nil, let url = tabBarAnimationURL else { return }
        let size = tabBarAnimationSize
        cyl_addTabBarItemAnimation(with: url, size: size, contentMode: animationContentMode, animationSpeed: tabBarAnimationSpeed)
    }

    private func updateTabBarItemAnimation() {
        // FIX: issue #604 — only with the `CYLTabBarItemAnimation` subspec. 仅在包含 `CYLTabBarItemAnimation` 子库时。
        guard CYLTabBarItemAnimationCore.service != nil, tabBarItemStorage != nil, isSelected else { return }
        guard let url = tabBarAnimationURL else {
            // FIX: issue #477 — a selected tab without an animation: the animated tabs stop and go back to their first
            // frame, as when another animated tab is selected. 选中没有动画的 Tab：有动画的 Tab 停止并回到第一帧，与选中其他动画 Tab 时一致。
            if let tabBar = flatDesignTabBar {
                unsafeBitCast(tabBar as AnyObject, to: CYLFlatDesignTabBarButtonPrivateAPI.self).stopAllTabBarItemAnimations()
            }
            return
        }
        let size = tabBarAnimationSize
        // [EN] The selected button can get here before `initTabBarItemAnimation()`; add the view with the speed first (#428).
        // [CN] 选中的按钮可能先于 `initTabBarItemAnimation()` 执行到这里；先按速度添加视图（#428）。
        cyl_addTabBarItemAnimation(with: url, size: size, contentMode: animationContentMode, animationSpeed: tabBarAnimationSpeed)
        cyl_playTabBarItemAnimation(with: url, size: size, defaultSelected: false, contentMode: animationContentMode)
    }

    /**
     * [EN] Returns the view that hosts this button's badge.
     * [CN] 返回承载该按钮角标的视图。
     */
    @objc open func actualBadgeSuperView() -> UIView {
        (self as UIView).cyl_getActualBadgeSuperView() as? UIView ?? self
    }

    // MARK: - VoiceOver

    /*
     * [EN] VoiceOver: the flat design tab bar is made of plain views, so a tab was read as loose pieces (its badge, then its
     *      title) with no button role or selected state. Each button is one element: its title, the button and selected
     *      traits, and its badge as the value (set by `UIView+CYLBadgeExtention`, e.g. "Messages, 3 new messages"). A slot
     *      without a title (the one under the plus button) is not an element; the plus button is.
     * [CN] VoiceOver：扁平样式 TabBar 由普通视图组成，Tab 会被拆成零散的内容（先读角标再读标题），没有按钮角色和选中状态。每个按钮
     *      是一个元素：标题、按钮与选中特征，角标作为值（由 `UIView+CYLBadgeExtention` 设置，如“消息，3 条新消息”）。没有标题的位置
     *      （加号按钮下方）不作为元素，由加号按钮代替。
     */
    open override var isAccessibilityElement: Bool {
        get { !(accessibilityLabel ?? "").isEmpty }
        set { super.isAccessibilityElement = newValue }
    }

    open override var accessibilityLabel: String? {
        get {
            if let label = super.accessibilityLabel {
                return label
            }
            if let title = tabBarItemStorage?.title, !title.isEmpty {
                return title
            }
            return titleLabel.text
        }
        set { super.accessibilityLabel = newValue }
    }

    open override var accessibilityTraits: UIAccessibilityTraits {
        get { super.accessibilityTraits.union(isSelected ? [.button, .selected] : .button) }
        set { super.accessibilityTraits = newValue }
    }
}
