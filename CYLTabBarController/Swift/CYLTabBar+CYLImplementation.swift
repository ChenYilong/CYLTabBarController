//
//  CYLTabBar+CYLImplementation.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

// [EN] The implementation of `CYLTabBar`, translated from Objective-C (docs/Swift-Migration.md, step 51). The class stays
//      declared in Objective-C: `CYLTabBarController.h` and `CYLPlusButton.h` name it, so it moves with them. CYLTabBar.m
//      keeps the overrides and the public accessors as one-line forwards to the `cyl_tabBar…` methods below (declared
//      there), the stored properties without logic (synthesized), and the iOS 27.1 hinge interaction (it needs the iOS
//      27.1 SDK, which only the preprocessor can check).
// [CN] `CYLTabBar` 的实现，已从 Objective-C 翻译（docs/Swift-Migration.md，第 51 步）。类仍在 Objective-C 中声明：
//      `CYLTabBarController.h` 与 `CYLPlusButton.h` 引用了它，因此随它们一起迁移。CYLTabBar.m 保留重写方法与公开存取方法（均为一行转发到下面的
//      `cyl_tabBar…` 方法，在该文件中声明）、没有逻辑的存储属性（自动合成），以及 iOS 27.1 的铰链交互（需要 iOS 27.1 SDK，只有预处理器能判断）。

/**
 * [EN] Private methods of `CYLTabBarController` (Objective-C, or declared only in the private header) that the tab bar calls.
 * [CN] TabBar 调用的 `CYLTabBarController` 私有方法（Objective-C 实现，或只在私有头文件中声明）。
 */
@objc private protocol CYLTabBarOwnerPrivateAPI {
    /// FIX: issue #610 — implemented in CYLTabBarController.m.
    @objc(cyl_bindTabControlActions) func bindTabControlActions()
    /// FIX: issue #22 — implemented in CYLTabBarController.m.
    @objc(cyl_runPendingReloadBadgesBlocksIfReady) func runPendingReloadBadgesBlocksIfReady()
    /// [EN] The plus button in the Liquid Glass layers, idempotent. [CN] 液态玻璃图层中的 PlusButton，可重复调用。
    @objc(cyl_layOutPlusButtonInLiquidGlassLayers) func layOutPlusButtonInLiquidGlassLayers()
    /// [EN] Declared in CYLTabBarController+CYLPrivate.h. [CN] 在 CYLTabBarController+CYLPrivate.h 中声明。
    @objc(cyl_syncTabBarItemAccessibility) func syncTabBarItemAccessibility()
    @objc(cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded) func fixOpaqueTabBarSafeAreaInsetsIfNeeded()
}

/**
 * [EN] The optional class method of `CYLPlusButtonSubclassing` the tab bar asks the plus button's class for.
 * [CN] TabBar 向 PlusButton 的类询问的 `CYLPlusButtonSubclassing` 可选类方法。
 */
@objc private protocol CYLPlusButtonCenterYOffsetSource {
    @objc(constantOfPlusButtonCenterYOffsetForTabBarHeight:) func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat
}

/**
 * [EN] The state of one `CYLTabBar` (the stored values of its public properties with logic, and its private state).
 * [CN] 一个 `CYLTabBar` 的状态（有逻辑的公开属性的存储值，以及私有状态）。
 */
final class CYLTabBarStorage: NSObject {
    var tabBarItemWidth: CGFloat = 0
    var tabImageViewDefaultOffset: CGFloat = 0
    var itemEdgeInsets: UIEdgeInsets = .zero
    var tabBarButtonArray: [UIControl] = []
    var plusButton: CYLPlusButton?

    /// [EN] YES between `-beginCustomizingItems:` and the end of More editing. [CN] 在 `-beginCustomizingItems:` 与「More」编辑结束之间为 YES。
    var isCustomizingItems = false
    /// [EN] The window point and time of the last touch hit test, see `cylTouchWindowLocation(of:)`. [CN] 最近一次触摸 hitTest 的窗口坐标与时间。
    var lastTouchHitWindowPoint: CGPoint?
    var lastTouchHitTime: TimeInterval = 0
    /// [EN] The views whose `alpha` is observed, and their observations. [CN] 被观察 `alpha` 的视图及其观察。
    var alphaObservations: [ObjectIdentifier: NSKeyValueObservation] = [:]
    /// Whether the last layout found the tab buttons in the iOS 27.1 vertical bar, see `cylRefreshTabButtonsAfterVerticalBar()`.
    var wasShowingVerticalBar = false
    /// The items whose `title` and `badgeValue` are observed, and the observations, see `cylObserveItemTitles()`.
    var titleObservedItems: [UITabBarItem] = []
    var itemObservations: [NSKeyValueObservation] = []
    /// Whether `-cyl_reloadTabButtons` has a reload scheduled.
    var isTabButtonsReloadPending = false
    /// Whether the scheduled reload also sets the items' titles again (after the vertical bar).
    var reloadSetsItemTitles = false
    /// While the reload sets the items' titles again: their `title` changes are not reloads to schedule.
    var isSettingItemTitles = false
    /// Receives the `UIScrollEdgeElementContainerInteraction`s added to the tab bar, see `-addInteraction:`.
    var scrollEdgeElementContainerView: UIView?
    /// [EN] The x of the first slot and the gap between slots of the last layout with a plus button (0 unless centered).
    /// [CN] 上次带 PlusButton 布局时第一个位置的 x 与位置间距（未居中时均为 0）。
    var itemLayoutLeading: CGFloat = 0
    var itemLayoutSpacing: CGFloat = 0
    /// FIX: issue #488. The token of the block-based animation observer: `-removeObserver:self` cannot remove it.
    var animationPlayingObserver: NSObjectProtocol?
    /// [EN] While the library sets a classic style for itself: not synced to the appearances. [CN] 本库自己设置经典样式期间：不同步到 appearance。
    var isSettingClassicStyleInternally = false
    /// [EN] The platter width when titles were last cut. [CN] 上次截断标题时的 platter 宽度。
    var cutPlatterWidth: CGFloat = 0

    /// [EN] Removes every observer; called by `-dealloc`. [CN] 移除所有观察者；由 `-dealloc` 调用。
    func invalidate() {
        if let animationPlayingObserver {
            NotificationCenter.default.removeObserver(animationPlayingObserver)
            self.animationPlayingObserver = nil
        }
        alphaObservations.values.forEach { $0.invalidate() }
        alphaObservations.removeAll()
        itemObservations.forEach { $0.invalidate() }
        itemObservations.removeAll()
        titleObservedItems.removeAll()
    }
}

private enum CYLTabBarImplementationKeys {
    static var storage: UInt8 = 0
    /// [EN] Key of the `hidden` value a view inserted by the library had before More editing hid it.
    /// [CN] 「More」编辑隐藏本库插入的视图之前，该视图原来的 `hidden` 值的 key。
    static var hiddenBeforeCustomizing: UInt8 = 0
    /// [EN] An item's full title, and the title it shows, while it is cut because the titles overflow the platter.
    /// [CN] 标题因超出 platter 而被截断时，item 的完整标题及其显示的标题。
    static var fullTitle: UInt8 = 0
    static var shownTitle: UInt8 = 0
}

/// [EN] Whether a coalesced send of the plus button's actions is pending (one per run loop turn). [CN] 是否已安排一次合并后的 PlusButton 事件补发（每个 run loop 一次）。
@MainActor private var cylIsPlusButtonActionsSendPending = false

/// [EN] `attributes` with the foreground color replaced (removed for nil). [CN] 替换（为 nil 时移除）前景色后的 `attributes`。
private func cylTitleAttributesWithColor(_ attributes: [NSAttributedString.Key: Any], _ color: UIColor?) -> [NSAttributedString.Key: Any] {
    var result = attributes
    result[.foregroundColor] = color
    return result
}

/**
 * [EN] The widest title width that frees `width` when every wider title is cut to it, taking from the longest titles
 *      first (`widths` holds every title's width).
 * [CN] 把所有更宽的标题截断到该宽度后能让出 `width` 的最大标题宽度，先从最长的标题中让出（`widths` 为各标题的宽度）。
 */
private func cylTitleWidthCapRemovingWidth(_ widths: [CGFloat], _ width: CGFloat) -> CGFloat {
    let sorted = widths.sorted(by: >)
    var sum: CGFloat = 0
    for count in 1...max(sorted.count, 1) where count <= sorted.count {
        sum += sorted[count - 1]
        let next = count < sorted.count ? sorted[count] : 0
        // [EN] Cutting the `count` longest titles to `cap` frees `sum - count * cap`. [CN] 把最长的 `count` 个标题截断到 `cap` 可让出 `sum - count * cap`。
        let cap = (sum - width) / CGFloat(count)
        if cap >= next {
            return max(0, cap.rounded(.down))
        }
    }
    return 0
}

/// [EN] `title`, or its longest start followed by "…", that fits in `width`. [CN] 能放进 `width` 的 `title`，或其后接「…」的最长前缀。
private func cylTitleFittingWidth(_ title: String, _ width: CGFloat, _ font: UIFont) -> String {
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    func fits(_ text: String) -> Bool {
        (text as NSString).size(withAttributes: attributes).width.rounded(.up) <= width
    }
    if fits(title) {
        return title
    }
    let ellipsis = "\u{2026}"
    // [EN] Cut at whole characters (emoji, CJK), longest start first. [CN] 按完整字符截断（emoji、中日韩文字），从最长前缀开始尝试。
    var end = title.endIndex
    while end > title.startIndex {
        end = title.index(before: end)
        let candidate = title[..<end].trimmingCharacters(in: .whitespaces) + ellipsis
        if fits(candidate) {
            return candidate
        }
    }
    return ellipsis
}

extension CYLTabBar {

    var cylTabBarStorage: CYLTabBarStorage {
        if let storage = objc_getAssociatedObject(self, &CYLTabBarImplementationKeys.storage) as? CYLTabBarStorage {
            return storage
        }
        let storage = CYLTabBarStorage()
        objc_setAssociatedObject(self, &CYLTabBarImplementationKeys.storage, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return storage
    }

    private func cylControllerPrivateAPI(_ controller: CYLTabBarController) -> CYLTabBarOwnerPrivateAPI {
        unsafeBitCast(controller as AnyObject, to: CYLTabBarOwnerPrivateAPI.self)
    }

    /// [EN] The plus button registered for this tab bar's owner (`+[CYLPlusButton plusButtonForOwner:]`). [CN] 为本 TabBar 所属者注册的 PlusButton。
    private var cylRegisteredPlusButton: CYLPlusButton? {
        CYLPlusButton(forOwner: self)
    }

    // MARK: - [EN] Life cycle [CN] 生命周期

    /**
     * [EN] Called by `-initWithFrame:` and `-initWithCoder:`: the defaults and the animation observer.
     * [CN] 由 `-initWithFrame:` 与 `-initWithCoder:` 调用：默认值与动画观察者。
     */
    @objc(cyl_tabBarSharedInit)
    func cylTabBarSharedInit() {
        syncsClassicStylesToAppearance = true
        let storage = cylTabBarStorage
        storage.tabBarItemWidth = cyl_tabBarItemWidth
        // Only with an animation library (#604, checked at runtime so that any library works): without one there is no
        // animation view to stop (#488). 仅在引入动画库时监听（#604，运行时判断，以支持任意动画库）：没有时没有需要停止的动画（#488）。
        if CYLTabBarItemAnimationCore.service != nil {
            // FIX: issue #488 keep the token and remove it in `-dealloc`; it was dropped, so every tab bar (one per tab bar
            // controller, e.g. each time `window.rootViewController` is replaced) left an observer behind for good.
            // 保存 token 并在 `-dealloc` 中移除；以前直接丢弃，每个 TabBar（每次替换 `window.rootViewController` 都会新建）都会永久留下一个观察者。
            storage.animationPlayingObserver = NotificationCenter.default.addObserver(
                forName: .cylTabBarItemAnimationPlaying, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    // Library-neutral (#604): every animation library (Lottie, PAG), from the `CYLTabBarItemAnimation` subspec.
                    // 与动画库无关：所有动画库（Lottie、PAG），由 `CYLTabBarItemAnimation` 子库处理。
                    guard let self, CYLTabBarItemAnimationCore.service != nil else { return }
                    self.cylStopAllTabBarItemAnimations()
                }
            }
        }
    }

    /// [EN] Called by `-dealloc`: removes the observers. [CN] 由 `-dealloc` 调用：移除观察者。
    @objc(cyl_tabBarDealloc)
    func cylTabBarDealloc() {
        cylTabBarStorage.invalidate()
    }

    @objc(cyl_tabBarSizeThatFits:)
    func cylTabBarSizeThatFits(_ sizeThatFits: CGSize) -> CGSize {
        var size = sizeThatFits
        if CYLConstants.isLiquidGlassActive() {
            // [CN] 液态玻璃不支持自定义高度，液态玻璃系统样式是固定高度的。
            // [EN] Liquid Glass does not support a custom height: the Liquid Glass system style has a fixed height.
            return size
        }
        let tabBarController = cylTabBarController
        let height = (tabBarController?.tabBarHeight ?? 0) + (tabBarController?.view.safeAreaInsets.bottom ?? 0)
        if height > 0 {
            size.height = height
        }
        return size
    }

    // MARK: - [EN] Public properties [CN] 公开属性

    @objc(cyl_tabBarContext)
    func cylTabBarContext() -> String? {
        cyl_context
    }

    @objc(cyl_tabBarSetContext:)
    func cylTabBarSetContext(_ context: String?) {
        cyl_context = context
        cylTabBarSetPlusButton(cylRegisteredPlusButton)
    }

    @objc(cyl_tabBarTabBarButtonArray)
    func cylTabBarTabBarButtonArray() -> [UIControl] {
        cylTabBarStorage.tabBarButtonArray
    }

    @objc(cyl_tabBarSetTabBarButtonArray:)
    func cylTabBarSetTabBarButtonArray(_ tabBarButtonArray: [UIControl]?) {
        cylTabBarStorage.tabBarButtonArray = tabBarButtonArray ?? []
    }

    @objc(cyl_tabBarTabBarItemWidth)
    func cylTabBarTabBarItemWidth() -> CGFloat {
        cylTabBarStorage.tabBarItemWidth
    }

    /**
     * [EN] Sends a KVO notification (`tabBarItemWidth`, manual) and `CYLTabBarItemWidthDidChangeNotification` when the
     *      width changes.
     * [CN] 宽度改变时发出 KVO 通知（`tabBarItemWidth`，手动）与 `CYLTabBarItemWidthDidChangeNotification`。
     */
    @objc(cyl_tabBarSetTabBarItemWidth:)
    func cylTabBarSetTabBarItemWidth(_ tabBarItemWidth: CGFloat) {
        let storage = cylTabBarStorage
        guard storage.tabBarItemWidth != tabBarItemWidth else { return }
        willChangeValue(forKey: "tabBarItemWidth")
        storage.tabBarItemWidth = tabBarItemWidth
        didChangeValue(forKey: "tabBarItemWidth")
        NotificationCenter.default.post(name: NSNotification.Name("CYLTabBarItemWidthDidChangeNotification"), object: self)
        // [EN] `CYL_IS_IPHONE_X`: a screen of at least 375 × 812 pt. [CN] `CYL_IS_IPHONE_X`：屏幕至少为 375 × 812 pt。
        if let size = cylTabBarController?.visiableTabBarSize(),
           min(size.width, size.height) >= 375 && max(size.width, size.height) >= 812 {
            layoutIfNeeded()
        }
    }

    @objc(cyl_tabBarTabImageViewDefaultOffset)
    func cylTabBarTabImageViewDefaultOffset() -> CGFloat {
        cylTabBarStorage.tabImageViewDefaultOffset
    }

    /**
     * FIX: issue #257
     * [EN] Every assignment sent a KVO notification, and `CYLTabBarController` then wrote `imageInsets` and
     *      `titlePositionAdjustment` into every tab bar item again, which lays the tab bar out again. Notify only when the
     *      value really changes.
     * [CN] 以前每次赋值都会发出 KVO 通知，`CYLTabBarController` 随即重新写入所有 TabBarItem 的 `imageInsets` 和
     *      `titlePositionAdjustment`，这又会导致 TabBar 重新布局。现在只在值真正改变时才通知。
     */
    private func cylSetTabImageViewDefaultOffset(_ offset: CGFloat) {
        let storage = cylTabBarStorage
        guard offset != 0, offset != storage.tabImageViewDefaultOffset else { return }
        willChangeValue(forKey: "tabImageViewDefaultOffset")
        storage.tabImageViewDefaultOffset = offset
        didChangeValue(forKey: "tabImageViewDefaultOffset")
    }

    @objc(cyl_tabBarItemEdgeInsets)
    func cylTabBarItemEdgeInsets() -> UIEdgeInsets {
        cylTabBarStorage.itemEdgeInsets
    }

    @objc(cyl_tabBarSetItemEdgeInsets:)
    func cylTabBarSetItemEdgeInsets(_ itemEdgeInsets: UIEdgeInsets) {
        let storage = cylTabBarStorage
        guard storage.itemEdgeInsets != itemEdgeInsets else { return }
        storage.itemEdgeInsets = itemEdgeInsets
        setNeedsLayout()
    }

    @objc(cyl_isCustomizingItems)
    func cylIsCustomizingItems() -> Bool {
        cylTabBarStorage.isCustomizingItems
    }

    /**
     * [EN] The plus button and its child view controller are bound to the CYLTabBarController (by its `context`), not to
     *      this tab bar. The tab bar finds them through the controller that owns it (`+[CYLPlusButton plusButtonForOwner:]`
     *      asks the tab bar's `delegate`), so it always agrees with `-[CYLTabBarController hasPlusButton]`, also when
     *      several plus buttons are registered (#414). Before the controller is set, its own `context` is used, which the
     *      controller copies to it.
     * [CN] PlusButton 及其子控制器绑定的是 CYLTabBarController（通过它的 `context`），而不是这个 TabBar。TabBar 通过拥有它的控制器
     *      找到它们（`+[CYLPlusButton plusButtonForOwner:]` 会询问 TabBar 的 `delegate`），因此始终与 `-[CYLTabBarController hasPlusButton]`
     *      一致，注册了多个时也是如此（#414）。控制器还没设置时，使用 TabBar 自己的 `context`，它是控制器复制过来的。
     */
    @objc(cyl_tabBarHasPlusButton)
    func cylTabBarHasPlusButton() -> Bool {
        cylRegisteredPlusButton != nil
    }

    @objc(cyl_tabBarHasPlusChildViewController)
    func cylTabBarHasPlusChildViewController() -> Bool {
        CYLPlusButton.plusChildViewController(forOwner: self) != nil
    }

    /// [EN] The plus button while it is in this tab bar and registered for its context. [CN] PlusButton 位于本 TabBar 中且为其 context 注册时返回它。
    @objc(cyl_tabBarPlusButton)
    func cylTabBarPlusButton() -> CYLPlusButton? {
        guard cylRegisteredPlusButton != nil, let plusButton = cylTabBarStorage.plusButton else { return nil }
        return plusButton.superview == self ? plusButton : nil
    }

    @objc(cyl_tabBarSetPlusButton:)
    func cylTabBarSetPlusButton(_ plusButton: CYLPlusButton?) {
        guard let plusButton, cylTabBarHasPlusButton() else { return }
        cylTabBarStorage.plusButton = plusButton
        guard !isPlusButtonActive, plusButton.superview == nil else { return }
        // [CN] 待改进：iOS26 考虑应该放进选中图层，而非粗暴放进最底层，这样未来可以 PlusButton 支持自定义index
        // [EN] To improve: on iOS26, consider putting this into the selected layer instead of crudely putting it at the bottom,
        //      so that PlusButton can support a custom index in the future.
        cylAddPlatterViewThenBringSubview(toFront: plusButton)
        isPlusButtonActive = true
        plusButton.cylSetTabBarController(cylTabBarController)
    }

    @objc(cyl_tabBarIsPlusButtonLayoutCentered)
    func cylTabBarIsPlusButtonLayoutCentered() -> Bool {
        cylTabBarPlusButton().map { $0.cylIsLayoutCentered() } ?? false
    }

    /// [EN] The owner (its `delegate`) first; the `-cyl_tabBarController` fallback walk only when it has none.
    /// [CN] 优先取所属者（其 `delegate`）；没有时才回退到 `-cyl_tabBarController` 的查找。
    @objc(cyl_tabBarOwningTabBarController)
    func cylTabBarOwningTabBarController() -> CYLTabBarController? {
        if let owner = delegate as? CYLTabBarController {
            return owner
        }
        return cylTabBarController
    }

    // MARK: - [EN] Classic styles and UITabBarAppearance [CN] 经典样式与 UITabBarAppearance

    private func cylPresetUnselectedItemTintColor() {
        if unselectedItemTintColor != nil {
            return
        }
        var tabLabelTextColor = UIColor.cyl_systemGray
        for childView in cylTabBarStorage.tabBarButtonArray where !childView.isSelected {
            if childView.cylTabEffectView() != nil, let label = childView.cylTabLabel() {
                tabLabelTextColor = label.textColor
            }
        }
        if #available(iOS 26.0, *) {
            // fix #631
            for tabButton in cylTabBarSubviews() {
                for case let label as UILabel in tabButton.subviews where label.cylIsTabLabel() {
                    tabLabelTextColor = label.textColor
                    break
                }
            }
        }
        // [EN] The color the items already show: not an app's style to sync. [CN] item 当前已显示的颜色：不是需要同步的 App 样式。
        let storage = cylTabBarStorage
        storage.isSettingClassicStyleInternally = true
        unselectedItemTintColor = tabLabelTextColor
        storage.isSettingClassicStyleInternally = false
    }

    /**
     * [EN] Since iOS 13, once a tab bar uses `UITabBarAppearance` (any `standardAppearance = ...`), UIKit ignores the classic
     *      styles (`tintColor`, `barTintColor`, `unselectedItemTintColor`, `backgroundImage`, `shadowImage`, `barStyle`).
     *      Each classic setter therefore also writes its value into `standardAppearance` (and `scrollEdgeAppearance` when
     *      there is one), so both ways of styling keep working together. Only a value that changed is written. Not with
     *      Liquid Glass, where the system draws the bar, nor while `syncsClassicStylesToAppearance` is NO.
     * [CN] iOS 13 起，TabBar 一旦使用 `UITabBarAppearance`（任何 `standardAppearance = ...`），UIKit 就会忽略经典样式（`tintColor`、
     *      `barTintColor`、`unselectedItemTintColor`、`backgroundImage`、`shadowImage`、`barStyle`）。因此每个经典 setter 同时把值写入
     *      `standardAppearance`（存在 `scrollEdgeAppearance` 时也写入），两种设置方式可以同时使用。只写入发生变化的值。液态玻璃（由系统
     *      绘制 TabBar）以及 `syncsClassicStylesToAppearance` 为 NO 时不同步。
     */
    private func cylShouldSyncClassicStyle() -> Bool {
        syncsClassicStylesToAppearance && !cylTabBarStorage.isSettingClassicStyleInternally && !CYLUtils.isLiquidGlassActive()
    }

    private func cylSyncClassicStyle(bar barBlock: ((UITabBarAppearance) -> Void)?,
                                     item itemBlock: ((UITabBarItemAppearance) -> Void)?) {
        let apply: (UITabBarAppearance) -> Void = { appearance in
            barBlock?(appearance)
            if let itemBlock {
                appearance.cylApplyItemAppearance(itemBlock)
            }
        }
        let standardAppearance = standardAppearance.copy()
        apply(standardAppearance)
        self.standardAppearance = standardAppearance
        if let scrollEdgeAppearance = scrollEdgeAppearance?.copy() {
            apply(scrollEdgeAppearance)
            self.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }

    /// [EN] Called by `-setTintColor:` after super. [CN] 由 `-setTintColor:` 在调用 super 之后调用。
    @objc(cyl_tabBarSyncTintColor:)
    func cylTabBarSyncTintColor(_ tintColor: UIColor?) {
        guard let tintColor, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: nil) { itemAppearance in
            itemAppearance.selected.iconColor = tintColor
            itemAppearance.selected.titleTextAttributes = cylTitleAttributesWithColor(itemAppearance.selected.titleTextAttributes, tintColor)
        }
    }

    @objc(cyl_tabBarSyncUnselectedItemTintColor:previous:)
    func cylTabBarSyncUnselectedItemTintColor(_ color: UIColor?, previous: UIColor?) {
        guard color != previous, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: nil) { itemAppearance in
            itemAppearance.normal.iconColor = color
            itemAppearance.normal.titleTextAttributes = cylTitleAttributesWithColor(itemAppearance.normal.titleTextAttributes, color)
        }
    }

    @objc(cyl_tabBarSyncBarTintColor:previous:)
    func cylTabBarSyncBarTintColor(_ color: UIColor?, previous: UIColor?) {
        guard color != previous, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: { $0.backgroundColor = color }, item: nil)
    }

    @objc(cyl_tabBarSyncBackgroundImage:previous:)
    func cylTabBarSyncBackgroundImage(_ image: UIImage?, previous: UIImage?) {
        guard image !== previous, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: { $0.backgroundImage = image }, item: nil)
    }

    @objc(cyl_tabBarSyncShadowImage:previous:)
    func cylTabBarSyncShadowImage(_ image: UIImage?, previous: UIImage?) {
        guard image !== previous, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: { $0.shadowImage = image }, item: nil)
    }

    @objc(cyl_tabBarSyncBarStyle:previous:)
    func cylTabBarSyncBarStyle(_ barStyle: UIBarStyle, previous: UIBarStyle) {
        guard barStyle != previous, cylShouldSyncClassicStyle() else { return }
        cylSyncClassicStyle(bar: { appearance in
            appearance.backgroundEffect = UIBlurEffect(style: barStyle == .default ? .systemChromeMaterialLight : .systemChromeMaterialDark)
        }, item: nil)
    }

    // MARK: - [EN] Layout [CN] 布局

    /// [EN] Called by `-layoutSubviews` after super. [CN] 由 `-layoutSubviews` 在调用 super 之后调用。
    @objc(cyl_tabBarLayoutSubviews)
    func cylTabBarLayoutSubviews() {
        cylLayoutTabBarSubviews()
        let storage = cylTabBarStorage
        let showsVerticalBar = cylVerticalBarTabButton(at: 0) != nil
        if storage.wasShowingVerticalBar && !showsVerticalBar {
            cylRefreshTabButtonsAfterVerticalBar()
        }
        storage.wasShowingVerticalBar = showsVerticalBar
        cylObserveItemTitles()
        let owningTabBarController = cylTabBarOwningTabBarController()
        // FIX: issue #610 — UIKit replaces the tab buttons when an item's image changes and lays out only the tab bar,
        // so bind the tap action here as well, not only in the controller's -viewDidLayoutSubviews. Done after the layout
        // above, which sets each new button's visible index (used to recognise the plus child view controller's button).
        // 修改 item 图片后 UIKit 会重建 Tab 按钮且只重新布局 TabBar，所以这里也要为新按钮添加点击事件。放在上面的布局之后，
        // 因为布局时才会设置新按钮的 visible index（用于识别加号子控制器对应的按钮）。
        // FIX: issue #22
        // [EN] UIKit fills `items` during this layout, after the controller's `-viewDidLayoutSubviews`: run the blocks of
        //      `-performWhenTabBarItemsReady:` / `-reloadBadgesWithBlock:` now that they exist.
        // [CN] UIKit 在本次布局中（晚于控制器的 `-viewDidLayoutSubviews`）生成 `items`：此时执行
        //      `-performWhenTabBarItemsReady:` / `-reloadBadgesWithBlock:` 的 block。
        if let owningTabBarController {
            let privateAPI = cylControllerPrivateAPI(owningTabBarController)
            privateAPI.bindTabControlActions()
            privateAPI.runPendingReloadBadgesBlocksIfReady()
        }
        // [EN] Classic style: badges of tab buttons UIKit replaced follow to the new buttons. [CN] 经典样式：角标跟随到 UIKit 替换后的新按钮。
        for item in items ?? [] {
            item.cylMoveBadgeToCurrentTabButtonIfNeeded()
        }
        // The tab titles may have moved: lay the plus button out again so its title follows them
        // (`+alignsTitleWithTabBarItemTitles`).
        cylRegisteredPlusButton?.cyl_setNeedsTitleAlignment()
        cylRunItemLayoutBlocks()
        guard let owningTabBarController else { return }
        let privateAPI = cylControllerPrivateAPI(owningTabBarController)
        // [EN] The bar is laid out again when it comes back after a pop: check the page's safe area under an opaque bar.
        // [CN] pop 返回后 TabBar 会重新布局：检查不透明 TabBar 下页面的安全区域。
        privateAPI.fixOpaqueTabBarSafeAreaInsetsIfNeeded()
        // [EN] The Liquid Glass selected layer can appear in a tab bar layout pass only: put the plus button's stand-in in it
        //      now rather than after a fixed delay. Idempotent; does nothing without Liquid Glass or a plus button.
        //      Only for the controller that owns this tab bar: `-tabBarController` can fall back to another controller.
        // [CN] 液态玻璃的选中层可能只在 TabBar 的布局中出现：此时就放入 PlusButton 的替身，而不是固定延迟之后。可重复调用；没有液态玻璃
        //      或 PlusButton 时不做任何事。只针对拥有本 TabBar 的控制器：`-tabBarController` 可能回退到其他控制器。
        if owningTabBarController.cyl_tabBar === self {
            privateAPI.layOutPlusButtonInLiquidGlassLayers()
            // [EN] A title changed in place lays out only the tab bar: update the tabs' accessibility labels here too.
            // [CN] 原地修改标题时只有 TabBar 重新布局：这里也更新 Tab 的无障碍 label。
            privateAPI.syncTabBarItemAccessibility()
        }
    }

    /// [EN] `-[UITabBarItem cyl_viewDidLayoutSubviewsBlock]` of every item, after the layout. [CN] 布局之后执行各 item 的 `cyl_viewDidLayoutSubviewsBlock`。
    private func cylRunItemLayoutBlocks() {
        for item in items ?? [] {
            if let block = item.cyl_viewDidLayoutSubviewsBlock, let view = item.cyl_tabButton {
                block(item, view)
            }
        }
    }

    private func cylLayoutTabBarSubviews() {
        let storage = cylTabBarStorage
        storage.tabBarButtonArray = cylOriginalTabBarButtons().compactMap { $0 as? UIControl }
        cylPresetUnselectedItemTintColor()
        if let firstButton = storage.tabBarButtonArray.first {
            cylSetupTabImageViewDefaultOffset(firstButton)
        }
        // [CN] FIX: iOS15有时候会导致TaBar透明的问题 但是这样会导致无法主动让TabBar透明 考虑以后添加属性 // 现在通过判断isHidden来处理，如果隐藏了就不再修改alpha
        // [EN] FIX: On iOS15 this sometimes makes the TaBar transparent, but it then prevents making the TabBar transparent
        //      on purpose; consider adding a property later // Now handled by checking isHidden: if hidden, alpha is no
        //      longer modified
        if !CYLConstants.isLiquidGlassActive() {
            cylRemoveAlphaObservers()
            let backgroundView = cylTabBackgroundView()
            cylObserveAlpha(of: cylTabShadowImageView()?.subviews.first)
            if UITabBar.appearance().backgroundImage != nil {
                cylObserveAlpha(of: backgroundView?.cylImageView())
            } else {
                cylObserveAlpha(of: backgroundView?.cylTabEffectView())
            }
        }
        cylCutOverflowingTabTitlesIfNeeded()
        if !isPlusButtonActive {
            cylLayoutTabButtonsWithItemEdgeInsetsIfNeeded()
            didLayoutSubViewsBlock?(self)
            return
        }
        let addedToTabBar = storage.plusButton?.superview == self
        if !addedToTabBar && cylTabBarHasPlusButton() {
            let layout = cylItemLayout(forTabCount: Int(cyl_tabbarItemsCount), plusWidth: 0)
            cyl_tabBarItemWidth = layout.itemWidth
            for (buttonIndex, childView) in storage.tabBarButtonArray.enumerated() {
                // [CN] 仅修改childView的x和宽度,yh值不变
                // [EN] Only change childView's x and width; the y and height values stay the same
                let childViewX = layout.leading + CGFloat(buttonIndex) * (cyl_tabBarItemWidth + layout.spacing)
                cylChangeX(forChildView: childView, childViewX: childViewX, tabBarItemWidth: cyl_tabBarItemWidth, index: buttonIndex)
            }
            didLayoutSubViewsBlock?(self)
            return
        }
        let plusButtonWidth = cylPlusButtonWidth()
        let layout = cylItemLayout(forTabCount: Int(cyl_tabbarItemsCount), plusWidth: plusButtonWidth)
        storage.itemLayoutLeading = layout.leading
        storage.itemLayoutSpacing = layout.spacing
        cyl_tabBarItemWidth = layout.itemWidth
        // [CN] plusButtonIndex内部调整 PlusButton 的中心坐标，不能直接修改 center，否则会造成点击动画时的闪动bug，需要借助坐标系转换。
        // [EN] plusButtonIndex adjusts the PlusButton's center internally. Do not modify center directly, otherwise the
        //      button flickers during the tap animation; use a coordinate-space conversion instead.
        let plusButtonIndex = Int(cylTabBarPlusButtonIndex())
        // [EN] FIX: placeholder count mismatch — whether the plus button's slot is one of the tab buttons, read from
        //      `viewControllers`, not from `cyl_hasPlusChildViewController`: on Liquid Glass a plus button without a child view
        //      controller has a placeholder slot too, and every tab button after it got `cyl_tabBarItemVisibleIndex` + 1
        //      (`-[CYLTabBar cyl_selectedIndex]` returned the next tab's index).
        // [CN] FIX：占位导致的数量不匹配——PlusButton 的 slot 是否是 Tab 按钮之一，从 `viewControllers` 读取，而不是用
        //      `cyl_hasPlusChildViewController`：液态玻璃下没有子控制器的 PlusButton 同样有占位 slot，以前它之后的每个 Tab 按钮的
        //      `cyl_tabBarItemVisibleIndex` 都多 1（`-[CYLTabBar cyl_selectedIndex]` 返回下一个 Tab 的下标）。
        let isPlusSlotAmongTabButtons = cylPlusButtonViewControllerIndex(fallback: NSNotFound) != NSNotFound
        let itemWidth = cyl_tabBarItemWidth
        for (buttonIndex, childView) in storage.tabBarButtonArray.enumerated() {
            // [CN] 调整UITabBarItem的位置
            // [EN] Adjust the position of the UITabBarItem
            var childViewX: CGFloat
            var visibleTabIndex = buttonIndex
            var tabBarItemWidth = itemWidth
            if isPlusSlotAmongTabButtons {
                if buttonIndex <= plusButtonIndex {
                    childViewX = CGFloat(buttonIndex) * itemWidth
                } else {
                    childViewX = CGFloat(buttonIndex - 1) * itemWidth + plusButtonWidth
                }
                if buttonIndex == plusButtonIndex {
                    tabBarItemWidth = plusButtonWidth
                }
            } else if buttonIndex >= plusButtonIndex {
                childViewX = CGFloat(buttonIndex) * itemWidth + plusButtonWidth
                visibleTabIndex = buttonIndex + 1
            } else {
                childViewX = CGFloat(buttonIndex) * itemWidth
            }
            // [EN] Centered positioning, item spacing (see `cylItemLayout(forTabCount:plusWidth:)`): 0 by default.
            // [CN] 居中与间距（见 `cylItemLayout(forTabCount:plusWidth:)`）：默认均为 0。
            let slotIndex = isPlusSlotAmongTabButtons ? buttonIndex : visibleTabIndex
            childViewX += storage.itemLayoutLeading + CGFloat(slotIndex) * storage.itemLayoutSpacing
            childView.cyl_tabBarChildViewControllerIndex = buttonIndex
            cylSelectedContentControl(fromContentControl: childView)?.cyl_tabBarChildViewControllerIndex = buttonIndex
            // [CN] 仅修改childView的x和宽度,yh值不变
            // [EN] Only change childView's x and width; the y and height values stay the same
            cylChangeX(forChildView: childView, childViewX: childViewX, tabBarItemWidth: tabBarItemWidth, index: visibleTabIndex)
        }
        didLayoutSubViewsBlock?(self)
    }

    /**
     * [CN] iOS26+ 玻璃效果不能使用 frame 进行修改， 否则 会引发 手势的 lifted 状态变更后，点击后左右闪动bug。
     * [EN] On iOS26+ the glass effect must not be modified via frame, otherwise after the gesture's lifted state changes,
     *      a tap causes a left-right flicker bug.
     */
    private func cylChangeX(forChildView childView: UIControl, childViewX: CGFloat, tabBarItemWidth: CGFloat, index: Int) {
        if !CYLConstants.isLiquidGlassActive() {
            var x = childViewX
            // [CN] RTL（如阿语）下镜像 x 坐标，使第 0 个 Tab 位于最右侧
            // [EN] Mirror the x coordinate under RTL (e.g. Arabic) so that tab 0 is on the far right
            if cylIsRightToLeftLayout() {
                x = cylBoundsSize().width - x - tabBarItemWidth
            }
            // [CN] 仅修改childView的x和宽度,yh值不变
            // [EN] Only change childView's x and width; the y and height values stay the same
            childView.frame = CGRect(x: x, y: childView.frame.minY, width: tabBarItemWidth, height: childView.frame.height)
        }
        let selectedContentControl = cylSelectedContentControl(fromContentControl: childView)
        childView.cyl_tabBarItemVisibleIndex = index
        guard let selectedContentControl else { return }
        // [CN] 只有玻璃效果有 selectedContentControl，所以可以代替玻璃效果判断。
        //非常重要的 transform 设置， 请勿删除， iOS26+ 玻璃效果+Lottie动画需要禁用形变，否则会引发手势的 lifted 状态变更后的闪动bug。因静态图片场景下不会引起异常， 故未判断是否为Lottie场景
        // [EN] Only the glass effect has selectedContentControl, so it can be used to detect the glass effect.
        //      Very important transform setting, do not delete. On iOS26+, glass effect + Lottie animation needs the
        //      transform disabled, otherwise a flicker bug occurs after the gesture's lifted state changes. Static images
        //      do not cause the problem, so there is no check for whether this is a Lottie scenario.
        selectedContentControl.transform = .identity
    }

    // MARK: - [EN] Alpha observers (iOS 15) [CN] alpha 观察者（iOS 15）

    /// [EN] Keeps `view` visible: an `alpha` set to 0 while the view is not hidden is set back to 1. [CN] 保持 `view` 可见：未隐藏时被设为 0 的 `alpha` 恢复为 1。
    private func cylObserveAlpha(of view: UIView?) {
        guard let view else { return }
        let storage = cylTabBarStorage
        let key = ObjectIdentifier(view)
        guard storage.alphaObservations[key] == nil else { return }
        storage.alphaObservations[key] = view.observe(\.alpha, options: [.new]) { view, change in
            MainActor.assumeIsolated {
                if !view.isHidden && change.newValue == 0 {
                    view.alpha = 1
                }
            }
        }
    }

    /**
     * [EN] Not gated like the registration: the conditions there (Liquid Glass) may have changed since; a view left observed
     *      messages this tab bar after it is deallocated.
     * [CN] 不像注册时那样加条件：注册时的条件（Liquid Glass）之后可能已改变；漏掉的视图会在本 TabBar 释放后继续向它发消息。
     */
    private func cylRemoveAlphaObservers() {
        let storage = cylTabBarStorage
        storage.alphaObservations.values.forEach { $0.invalidate() }
        storage.alphaObservations.removeAll()
    }

    // MARK: - [EN] Fixes of iOS 13 and 14 [CN] iOS 13、14 的修复

    // [EN] `-cyl_fixTruncatedTabTitlesIfNeeded` (titles cut off by a UIKit bug of iOS 13 and 14, fixed in iOS 15) is gone:
    //      the deployment target is iOS 15.
    // [CN] `-cyl_fixTruncatedTabTitlesIfNeeded`（iOS 13、14 的 UIKit bug 截断标题，iOS 15 已修复）已删除：最低部署版本为 iOS 15。

    // MARK: - [EN] More editing [CN]「More」编辑

    /**
     * [EN] More editing ("Edit" on the More page) lets the user drag items onto the tab bar, and UIKit moves and rebuilds the
     *      tab buttons. The views the library inserted into them (`-cyl_markAsInsertedForTabControl:`) and the plus button
     *      are hidden meanwhile, so none is left at a stale position, and they come back when editing ends; the next layout
     *      puts the plus button's stand-in in the new buttons. The library does not support More editing as such: this only
     *      keeps it from leaving views behind. Called by `-beginCustomizingItems:` before super.
     * [CN] 「More」编辑（More 页面中的 "Edit"）允许用户把 item 拖到 TabBar 上，UIKit 会移动并重建 Tab 按钮。编辑期间隐藏本库插入其中的视图
     *      （`-cyl_markAsInsertedForTabControl:`）与 PlusButton，避免留在过时的位置；编辑结束后恢复，下一次布局会把 PlusButton 的替身放进
     *      新按钮。本库并不支持「More」编辑本身，这里只是避免它留下残留视图。由 `-beginCustomizingItems:` 在调用 super 之前调用。
     */
    @objc(cyl_tabBarWillBeginCustomizing)
    func cylTabBarWillBeginCustomizing() {
        cylTabBarStorage.isCustomizingItems = true
        cylSetInsertedViewsHidden(forCustomizing: true)
    }

    /// [EN] Called by `-beginCustomizingItems:` after super. [CN] 由 `-beginCustomizingItems:` 在调用 super 之后调用。
    @objc(cyl_tabBarDidBeginCustomizing)
    func cylTabBarDidBeginCustomizing() {
        cylSetContainerRespondsOutsideBounds(forCustomizing: true)
        cylWaitForCustomizingEnd(polls: 0, sawCustomizing: false)
    }

    /**
     * [EN] FIX: after More editing → Done, Home's icon was missing. UIKit ends the editing without calling
     *      `-endCustomizingAnimated:` (checked with a log: `-beginCustomizingItems:` is called, the end method never is), so
     *      the marked views stayed hidden, and the container kept answering outside its bounds. The end is found by asking
     *      `isCustomizing` every 0.1 s after editing began; it also stops once `-endCustomizingAnimated:` ran.
     * [CN] FIX：「More」编辑 → Done 之后 Home 的图标不见了。UIKit 结束编辑时不会调用 `-endCustomizingAnimated:`（用日志确认：
     *      `-beginCustomizingItems:` 会被调用，结束方法从不被调用），所以被标记的视图一直隐藏，容器也一直在范围之外响应点击。编辑开始后每 0.1 秒
     *      询问一次 `isCustomizing` 来发现结束；`-endCustomizingAnimated:` 被调用时同样会结束。
     */
    private func cylWaitForCustomizingEnd(polls: Int, sawCustomizing: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self, self.cylTabBarStorage.isCustomizingItems else { return }
            let isCustomizing = self.isCustomizing
            // [EN] Never seen as customizing within 3 s (no editing screen): end as well, so nothing stays hidden.
            // [CN] 3 秒内始终没有处于编辑状态（没有出现编辑界面）：同样结束，避免视图一直隐藏。
            if !isCustomizing && (sawCustomizing || polls >= 30) {
                self.cylTabBarDidEndCustomizing()
                return
            }
            self.cylWaitForCustomizingEnd(polls: polls + 1, sawCustomizing: sawCustomizing || isCustomizing)
        }
    }

    /// [EN] Editing ended: gives back the container's hit test, the hidden views and the layout. [CN] 编辑结束：恢复容器的点击判定、被隐藏的视图与布局。
    @objc(cyl_tabBarDidEndCustomizing)
    func cylTabBarDidEndCustomizing() {
        let storage = cylTabBarStorage
        guard storage.isCustomizingItems else { return }
        cylSetContainerRespondsOutsideBounds(forCustomizing: false)
        storage.isCustomizingItems = false
        cylSetInsertedViewsHidden(forCustomizing: false)
        setNeedsLayout()
        // [EN] Again after UIKit's end-of-editing pass, which can rebuild the buttons. [CN] UIKit 结束编辑的处理可能重建按钮，之后再布局一次。
        cylSetNeedsLayoutOnNextRunLoop()
    }

    /**
     * [EN] FIX: More editing could not be closed: its "Done" (and every place above the bar) got no tap. UIKit puts the
     *      editing view (`UITabBarCustomizeView`) next to this tab bar in `_UITabBarContainerView`, whose superview
     *      (`_UITabBarContainerWrapperView`) is only as tall as the bar, so hit testing never reached it and the tap went to
     *      the More page's "Edit" below (seen with lldb; the system `UITabBarController` puts it in its full-screen view).
     *      While editing, that container answers outside its superview's bounds (`-cyl_setRespondsOutsideSuperviewBounds:`);
     *      afterwards it no longer does, so it never takes the page's touches.
     * [CN] FIX：「More」编辑无法关闭：其 "Done"（以及 TabBar 上方的任何位置）收不到点击。UIKit 把编辑视图（`UITabBarCustomizeView`）放在本 TabBar
     *      旁边、`_UITabBarContainerView` 之中，而它的父视图（`_UITabBarContainerWrapperView`）只有 TabBar 那么高，所以点击判定到达不了，点击落到了
     *      下方 More 页面的 "Edit" 上（用 lldb 确认；系统的 `UITabBarController` 把它放在全屏视图中）。编辑期间，该容器在父视图范围之外也响应点击
     *      （`-cyl_setRespondsOutsideSuperviewBounds:`）；编辑结束后取消，不会拦截页面的触摸。
     */
    private func cylSetContainerRespondsOutsideBounds(forCustomizing responds: Bool) {
        guard let container = superview, NSStringFromClass(type(of: container)).contains("TabBarContainer") else { return }
        container.cyl_respondsOutsideSuperviewBounds = responds
    }

    /// [EN] Hides (true) or restores (false) the plus button and every inserted view inside this tab bar, in one pass.
    /// [CN] 一次性隐藏（true）或恢复（false）PlusButton 与本 TabBar 中所有被插入的视图。
    private func cylSetInsertedViewsHidden(forCustomizing hidden: Bool) {
        var views = UIView.cylInsertedTabControlViews().filter { $0.isDescendant(of: self) }
        if let plusButton = cylRegisteredPlusButton, plusButton.isDescendant(of: self) {
            views.append(plusButton)
        }
        for view in views {
            if hidden {
                if objc_getAssociatedObject(view, &CYLTabBarImplementationKeys.hiddenBeforeCustomizing) == nil {
                    objc_setAssociatedObject(view, &CYLTabBarImplementationKeys.hiddenBeforeCustomizing, NSNumber(value: view.isHidden),
                                             .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
                view.isHidden = true
            } else if let hiddenBefore = objc_getAssociatedObject(view, &CYLTabBarImplementationKeys.hiddenBeforeCustomizing) as? NSNumber {
                view.isHidden = hiddenBefore.boolValue
                objc_setAssociatedObject(view, &CYLTabBarImplementationKeys.hiddenBeforeCustomizing, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    // MARK: - [EN] Item positioning (centered, item width, item spacing) [CN] Tab 的排列（居中、宽度、间距）

    /**
     * [EN] The classic tab bar lays its tab buttons out itself when there is a plus button, which used to fill the whole width
     *      and ignore `itemPositioning`, `itemWidth` and `itemSpacing`. They are read as UIKit reads them: the
     *      `standardAppearance` values when set, otherwise the tab bar's own properties.
     * [CN] 有 PlusButton 时，经典 TabBar 自行布局 Tab 按钮，以前总是铺满整个宽度，忽略了 `itemPositioning`、`itemWidth`、`itemSpacing`。
     *      这里按 UIKit 的方式读取：设置了 `standardAppearance` 中的值时使用它们，否则使用 TabBar 自身的属性。
     */
    private func cylItemPositioning() -> (positioning: UITabBar.ItemPositioning, itemWidth: CGFloat, itemSpacing: CGFloat) {
        var positioning = itemPositioning
        var width = itemWidth
        var spacing = itemSpacing
        let appearance = standardAppearance
        if appearance.stackedItemPositioning != .automatic {
            positioning = appearance.stackedItemPositioning
        }
        if appearance.stackedItemWidth > 0 {
            width = appearance.stackedItemWidth
        }
        if appearance.stackedItemSpacing > 0 {
            spacing = appearance.stackedItemSpacing
        }
        // [EN] UIKit centers Automatic tabs in a regular horizontal size class (e.g. iPad): read it the same way, so a spacing
        //      alone keeps UIKit's centered layout there instead of filling with gaps.
        // [CN] UIKit 在 regular 水平尺寸类别（如 iPad）下把 Automatic 的 Tab 居中：这里按同样方式读取，因此只设置间距时，
        //      在那里仍保持 UIKit 的居中布局，而不是铺满加间隙。
        if positioning == .automatic && traitCollection.horizontalSizeClass == .regular {
            positioning = .centered
        }
        return (positioning, width, spacing)
    }

    /**
     * [EN] The horizontal layout of `count` tab buttons plus, when `plusWidth` > 0, one plus button slot: the x of the first
     *      slot (`leading`), the width of a tab slot and the gap between slots. Without centered positioning, an item width or
     *      an item spacing it is the previous layout: leading 0, no gap, the tabs sharing the width left by the plus button.
     *      Centered: the slots keep `itemWidth` (the shared width when 0) and `itemSpacing`, centered as a group; when they do
     *      not fit, the previous layout is used.
     * [CN] `count` 个 Tab 按钮（`plusWidth` > 0 时再加一个 PlusButton 位置）的横向布局：第一个位置的 x（`leading`）、Tab 位置的宽度、
     *      位置之间的间距。未设置居中、item 宽度或间距时与以前的布局相同：leading 为 0、无间距，各 Tab 平分 PlusButton 之外的宽度。
     *      居中时：各位置使用 `itemWidth`（为 0 时使用平分宽度）与 `itemSpacing`，整体居中；放不下时使用以前的布局。
     */
    private func cylItemLayout(forTabCount count: Int, plusWidth: CGFloat) -> (leading: CGFloat, itemWidth: CGFloat, spacing: CGFloat) {
        let edgeInsets = cylTabBarStorage.itemEdgeInsets
        let availableWidth = max(0, cylBoundsSize().width - edgeInsets.left - edgeInsets.right)
        let fillWidth = count > 0 ? (availableWidth - plusWidth) / CGFloat(count) : 0
        let fill = (leading: edgeInsets.left, itemWidth: fillWidth, spacing: CGFloat(0))
        let custom = cylItemPositioning()
        if count == 0 {
            return fill
        }
        let slotCount = count + (plusWidth > 0 ? 1 : 0)
        let centered = custom.positioning == .centered || custom.itemWidth > 0
        if !centered {
            // [EN] A spacing alone fills the width with gaps between the slots; the tab bar shows through them, e.g. as
            //      separators between tabs that have a background color.
            // [CN] 只设置间距时，各位置铺满宽度且之间留有间隙；TabBar 的背景透过间隙显示，例如作为有背景色的 Tab 之间的分隔线。
            let gappedWidth = (availableWidth - plusWidth - custom.itemSpacing * CGFloat(slotCount - 1)) / CGFloat(count)
            if custom.itemSpacing > 0 && gappedWidth > 0 {
                return (edgeInsets.left, gappedWidth, custom.itemSpacing)
            }
            return fill
        }
        let width = custom.itemWidth > 0 ? custom.itemWidth : fillWidth
        let totalWidth = width * CGFloat(count) + plusWidth + custom.itemSpacing * CGFloat(slotCount - 1)
        if totalWidth > availableWidth + 0.5 {
            return fill
        }
        return (edgeInsets.left + (availableWidth - totalWidth) * 0.5, width, custom.itemSpacing)
    }

    /**
     * [EN] Without a plus button UIKit lays the tab buttons out (and honors centered positioning itself). With
     *      `cyl_itemEdgeInsets` they are laid out here instead, between the insets, the same way as with a plus button.
     * [CN] 没有 PlusButton 时由 UIKit 布局 Tab 按钮（居中排列也由 UIKit 处理）。设置了 `cyl_itemEdgeInsets` 时改为在这里布局，
     *      排列在两端空白之间，与有 PlusButton 时的方式相同。
     */
    private func cylLayoutTabButtonsWithItemEdgeInsetsIfNeeded() {
        let edgeInsets = cylTabBarStorage.itemEdgeInsets
        let custom = cylItemPositioning()
        // [EN] UIKit does not leave gaps between filled tabs, so a fill with spacing is laid out here too.
        // [CN] UIKit 铺满时不会在 Tab 之间留间隙，因此铺满加间距时同样在这里布局。
        let fillsWithSpacing = custom.itemSpacing > 0 && custom.itemWidth == 0 && custom.positioning != .centered
        if (edgeInsets.left == 0 && edgeInsets.right == 0 && !fillsWithSpacing) || CYLConstants.isLiquidGlassActive() {
            return
        }
        let tabButtons = cylTabBarStorage.tabBarButtonArray
        let layout = cylItemLayout(forTabCount: tabButtons.count, plusWidth: 0)
        for (index, tabButton) in tabButtons.enumerated() {
            cylChangeX(forChildView: tabButton, childViewX: layout.leading + CGFloat(index) * (layout.itemWidth + layout.spacing),
                       tabBarItemWidth: layout.itemWidth, index: index)
        }
    }

    // MARK: - [EN] Titles too long for the platter [CN] 超出 platter 的标题

    /**
     * [EN] FIX: titles too long for the platter overlapped. The plus button follows its slot (`-plusButtonIndex`), so a
     *      long title is normally left whole; but when the tab buttons together are wider than the platter, UIKit lets them
     *      overlap and the titles run into each other. Only then, and only the longest titles, are cut with "…": after
     *      UIKit's layout the overlap of the buttons is measured, and the longest titles lose that width, the longest first,
     *      so the others keep their full text. Checked again on each layout pass until nothing overlaps. The full title
     *      stays the item's accessibility label, and comes back, to be measured again, when the platter grows (rotation) or
     *      the app sets a new title. Only for the horizontal Liquid Glass bar with a plus button
     *      (`cylShouldCutOverflowingTabTitles()`); elsewhere cut titles get their full text back.
     * [CN] FIX：超出 platter 的长标题互相重叠。PlusButton 跟随它的 slot（`-plusButtonIndex`），所以长标题通常保持完整；但 Tab 按钮总宽度
     *      超过 platter 时，UIKit 让按钮重叠，标题文字互相覆盖。只有这时，并且只截断最长的标题（以「…」结尾）：在 UIKit 布局之后测量按钮的
     *      重叠宽度，由最长的标题依次让出这段宽度，其他标题保持完整。每次布局都再检查一次，直到没有重叠。完整标题作为 item 的无障碍标签，
     *      platter 变宽时（如旋转）或 App 设置新标题时恢复完整标题并重新测量。只用于有 PlusButton 的横向液态玻璃 TabBar
     *      （`cylShouldCutOverflowingTabTitles()`）；其他情况下被截断的标题恢复完整文字。
     */
    private func cylCutOverflowingTabTitlesIfNeeded() {
        guard let items, !items.isEmpty else { return }
        if !cylShouldCutOverflowingTabTitles() {
            cylRestoreCutTabTitles()
            return
        }
        let platterView = cylTabBarContentView()
        let platterWidth = platterView.bounds.width
        guard platterWidth > 0 else { return }
        if cylHasCutTabTitles() {
            if platterWidth > cylTabBarStorage.cutPlatterWidth + 0.5 || cylHasTabTitleSetByAppSinceCut() {
                cylRestoreCutTabTitles()
                cylSetNeedsLayoutOnNextRunLoop()
                return
            }
            // [EN] VoiceOver reads the full title of a cut item. [CN] VoiceOver 读出被截断 item 的完整标题。
            for item in items {
                if let fullTitle = cylFullTitle(of: item), item.accessibilityLabel != fullTitle {
                    item.accessibilityLabel = fullTitle
                }
            }
        }
        platterView.layoutIfNeeded()
        let tabButtons = cylTabBarSubviews()
        guard tabButtons.count == items.count else { return }
        let excess = cylOverflow(ofTabButtons: tabButtons, inPlatterWidth: platterWidth)
        guard excess > 0.5 else { return }
        // [EN] The width each title shows now, in its own label's font. [CN] 每个标题当前显示的宽度，使用其标签的字体。
        let widths: [CGFloat] = items.indices.map { index in
            guard let font = tabButtons[index].cylTabLabel()?.font, let title = items[index].title, !title.isEmpty else { return 0 }
            return (title as NSString).size(withAttributes: [.font: font]).width.rounded(.up)
        }
        let cap = cylTitleWidthCapRemovingWidth(widths, excess + 1)
        var didCut = false
        for (index, item) in items.enumerated() where widths[index] > cap {
            guard let font = tabButtons[index].cylTabLabel()?.font,
                  let fullTitle = cylFullTitle(of: item) ?? item.title else { continue }
            let fittingTitle = cylTitleFittingWidth(fullTitle, cap, font)
            if fittingTitle == item.title {
                continue
            }
            didCut = true
            objc_setAssociatedObject(item, &CYLTabBarImplementationKeys.fullTitle, fullTitle, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            objc_setAssociatedObject(item, &CYLTabBarImplementationKeys.shownTitle, fittingTitle, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            item.accessibilityLabel = fullTitle
            item.title = fittingTitle
        }
        if didCut {
            cylTabBarStorage.cutPlatterWidth = platterWidth
            cylSetNeedsLayoutOnNextRunLoop()
        }
    }

    private func cylFullTitle(of item: UITabBarItem) -> String? {
        objc_getAssociatedObject(item, &CYLTabBarImplementationKeys.fullTitle) as? String
    }

    private func cylShownTitle(of item: UITabBarItem) -> String? {
        objc_getAssociatedObject(item, &CYLTabBarImplementationKeys.shownTitle) as? String
    }

    /**
     * [EN] How much title width is missing: UIKit's tab buttons always overlap a little (about 20 pt on iOS 26.1), so their
     *      frames do not show it; when the titles overflow, UIKit squeezes the title labels instead. So: each label's
     *      missing width (its text against its width), plus labels closer than `minimumTabTitleGap` (UIKit's own gap is about
     *      5 pt) or running past the platter. 0 when every title fits or nothing is laid out.
     * [CN] 缺少多少标题宽度：UIKit 的 Tab 按钮本来就会略微重叠（iOS 26.1 上约 20 pt），按钮 frame 看不出溢出；标题溢出时 UIKit 改为压缩标题
     *      标签。因此取：每个标签缺少的宽度（文字宽度减标签宽度），加上间距小于 `minimumTabTitleGap`（UIKit 自身的间距约 5 pt）或超出 platter 的部分。
     *      所有标题都放得下或尚未布局时为 0。
     */
    private func cylOverflow(ofTabButtons tabButtons: [UIView], inPlatterWidth platterWidth: CGFloat) -> CGFloat {
        let minimumTabTitleGap: CGFloat = 2
        let platterView = cylTabBarContentView()
        var labelFrames: [CGRect] = []
        var excess: CGFloat = 0
        for tabButton in tabButtons {
            if tabButton.frame.width <= 0 {
                return 0
            }
            guard let label = tabButton.cylTabLabel(), label.text?.isEmpty == false, !label.isHidden, label.alpha > 0.01 else { continue }
            let textWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
            excess += max(0, textWidth - label.bounds.width)
            labelFrames.append(label.convert(label.bounds, to: platterView))
        }
        labelFrames.sort { $0.minX < $1.minX }
        for (index, frame) in labelFrames.enumerated() {
            if index > 0 {
                let gap = frame.minX - labelFrames[index - 1].maxX
                excess += max(0, minimumTabTitleGap - gap)
            }
            excess += max(0, -frame.minX) + max(0, frame.maxX - platterWidth)
        }
        return excess
    }

    /// [EN] The only case titles are cut for: iOS 26 and later, Liquid Glass active, not the FlatDesign style, a plus button in
    ///      this tab bar, and the horizontal bar (not the iOS 27.1 vertical bar, which shows no titles).
    /// [CN] 只在这种情况下截断标题：iOS 26 及以上、液态玻璃生效、非扁平样式、本 TabBar 有 PlusButton，且为横向栏（iOS 27.1 竖向栏不显示标题）。
    private func cylShouldCutOverflowingTabTitles() -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        if !CYLConstants.isLiquidGlassActive() || cylTabBarOwningTabBarController()?.tabBarStyleType == .flatDesign || !cylTabBarHasPlusButton() {
            return false
        }
        return !cylTabBarShowsVerticalBar()
    }

    /// [EN] YES while a title is cut. [CN] 有标题被截断时为 YES。
    private func cylHasCutTabTitles() -> Bool {
        (items ?? []).contains { cylFullTitle(of: $0) != nil }
    }

    /// [EN] YES when the app set the title of a cut item since it was cut. [CN] 被截断的 item 在截断之后由 App 设置了标题时为 YES。
    private func cylHasTabTitleSetByAppSinceCut() -> Bool {
        (items ?? []).contains { item in
            guard let shownTitle = cylShownTitle(of: item) else { return false }
            return item.title != shownTitle
        }
    }

    /// [EN] Gives every cut item its full title back, unless the app set another one. [CN] 把每个被截断的 item 恢复为完整标题，App 已设置其他标题时除外。
    private func cylRestoreCutTabTitles() {
        for item in items ?? [] {
            guard let fullTitle = cylFullTitle(of: item) else { continue }
            let shownTitle = cylShownTitle(of: item)
            objc_setAssociatedObject(item, &CYLTabBarImplementationKeys.fullTitle, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            objc_setAssociatedObject(item, &CYLTabBarImplementationKeys.shownTitle, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            item.accessibilityLabel = nil
            if let shownTitle, item.title == shownTitle {
                item.title = fullTitle
            }
        }
    }

    /// [EN] Lays the bar out again on the next run loop, once UIKit has applied changed titles. [CN] 在下一个 run loop（UIKit 应用修改后的标题之后）再次布局 TabBar。
    private func cylSetNeedsLayoutOnNextRunLoop() {
        DispatchQueue.main.async { [weak self] in
            self?.setNeedsLayout()
        }
    }

    // MARK: - [EN] Plus button position [CN] PlusButton 的位置

    private func cylMultiplierOfTabBarHeight() -> CGFloat {
        cylRegisteredPlusButton?.multiplier(ofTabBarHeight: cylBoundsSize().height) ?? 0
    }

    private func cylConstantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        guard let plusButtonClass = cylTabBarPlusButton().map({ $0.cylRuntimeClass as AnyObject }),
              plusButtonClass.responds(to: #selector(CYLPlusButtonCenterYOffsetSource.constantOfPlusButtonCenterYOffset(forTabBarHeight:))) else {
            return 0
        }
        return unsafeBitCast(plusButtonClass, to: CYLPlusButtonCenterYOffsetSource.self).constantOfPlusButtonCenterYOffset(forTabBarHeight: tabBarHeight)
    }

    /**
     * FIX: issue #515
     * [EN] The index in `viewControllers` of the plus button's placeholder or child view controller, or `fallback`.
     * [CN] PlusButton 的占位控制器或子控制器在 `viewControllers` 中的下标，没有时返回 `fallback`。
     */
    private func cylPlusButtonViewControllerIndex(fallback: Int) -> Int {
        let viewControllers = cylTabBarOwningTabBarController()?.viewControllers ?? []
        let plusChildViewController = CYLPlusButton.plusChildViewController(forOwner: self)
        let index = viewControllers.firstIndex { viewController in
            viewController.cyl_isPlaceholder || (plusChildViewController != nil && viewController === plusChildViewController)
        }
        return index ?? fallback
    }

    /// [EN] Moves the plus button to `center` without implicit animation. [CN] 无隐式动画地把 PlusButton 移到 `center`。
    private func cylMovePlusButton(to center: CGPoint) {
        guard let plusButton = cylTabBarPlusButton(), plusButton.center != center else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        plusButton.center = center
        CATransaction.commit()
        // [EN] UIKit (or the vertical bar) may lay out the tab buttons after this pass: check again on the next run loop;
        //      nothing happens once the position is unchanged.
        // [CN] UIKit（或竖向栏）可能在本次布局之后才排好 Tab 按钮：下一个 run loop 再校正一次；位置不变时不会再次触发。
        cylSetNeedsLayoutOnNextRunLoop()
    }

    /// [EN] The plus button's index in the tab bar; also lays the plus button out. [CN] PlusButton 在 TabBar 中的索引；同时布局 PlusButton。
    @objc(cyl_tabBarPlusButtonIndex)
    func cylTabBarPlusButtonIndex() -> UInt {
        let plusButton = cylTabBarPlusButton()
        var plusButtonIndex = plusButton.map { Int($0.cylIndex(forTabbarItemsCount: cyl_tabbarItemsCount)) } ?? 0
        let tabBarWidth = cylBoundsSize().width
        let tabBarHeight = cylBoundsSize().height
        let registeredPlusButton = cylRegisteredPlusButton
        defer {
            registeredPlusButton?.cyl_tabBarChildViewControllerIndex = plusButtonIndex
        }
        // FIX: issue #515
        // [EN] With a plus child view controller (or a placeholder), the plus button covers its tab (the slot), which
        //      `-[CYLTabBarController setViewControllers:]` places by the same rule; without one, between the tabs as before.
        //      The index stored on the plus button (used to select its child view controller) is the slot's index, also
        //      when `+indexOfPlusButtonInTabBar` returns another position.
        // [CN] 有 PlusButton 子控制器（或占位控制器）时位于其 Tab（slot）上方，slot 由 `-[CYLTabBarController setViewControllers:]` 按同一规则放置；
        //      没有时与以前一样位于 Tab 之间。PlusButton 上记录的下标（用于选中其子控制器）就是该 slot 的下标，`+indexOfPlusButtonInTabBar`
        //      返回其他位置时也正确。
        plusButtonIndex = cylPlusButtonViewControllerIndex(fallback: plusButtonIndex)
        CYLPlusButtonIndex = UInt(plusButtonIndex)
        if !CYLConstants.isLiquidGlassActive() {
            let multiplierOfTabBarHeight = cylMultiplierOfTabBarHeight()
            let constantOfPlusButtonCenterYOffset = cylConstantOfPlusButtonCenterYOffset(forTabBarHeight: tabBarHeight)
            cylTabBarStorage.plusButton?.center = CGPoint(x: tabBarWidth * 0.5,
                                                          y: tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset)
            if let plusButton {
                let storage = cylTabBarStorage
                let childViewX = storage.itemLayoutLeading + CGFloat(plusButtonIndex) * (cyl_tabBarItemWidth + storage.itemLayoutSpacing)
                cylChangeX(forChildView: plusButton, childViewX: childViewX, tabBarItemWidth: plusButton.frame.width, index: plusButtonIndex)
            }
            return UInt(plusButtonIndex)
        }
        // FIX: issue #653 — iOS 27.1 vertical bar (folded iPhone Duo, `allowsVerticalBar = YES`).
        // [EN] The system moves the tab buttons out of this bar into a vertical bar on the trailing edge, while the
        //      plus button stays here. Centre it on its placeholder tab button instead of the horizontal position.
        //      Issue #13: the minimized Liquid Glass tab bar (`cyl_tabBarMinimizeBehavior`, iOS 26+) is laid out as the
        //      vertical bar is: the platter shrinks, so the height-based Y offset no longer fits; center on the slot instead.
        // [CN] 系统把 Tab 按钮移出本 TabBar，放进右侧竖向栏，而加号按钮仍在本 TabBar 上，需对齐到它的占位 Tab 按钮中心。
        //      issue #13：缩小后的液态玻璃 TabBar（`cyl_tabBarMinimizeBehavior`，iOS 26+）与竖向栏一样处理：platter 缩小后，
        //      按 TabBar 高度计算的 Y 轴偏移不再适用，改为居中于该 Tab。
        if let centeredSlot = cylVerticalBarTabButton(at: plusButtonIndex) ?? cylMinimizedBarTabButton(at: plusButtonIndex) {
            // Issue #636: centered on the slot, with or without a title, like a plus button without a title. The height
            // methods and the title alignment (`-cyl_alignedCenterForCenter:`) don't apply to the vertical bar, nor to
            // the minimized bar (issue #13).
            // 竖向栏与缩小后的 TabBar 中（issue #13），无论有没有标题，都与没有标题时一样居中于该 Tab；高度相关的代理方法和标题对齐都不适用。
            if let slotSuperview = centeredSlot.superview {
                cylMovePlusButton(to: slotSuperview.convert(centeredSlot.center, to: self))
            }
            return UInt(plusButtonIndex)
        }
        let platterView = cylTabBarContentView()
        // [CN] 系统默认参数
        // [EN] System default parameters
        let multiplierOfTabBarHeight = cylMultiplierOfTabBarHeight()
        let constantOfPlusButtonCenterYOffset = cylConstantOfPlusButtonCenterYOffset(forTabBarHeight: tabBarHeight)
        // [CN] 计算 platterView 中心
        // [EN] Compute the platterView center
        let platterCenter = platterView.superview.map { $0.convert(platterView.center, to: self) } ?? .zero
        // [CN] 叠加系统默认 Y 逻辑
        // [EN] Add the system's default Y logic on top
        var systemDefaultY = tabBarHeight * multiplierOfTabBarHeight + constantOfPlusButtonCenterYOffset
        // A plus button without a title replaces the whole tab item: centered on the platter (the tab items' center),
        // not on the tab bar (`cyl_appliesCenterYOffsetWithoutTitle` in CYLPlusButton.h).
        // 没有标题的 PlusButton 替换整个 TabBarItem：居中于 platter（即 Tab 的中心），而不是 TabBar 的中心。
        if let registeredPlusButton, registeredPlusButton.cylIsCenteredWithoutTitle() {
            systemDefaultY = platterCenter.y
        }
        // FIX: long titles next to the plus button (PlusButton-Slot.md, "Long titles").
        // [EN] Horizontally on the center of its slot, the tab button it covers: UIKit makes a tab with a long title
        //      wider, which moves the slots after it, so the platter's center is no longer the slot's. Titles keep their
        //      full text. The platter's center only while the slot is not laid out.
        // [CN] 水平方向居中于它的 slot（它覆盖的 Tab 按钮）：UIKit 会把长标题的 Tab 变宽，其后的 slot 随之移动，platter 中心不再是
        //      slot 的中心。标题保持完整文字。slot 尚未布局时才使用 platter 中心。
        var centerX = platterCenter.x
        if let slot = cylLiquidGlassPlusButtonSlot(at: plusButtonIndex), let slotSuperview = slot.superview {
            centerX = slotSuperview.convert(slot.center, to: self).x
        }
        // [CN] 计算最终中心
        // [EN] Compute the final center
        var finalCenter = CGPoint(x: centerX, y: systemDefaultY)
        // Issue #636: with the title in the tab item, the image above its title, on the title's vertical center line.
        // 标题由 TabBarItem 显示时：图片位于标题上方，与标题竖向中心线对齐。
        if let registeredPlusButton {
            finalCenter = registeredPlusButton.cylAlignedCenter(forCenter: finalCenter)
        }
        // [CN] 禁止隐式动画
        // [EN] Disable implicit animations
        cylMovePlusButton(to: finalCenter)
        return UInt(plusButtonIndex)
    }

    // MARK: - [EN] Reloading the tab buttons [CN] 重新加载 Tab 按钮

    /**
     * FIX: issue #653 (follow-up)
     * [EN] The iOS 27.1 vertical bar (folded iPhone Duo in landscape, `allowsVerticalBar = YES`) shows the tabs without
     *      titles. Back in the horizontal bar (e.g. rotated to portrait), the tabs kept that layout, without titles, until
     *      a tab was tapped. So when the tab buttons come back, every tab item is updated once, as a tap does: its title is
     *      set again and the tab buttons are laid out again. Runs on the next run loop and once more after the rotation.
     * [CN] iOS 27.1 竖向栏（iPhone Duo 折叠横屏，`allowsVerticalBar = YES`）中 Tab 不显示标题。回到横向栏（如转回竖屏）后，Tab 仍保持
     *      没有标题的布局，直到点击某个 Tab 才恢复。因此 Tab 按钮回到横向栏时，像点击一样把每个 TabBarItem 更新一次：重新设置标题，
     *      并重新布局 Tab 按钮。在下一个 run loop 执行，旋转动画结束后再执行一次。
     */
    private func cylRefreshTabButtonsAfterVerticalBar() {
        cylReloadTabButtons(settingItemTitles: true)
    }

    @objc(cyl_tabBarReloadTabButtons)
    func cylTabBarReloadTabButtons() {
        cylReloadTabButtons(settingItemTitles: false)
    }

    /**
     * FIX: issue #601, #653
     * [EN] Lays the tab buttons out again, as a tap does, on the next run loop and once more 0.5 s later (after a rotation
     *      or an animated title change); calls made in the meantime are merged. `settingItemTitles` also sets every item's
     *      title again first, which the tabs coming back from the vertical bar need to show their titles. Does nothing
     *      while the tab buttons are in the iOS 27.1 vertical bar.
     * [CN] 像点击一样重新布局 Tab 按钮：下一个 run loop 执行一次，0.5 秒后（旋转或标题改变的动画之后）再执行一次；期间的多次调用会合并。
     *      `settingItemTitles` 为 true 时先重新设置每个 item 的标题，从竖向栏返回的 Tab 需要这样才会显示标题。Tab 按钮位于 iOS 27.1
     *      竖向栏时不执行。
     */
    private func cylReloadTabButtons(settingItemTitles: Bool) {
        let storage = cylTabBarStorage
        storage.reloadSetsItemTitles = storage.reloadSetsItemTitles || settingItemTitles
        guard !storage.isTabButtonsReloadPending else { return }
        storage.isTabButtonsReloadPending = true
        let reload: @MainActor (CYLTabBar?, Bool) -> Void = { tabBar, isLast in
            guard let tabBar else { return }
            let storage = tabBar.cylTabBarStorage
            if tabBar.cylVerticalBarTabButton(at: 0) == nil {
                if storage.reloadSetsItemTitles {
                    storage.isSettingItemTitles = true
                    for item in tabBar.items ?? [] {
                        let title = item.title
                        item.title = nil
                        item.title = title
                    }
                    storage.isSettingItemTitles = false
                }
                var views: [UIView] = [tabBar]
                while let view = views.popLast() {
                    view.setNeedsLayout()
                    views.append(contentsOf: view.subviews)
                }
                tabBar.layoutIfNeeded()
            }
            if isLast {
                storage.isTabButtonsReloadPending = false
                storage.reloadSetsItemTitles = false
            }
        }
        DispatchQueue.main.async { [weak self] in reload(self, false) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in reload(self, true) }
    }

    /**
     * FIX: issue #601
     * [EN] Observes the `title` of every item, so a title changed in place (e.g. `viewController.tabBarItem.title = ...`)
     *      reloads the tab buttons (`-cyl_reloadTabButtons`). Liquid Glass otherwise kept their previous layout: the plus
     *      button stayed where its tab was before, off its own title, until a tab was tapped. Also observes `badgeValue`:
     *      a badge that appears or changes (not removed) lets the tab's animation play its badge-changed animation.
     * [CN] 观察每个 item 的 `title`，原地修改标题（如 `viewController.tabBarItem.title = ...`）后重新加载 Tab 按钮
     *      （`-cyl_reloadTabButtons`）。否则液态玻璃保持原来的布局：PlusButton 停在它的 Tab 原来的位置，偏离自己的标题，直到点击某个 Tab。
     *      同时观察 `badgeValue`：角标出现或变化（不是被移除）时，该 Tab 的动画可以播放角标变化动画。
     */
    private func cylObserveItemTitles() {
        let items = self.items ?? []
        let storage = cylTabBarStorage
        if items == storage.titleObservedItems {
            return
        }
        storage.itemObservations.forEach { $0.invalidate() }
        storage.itemObservations.removeAll()
        for item in items {
            storage.itemObservations.append(item.observe(\.title, options: [.old, .new]) { [weak self] _, change in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let oldTitle = change.oldValue ?? nil
                    let newTitle = change.newValue ?? nil
                    if !self.cylTabBarStorage.isSettingItemTitles && oldTitle != newTitle && CYLConstants.isLiquidGlassActive() {
                        self.cylTabBarReloadTabButtons()
                    }
                }
            })
            storage.itemObservations.append(item.observe(\.badgeValue, options: [.old, .new]) { [weak self] item, change in
                MainActor.assumeIsolated {
                    guard let self, let newValue = change.newValue ?? nil, newValue != change.oldValue ?? nil else { return }
                    self.cylTabBarOwningTabBarController()?.cylTabBarItemBadgeValueDidChange(item)
                }
            })
        }
        storage.titleObservedItems = items
    }

    // MARK: - [EN] The iOS 27.1 vertical bar and the minimized bar [CN] iOS 27.1 竖向栏与缩小后的 TabBar

    /**
     * FIX: issue #653
     * [EN] Whether the system shows the tab buttons in the iOS 27.1 vertical bar (unfolded iPhone Duo in landscape,
     *      `allowsVerticalBar = YES`): the platter is no longer inside this tab bar.
     * [CN] 系统是否把 Tab 按钮放在 iOS 27.1 竖向栏中（iPhone Duo 展开横屏，`allowsVerticalBar = YES`）：platter 已不在本 TabBar 内。
     */
    @objc(cyl_showsVerticalBar)
    func cylTabBarShowsVerticalBar() -> Bool {
        guard let platterView = cylPlatterView(), let platterWindow = platterView.window else { return false }
        return platterWindow == window && !platterView.isDescendant(of: self)
    }

    /**
     * Issue #13
     * [EN] Whether the system shows this Liquid Glass tab bar minimized (`-[CYLTabBarController cyl_tabBarMinimizeBehavior]`
     *      is OnScrollDown or OnScrollUp, iOS 26+). UIKit has no public minimized state, so it is read from the geometry: on
     *      iPhone the platter (the glass capsule with the tab buttons) shrinks from almost the full width of the bar to a
     *      small capsule. Less than half the bar's width counts as minimized. NO in the vertical bar (issue #653).
     * [CN] 系统是否正以缩小状态显示本液态玻璃 TabBar（`-[CYLTabBarController cyl_tabBarMinimizeBehavior]` 为 OnScrollDown 或
     *      OnScrollUp，iOS 26+）。UIKit 没有公开的缩小状态，因此根据几何尺寸判断：iPhone 上 platter（承载 Tab 按钮的玻璃胶囊）
     *      会从接近 TabBar 全宽缩小为一个小胶囊，宽度不到 TabBar 一半即视为缩小。竖向栏中（issue #653）返回 NO。
     */
    @objc(cyl_showsMinimizedBar)
    func cylTabBarShowsMinimizedBar() -> Bool {
        guard CYLConstants.isLiquidGlassActive(), traitCollection.userInterfaceIdiom == .phone else { return false }
        let behavior = cylTabBarOwningTabBarController()?.cyl_tabBarMinimizeBehavior
        guard behavior == .onScrollDown || behavior == .onScrollUp else { return false }
        guard let platterView = cylPlatterView(), platterView.window != nil, platterView.isDescendant(of: self) else { return false }
        // [EN] In this bar's coordinates, so a scale transform counts too. [CN] 转换到本 TabBar 坐标系，缩放 transform 也会计入。
        let platterWidth = platterView.convert(platterView.bounds, to: self).width
        let tabBarWidth = bounds.width
        return platterWidth > 0 && tabBarWidth > 0 && platterWidth < tabBarWidth * 0.5
    }

    /// [EN] The tab button at `index`, or nil when `index` is out of range. [CN] 第 `index` 个 Tab 按钮；越界时返回 nil。
    private func cylTabButton(at index: Int) -> UIView? {
        let tabButtons = cylTabBarSubviews()
        return index >= 0 && index < tabButtons.count ? tabButtons[index] : nil
    }

    /**
     * [EN] The tab button the plus button covers on the horizontal Liquid Glass bar (its slot), laid out in the platter; nil
     *      before it is laid out.
     * [CN] 横向液态玻璃 TabBar 上 PlusButton 覆盖的 Tab 按钮（它的 slot），已在 platter 中布局；尚未布局时返回 nil。
     */
    private func cylLiquidGlassPlusButtonSlot(at index: Int) -> UIView? {
        let platterView = cylTabBarContentView()
        platterView.layoutIfNeeded()
        guard let slot = cylTabButton(at: index), slot.bounds.width > 0, slot.superview != nil, slot.isDescendant(of: platterView) else {
            return nil
        }
        return slot
    }

    /**
     * Issue #13
     * [EN] The tab button at `index` while this tab bar is minimized (`-cyl_showsMinimizedBar`); nil otherwise.
     * [CN] 本 TabBar 处于缩小状态（`-cyl_showsMinimizedBar`）时第 `index` 个 Tab 按钮；其他情况返回 nil。
     */
    private func cylMinimizedBarTabButton(at index: Int) -> UIView? {
        cylTabBarShowsMinimizedBar() ? cylTabButton(at: index) : nil
    }

    /**
     * FIX: issue #653
     * [EN] The tab button at `index` when the system shows the tab buttons in the iOS 27.1 vertical bar, i.e. when the
     *      platter is no longer inside this tab bar; nil otherwise.
     * [CN] iOS 27.1 竖向栏中（platter 已不在本 TabBar 内）第 `index` 个 Tab 按钮；其他情况返回 nil。
     */
    private func cylVerticalBarTabButton(at index: Int) -> UIView? {
        guard cylTabBarShowsVerticalBar(), let platterView = cylPlatterView(), let tabButton = cylTabButton(at: index) else { return nil }
        return tabButton.isDescendant(of: platterView) ? tabButton : nil
    }

    /**
     * FIX: issue #653
     * [EN] The tab button (normal layer) under `windowPoint` while the tab buttons are shown in the iOS 27.1 vertical bar; nil otherwise.
     * [CN] iOS 27.1 竖向栏中，位于 `windowPoint`（窗口坐标）下的 Tab 按钮（常态图层）；其他情况返回 nil。
     */
    @objc(cyl_verticalBarTabButtonAtWindowPoint:)
    func cylTabBarVerticalBarTabButton(atWindowPoint windowPoint: CGPoint) -> UIControl? {
        guard cylVerticalBarTabButton(at: 0) != nil else { return nil }
        for case let tabButton as UIControl in cylTabBarSubviews() {
            if tabButton.point(inside: tabButton.convert(windowPoint, from: nil), with: nil) {
                return tabButton
            }
        }
        return nil
    }

    // MARK: - [EN] Image-only tabs [CN] 纯图标 Tab

    /**
     * FIX: issue #598
     * [EN] Vertical center of the part of `tabBarButton` that holds its content, in this tab bar's coordinates (the same
     *      value as `tabBarButton.center.y` while the button stays above the bottom safe area).
     *      On iOS 16, during a push (iPhone 12), the tab button was laid out stretched over the bottom safe area: its frame
     *      height went from 49 to 83, so `center.y` moved from 24.5 to 41.5. `tabImageViewDefaultOffset` came out ~8.5 pt too
     *      large, the image was moved down onto the title, and since the value is computed only once it stayed wrong.
     *      Leave out the part of the button inside the bottom safe area. Classic style only (no Liquid Glass, no FlatDesign:
     *      FlatDesign does not use `tabImageViewDefaultOffset`); the superview check is a last line of defence for any
     *      other button layout.
     * [CN] `tabBarButton` 中承载内容那部分的垂直中心，使用本 TabBar 的坐标系（按钮位于底部安全区之上时，与
     *      `tabBarButton.center.y` 相同）。
     *      iOS 16（iPhone 12）push 过程中，Tab 按钮会被拉伸到底部安全区内：frame 高度由 49 变为 83，`center.y` 由 24.5 变为 41.5，
     *      计算出的 `tabImageViewDefaultOffset` 偏大约 8.5pt，图片被下移与文字重叠；该值只计算一次，因此会一直错误。
     *      这里排除按钮位于底部安全区内的部分。仅适用于经典样式（非液态玻璃、非扁平样式：扁平样式不使用 `tabImageViewDefaultOffset`）。
     */
    private func cylTabButtonContentCenterY(_ tabBarButton: UIView) -> CGFloat {
        if CYLConstants.isLiquidGlassActive() || cylTabBarOwningTabBarController()?.tabBarStyleType == .flatDesign ||
            tabBarButton.superview !== self {
            return tabBarButton.center.y
        }
        let frame = tabBarButton.frame
        let contentMaxY = bounds.height - safeAreaInsets.bottom
        if frame.maxY <= contentMaxY || contentMaxY <= frame.minY {
            return tabBarButton.center.y
        }
        return (frame.minY + contentMaxY) * 0.5
    }

    /**
     * FIX: issue #257, issue #522
     * [EN] Measures, once, how far the image of an image-only tab (a tab button without a title label) has to move to be
     *      vertically centered; `CYLTabBarController` observes the result and moves the images of its image-only tabs.
     *      - The guard was `> 0`: a negative offset (an image below the center) was measured again on every layout pass
     *        (any layout of the screen, e.g. after setting a label's text on a page), each time from the image that the
     *        previous offset had already moved, so the icons jumped and the items were written again and again.
     *        Any non-zero offset now ends the measurement.
     *      - Nothing is measured when `CYLTabBarController.automaticallyAdjustsImageOnlyTabs` is NO.
     * [CN] 只测量一次纯图标 Tab（没有标题 label 的 Tab 按钮）的图片需要移动多少才能垂直居中；`CYLTabBarController` 监听该结果，
     *      并移动其纯图标 Tab 的图片。
     *      - 以前的判断是 `> 0`：偏移为负（图片低于中心）时，每次布局（屏幕上任何布局，例如在页面上给 label 赋值后）都会重新测量，
     *        且每次都基于已被上次偏移移动过的图片，于是图标跳动，item 被反复写入。现在任何非零偏移都会结束测量。
     *      - `CYLTabBarController.automaticallyAdjustsImageOnlyTabs` 为 NO 时不做测量。
     */
    private func cylSetupTabImageViewDefaultOffset(_ tabBarButton: UIView) {
        guard cylTabBarStorage.tabImageViewDefaultOffset == 0 else { return }
        if let tabBarController = cylTabBarOwningTabBarController(), !tabBarController.automaticallyAdjustsImageOnlyTabs {
            return
        }
        var shouldCustomizeImageView = true
        var tabImageViewDefaultOffset: CGFloat = 0
        let tabButtonCenterY = cylTabButtonContentCenterY(tabBarButton)
        for subview in tabBarButton.subviews {
            if subview.cylIsTabLabel() {
                shouldCustomizeImageView = false
            }
            let isTabImageView = subview.cylIsTabImageView()
            if isTabImageView {
                tabImageViewDefaultOffset = (tabButtonCenterY - subview.center.y) * 0.5
            }
            if isTabImageView && tabImageViewDefaultOffset == 0 {
                shouldCustomizeImageView = false
            }
        }
        if shouldCustomizeImageView {
            cylSetTabImageViewDefaultOffset(tabImageViewDefaultOffset)
        }
    }

    // MARK: - [EN] Hit testing [CN] 点击判定

    /**
     * FIX: issue #653
     * [EN] `view.frame` converted from its superview's coordinate space to this tab bar's; `.null` if `view` is nil.
     * [CN] 将 `view.frame` 从其父视图坐标系转换到本 TabBar 坐标系；`view` 为 nil 时返回 `.null`。
     */
    private func cylConvertFrame(of view: UIView?) -> CGRect {
        guard let view else { return .null }
        guard let superview = view.superview, superview !== self else { return view.frame }
        return superview.convert(view.frame, to: self)
    }

    /**
     * [EN] Capturing touches on a subview outside the frame of its superview. `superHitTest` is UIKit's hit test.
     * [CN] 捕获子视图超出父视图范围部分的触摸。`superHitTest` 为 UIKit 的点击判定。
     */
    @objc(cyl_tabBarHitTest:withEvent:superHitTest:)
    func cylTabBarHitTest(_ point: CGPoint, with event: UIEvent?, superHitTest: (CGPoint) -> UIView?) -> UIView? {
        // [EN] Remember where a touch hit, for a gesture that later reports no location (see `cylTouchWindowLocation(of:)`).
        // [CN] 记录触摸命中的位置，供之后报告不出位置的手势使用（见 `cylTouchWindowLocation(of:)`）。
        if event?.type == .touches, window != nil {
            cylTabBarStorage.lastTouchHitWindowPoint = convert(point, to: nil)
            cylTabBarStorage.lastTouchHitTime = ProcessInfo.processInfo.systemUptime
        }
        // [CN] 1. 边界情况：不能响应点击事件
        // [EN] 1. Edge cases: cannot respond to tap events
        if cylCanNotResponseEvent() {
            return superHitTest(point)
        }
        // [CN] 2. 优先处理 PlusButton （包括其突出的部分）、TabBarItems 未凸出的部分。这一步主要是在处理只有两个 TabBarItems 的场景。
        //      2.1 先考虑clipsToBounds情况：子view超出部分没有显示出来
        // [EN] 2. First handle the PlusButton (including its protruding part) and the non-protruding part of TabBarItems.
        //      This step mainly handles the case where there are only two TabBarItems.
        //      2.1 First consider the clipsToBounds case: the parts of subviews outside the bounds are not shown
        if clipsToBounds && !self.point(inside: point, with: event) {
            return superHitTest(point)
        }
        // [EN] Guard: only with a plus button. [CN] 仅在有 PlusButton 时处理。
        if let plusButton = cylTabBarPlusButton() {
            // [EN] FIX: issue #202 — a subview of the plus button that takes touches (a control, or a view with a gesture
            //      recognizer) gets the touch first; it used to be swallowed by the plus button.
            // [CN] PlusButton 中自己接收触摸的子视图（控件，或带手势的视图）优先获得触摸；以前会被 PlusButton 拦截。
            if let plusButtonSubview = plusButton.hitTestInteractiveSubview(plusButton.convert(point, from: self), with: event) {
                return plusButtonSubview
            }
            // [EN] FIX: issue #91 — the touchable area (`touchableAreaOutsets`, `touchableAreaScale`, or an overridden
            //      `-touchableRect`) is in the plus button's superview coordinates. In Liquid Glass that superview is the platter,
            //      not this tab bar, so convert it first (as for the tab buttons, #653). A point outside this tab bar still
            //      reaches here, so an area above or below the bar takes the touch instead of the page behind.
            // [CN] 可点击区域位于 PlusButton 父视图坐标系；液态玻璃下父视图是 platter 而不是本 TabBar，需要先转换（与 #653 的 Tab 按钮相同）。
            //      本 TabBar 之外的点也会走到这里，因此 TabBar 上方或下方的扩展区域会接收点击，而不再穿透到后面的页面。
            if plusButton.touchableRect(in: self).contains(point) {
                return plusButton
            }
        }
        var tabBarButtons: [UIView] = cylTabBarStorage.tabBarButtonArray
        if tabBarButtons.isEmpty {
            tabBarButtons = cylVisibleControls() ?? []
        }
        for tabBarButton in tabBarButtons {
            let imageView = tabBarButton is UIControl ? tabBarButton.cyl_getActualBadgeSuperView() as? UIView : nil
            // FIX: issue #653 — in Liquid Glass the tab buttons live in the platter, not in this tab bar, so their `frame`
            // is in the platter's coordinate space while `point` is in this tab bar's. On the unfolded iPhone Duo the platter
            // is centered with a large horizontal offset, so a tap on the 2nd tab hit-tested as another tab and a repeat tap on
            // the selected tab never called `tabBarController:didSelectControl:`. Convert both frames to this tab bar first.
            // 液态玻璃下 Tab 按钮在 platter 内，frame 是 platter 坐标，point 是本 TabBar 坐标；iPhone Duo 展开时 platter 居中、偏移较大，
            // 点击第 2 个 Tab 被识别为其他 Tab，导致选中状态下再次点击不回调 didSelectControl。这里先把 frame 转换到本 TabBar 坐标系。
            let isTabBarButtonFrame = cylConvertFrame(of: tabBarButton).contains(point) || cylConvertFrame(of: imageView).contains(point)
            if isTabBarButtonFrame && !tabBarButton.cylCanNotResponseEvent() {
                return tabBarButton
            }
        }
        // [CN] CYLFlatDesignTabBar 已经封装在该类内部，不需要在这里处理
        // [EN] CYLFlatDesignTabBar is already handled inside that class, so there is no need to handle it here
        // [CN] 3. 最后处理 TabBarItems 凸出的部分、添加到 TabBar 上的自定义视图、点击到 TabBar 上的空白区域
        // [EN] 3. Finally handle the protruding parts of TabBarItems, custom views added to the TabBar, and taps on empty
        //      areas of the TabBar
        if let result = superHitTest(point) {
            return result
        }
        for subview in subviews.reversed() {
            if let result = subview.hitTest(subview.convert(point, from: self), with: event) {
                return result
            }
        }
        return superHitTest(point)
    }

    /// [EN] Called by `-addSubview:` before super: records the Liquid Glass views. [CN] 由 `-addSubview:` 在调用 super 之前调用：记录液态玻璃视图。
    @objc(cyl_tabBarWillAddSubview:)
    func cylTabBarWillAddSubview(_ view: UIView) {
        if view.cylIsPlatterView() {
            cylSetPlatterView(view)
            // [CN] 从 PlatterView 中，找真正承载 UITabBarButton 的 ContentView
            // [EN] Find, inside the PlatterView, the ContentView that actually holds the UITabBarButton
            if let contentView = view.subviews.first(where: { $0.cylIsPlatterContentView() }) {
                cylSetPlatterContentView(contentView)
            }
        }
        // [CN] 点击后的聚焦瞬间遮罩
        // [EN] Momentary focus overlay shown after a tap
        if view.cylIsPlatterPortalView() && cylPortalView() == nil {
            cylSetPortalView(view)
        }
    }

    // MARK: - [EN] Scroll edge element container (iOS 26+) [CN] 滚动边缘元素容器（iOS 26+）

    /**
     * FIX: issue #662 — a frosted band above the tab bar hides the last rows of a list on iOS 27
     * [EN] Apps add a `UIScrollEdgeElementContainerInteraction` to the tab bar so a scroll view's bottom edge effect sits
     *      under it. UIKit sizes that effect from the tab bar AND its subviews. The raised plus button is a subview that
     *      sticks out above the tab bar (y < 0), so the effect started above the glass capsule and blurred the last rows.
     *      The interaction is now moved to an empty view with exactly the tab bar's bounds, so the effect matches the
     *      tab bar, as it does for tabs without the interaction. Nothing to change in the app. The interaction is not in
     *      the tab bar's `interactions`; remove it with `-removeInteraction:` on the tab bar as usual.
     *      Called by `-addInteraction:`: YES when the interaction was added here (super is then not called).
     * [CN] App 会给 TabBar 添加 `UIScrollEdgeElementContainerInteraction`，让滚动视图底部的边缘效果位于 TabBar 下方。UIKit 按
     *      TabBar 及其子视图计算该效果的范围。凸起的加号按钮是伸出 TabBar 上方（y < 0）的子视图，于是边缘效果从玻璃胶囊上方开始，
     *      模糊了列表最后几行。现在该交互被转移到一个与 TabBar bounds 完全相同的空视图上，边缘效果与 TabBar 一致，与未添加该交互的
     *      Tab 相同。App 无需修改代码。该交互不会出现在 TabBar 的 `interactions` 中；照常在 TabBar 上调用 `-removeInteraction:` 移除即可。
     *      由 `-addInteraction:` 调用：交互已在这里添加时返回 YES（此时不再调用 super）。
     */
    @objc(cyl_tabBarAddScrollEdgeElementContainerInteraction:)
    func cylTabBarAddScrollEdgeElementContainerInteraction(_ interaction: UIInteraction) -> Bool {
        guard #available(iOS 26.0, *), interaction is UIScrollEdgeElementContainerInteraction else { return false }
        let storage = cylTabBarStorage
        let containerView: UIView
        if let existing = storage.scrollEdgeElementContainerView {
            containerView = existing
        } else {
            containerView = UIView(frame: bounds)
            containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.isUserInteractionEnabled = false
            containerView.backgroundColor = .clear
            storage.scrollEdgeElementContainerView = containerView
        }
        if containerView.superview !== self {
            insertSubview(containerView, at: 0)
        }
        containerView.addInteraction(interaction)
        return true
    }

    /// [EN] Called by `-removeInteraction:`: YES when the interaction was removed here. [CN] 由 `-removeInteraction:` 调用：交互已在这里移除时返回 YES。
    @objc(cyl_tabBarRemoveScrollEdgeElementContainerInteraction:)
    func cylTabBarRemoveScrollEdgeElementContainerInteraction(_ interaction: UIInteraction) -> Bool {
        guard let containerView = cylTabBarStorage.scrollEdgeElementContainerView, interaction.view === containerView else { return false }
        containerView.removeInteraction(interaction)
        return true
    }

    // MARK: - [EN] Liquid Glass gestures [CN] 液态玻璃手势

    /**
     * [CN] 识别ContinuousSelection手势，需要代理长按等其他，处理PlusButton事件响应优先级为最优。由 `-addGestureRecognizer:` 在调用 super 之前调用。
     * [EN] Recognize the ContinuousSelection gesture; needs a delegate for long press etc., so that PlusButton event
     *      handling gets the highest priority. Called by `-addGestureRecognizer:` before super.
     */
    @objc(cyl_tabBarWillAddGestureRecognizer:)
    func cylTabBarWillAddGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        guard CYLConstants.isLiquidGlassActive() else { return }
        // [EN] The tab bar is its own gesture delegate (declared in CYLTabBar.m). [CN] TabBar 是自己的手势代理（在 CYLTabBar.m 中声明）。
        let delegate = (self as AnyObject) as? UIGestureRecognizerDelegate
        if gestureRecognizer.cylIsContinuousGestureRecognizer() {
            liquidGlassContinuousGestureRecognizer = gestureRecognizer
            gestureRecognizer.delegate = delegate
            gestureRecognizer.addTarget(self, action: #selector(cylLiquidGlassGestureRecognizerDidUpdate(_:)))
        }
        if gestureRecognizer.cylIsLongGestureRecognizer() {
            liquidGlassLongGestureRecognizer = gestureRecognizer
            gestureRecognizer.delegate = delegate
            gestureRecognizer.addTarget(self, action: #selector(cylLiquidGlassGestureRecognizerDidUpdate(_:)))
        }
    }

    /**
     * FIX: issue #653 — plus button hidden while pressing or dragging in the iOS 27.1 vertical bar.
     * [EN] While a tab is pressed or dragged, UIKit shows a lifted copy of the tab platter in a portal view. With a
     *      horizontal tab bar that portal is added to this tab bar, below the plus button. In the vertical bar it is added
     *      to the tab bar controller's container view, above the branch that holds this tab bar, so it covered the plus
     *      button (only the plus cover in the selected layer stayed visible). Keep such portal views just below that branch.
     * [CN] 按住或拖拽 Tab 时，系统用 portal 视图显示抬起的 platter 副本。横向时该 portal 加在本 TabBar 上、位于加号按钮之下；
     *      竖向栏中它被加到 TabBarController 的容器视图上，位于本 TabBar 所在分支之上，遮住了加号按钮（只剩选中图层里的加号遮罩）。
     *      这里把这类 portal 视图移到该分支下方。
     */
    @objc(cyl_liquidGlassGestureRecognizerDidUpdate:)
    func cylLiquidGlassGestureRecognizerDidUpdate(_ gestureRecognizer: UIGestureRecognizer) {
        // [EN] FIX: issue #152 / #535 — in Liquid Glass these UIKit gestures receive every touch on the tab buttons, and a
        //      gesture added by the library does not: the long press, Reselect and DoubleTap are recognized from them.
        //      Every state is forwarded, before the checks below.
        // [CN] FIX: issue #152 / #535 — 液态玻璃下，Tab 按钮上的每次触摸都由这些系统手势接收，库自己添加的手势收不到：长按、Reselect
        //      与 DoubleTap 由它们识别。所有状态都转发，且在下方的判断之前。
        cylTabBarOwningTabBarController()?.cylLiquidGlassTabBarGestureRecognizerDidUpdate(gestureRecognizer)
        guard gestureRecognizer.state == .began, cylKeepPlusButtonAbovePortalViewsInVerticalBar() else { return }
        // The portal is added by the lift animation, slightly after the gesture begins, and a finger held still sends no
        // further updates: keep checking while the gesture is active. 抬起动画稍后才添加 portal，手指不动时没有后续回调，因此手势进行中持续检查。
        cylKeepPlusButtonAbovePortalViews(whileGestureIsActive: gestureRecognizer)
    }

    private func cylKeepPlusButtonAbovePortalViews(whileGestureIsActive gestureRecognizer: UIGestureRecognizer) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak gestureRecognizer] in
            guard let self, let gestureRecognizer else { return }
            self.cylKeepPlusButtonAbovePortalViewsInVerticalBar()
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                self.cylKeepPlusButtonAbovePortalViews(whileGestureIsActive: gestureRecognizer)
            }
        }
    }

    /// Returns false when there is nothing to do (no plus button, or the tab buttons are not in the vertical bar).
    @discardableResult
    private func cylKeepPlusButtonAbovePortalViewsInVerticalBar() -> Bool {
        guard cylTabBarPlusButton()?.superview != nil, cylVerticalBarTabButton(at: 0) != nil else { return false }
        let rootView = cylTabBarOwningTabBarController()?.viewIfLoaded
        var child: UIView = self
        var parent = superview
        while let currentParent = parent {
            for sibling in currentParent.subviews {
                guard let childIndex = currentParent.subviews.firstIndex(of: child),
                      let siblingIndex = currentParent.subviews.firstIndex(of: sibling) else { continue }
                if siblingIndex > childIndex && sibling.cylIsPlatterPortalView() {
                    currentParent.insertSubview(sibling, belowSubview: child)
                }
            }
            if currentParent === rootView || currentParent === window {
                break
            }
            child = currentParent
            parent = currentParent.superview
        }
        return true
    }

    /**
     * FIX: issue #653 — plus button does not respond in the iOS 27.1 vertical bar.
     * [EN] With a horizontal tab bar, UIKit's hit test reaches the plus button (via `-hitTest:withEvent:` above), so the
     *      touch goes to it and its `UIControlEventTouchUpInside` actions run. In the vertical bar this tab bar's container
     *      (`_UIBottomTabBarGroupView`) is 0 pt tall, so UIKit's hit test never reaches the plus button: the touch goes to
     *      the placeholder tab in the vertical bar and the plus button's actions (e.g. an app's own `-clickPublish`) never run.
     *      When that happens, send them here. Several gesture recognizers can ask during the same touch; the calls are
     *      coalesced to one per run loop turn.
     * [CN] 横向时系统 hitTest 能命中加号按钮（见上方 `-hitTest:withEvent:`），触摸交给加号按钮，触发其 TouchUpInside 事件。
     *      竖向栏中本 TabBar 所在容器 `_UIBottomTabBarGroupView` 高度为 0，系统 hitTest 命中不了加号按钮，触摸落到竖向栏的占位 Tab 上，
     *      加号按钮的点击事件（如 App 自己添加的 `-clickPublish`）不会执行，这里补发。同一次触摸可能有多个手势询问，同一 run loop 内只发送一次。
     */
    private func cylSendPlusButtonActionsIfUnreachable(for gestureRecognizer: UIGestureRecognizer) {
        guard let plusButton = cylRegisteredPlusButton, let window,
              plusButton.isEnabled, plusButton.isUserInteractionEnabled, !plusButton.isHidden else { return }
        if let systemHitView = window.hitTest(gestureRecognizer.location(in: window), with: nil), systemHitView.isDescendant(of: plusButton) {
            return // UIKit delivers the touch to the plus button itself. 系统会把触摸交给加号按钮，无需补发。
        }
        guard !cylIsPlusButtonActionsSendPending else { return }
        cylIsPlusButtonActionsSendPending = true
        DispatchQueue.main.async {
            cylIsPlusButtonActionsSendPending = false
            plusButton.sendActions(for: .touchUpInside)
        }
    }

    /**
     * [CN] 处理PlusButton事件响应优先级为最优。由 `-gestureRecognizerShouldBegin:` 调用。
     * [EN] Give PlusButton event handling the highest priority. Called by `-gestureRecognizerShouldBegin:`.
     */
    /**
     * [EN] Where `gestureRecognizer`'s touch is, in window coordinates. A touch that a host delivers late (Flutter's
     *      `UiKitView` forwards a simulator's one-event tap only after its gesture arena accepts it) reaches UIKit's Liquid Glass
     *      gestures with no touch left: they report {0, 0}. Then the point of the touch's own hit test, made when it began, is
     *      used, if it is at most a second old. Docs: docs/Flutter-Component.md (simulated taps).
     * [CN] `gestureRecognizer` 的触摸在窗口坐标系中的位置。宿主延迟交付的触摸（Flutter 的 `UiKitView` 要等手势竞技场接受后才转发模拟器的单事件点击）
     *      到达系统液态玻璃手势时已没有触摸，位置为 {0, 0}；此时使用该触摸开始时 hitTest 的位置（不超过 1 秒）。
     */
    @objc(cyl_touchWindowLocationOfGestureRecognizer:)
    func cylTouchWindowLocation(of gestureRecognizer: UIGestureRecognizer) -> CGPoint {
        let location = gestureRecognizer.location(in: nil)
        guard location == .zero, cylTouchLocationWasLost(gestureRecognizer) else { return location }
        return cylTabBarStorage.lastTouchHitWindowPoint ?? location
    }

    /**
     * [EN] YES when `gestureRecognizer` reports no touch location ({0, 0} with no touches) and a recent touch hit test can stand
     *      in for it. [CN] `gestureRecognizer` 报告不出触摸位置（{0, 0} 且无触摸）且有最近的触摸 hitTest 可替代时为 YES。
     */
    @objc(cyl_touchLocationWasLost:)
    func cylTouchLocationWasLost(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.numberOfTouches == 0, gestureRecognizer.location(in: nil) == .zero,
              cylTabBarStorage.lastTouchHitWindowPoint != nil else { return false }
        return ProcessInfo.processInfo.systemUptime - cylTabBarStorage.lastTouchHitTime <= 1
    }

    @objc(cyl_tabBarGestureRecognizerShouldBegin:)
    func cylTabBarGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard CYLConstants.isLiquidGlassActive() else { return true }
        var hitView = hitTest(convert(cylTouchWindowLocation(of: gestureRecognizer), from: nil), with: nil)
        if hitView == nil {
            // FIX: issue #653 — in the iOS 27.1 vertical bar the tab buttons are outside this tab bar, so the hit test
            // above finds nothing and a tap on the already selected tab never reached `-tabChangedToControl:`
            // (no `tabBarController:didSelectControl:` callback). Look the tab button up under the touch instead.
            // 竖向栏中 Tab 按钮不在本 TabBar 内，上面的 hitTest 为 nil，导致选中状态下再次点击不回调 didSelectControl，这里按触摸点查找 Tab 按钮。
            hitView = cylTabBarVerticalBarTabButton(atWindowPoint: cylTouchWindowLocation(of: gestureRecognizer))
        }
        // [EN] FIX: issue #202 — on Liquid Glass a subview of the plus button that takes touches (e.g. an X button) got
        //      none: the hit test above returns it, but UIKit's selection gesture still began, selected the stand-in tab
        //      under the plus button and cancelled the subview's touch. Such a subview keeps the touch for itself.
        // [CN] 液态玻璃下，PlusButton 中自己接收触摸的子视图（例如 X 按钮）收不到触摸：上面的 hitTest 已返回它，但 UIKit 的选中手势仍会开始，
        //      选中 PlusButton 下方的替身 Tab 并取消该子视图的触摸。这样的子视图自己保留这次触摸。
        if let plusButtonView = cylTabBarPlusButton(), let hitView, hitView !== plusButtonView, hitView.isDescendant(of: plusButtonView) {
            return false
        }
        let tabBarController = cylTabBarOwningTabBarController()
        if let control = hitView as? UIControl, let tabBarController, control.cylIsTabButton() || control is CYLPlusButton {
            // [EN] A plus button with a child view controller counts as selected while its page is: on Liquid Glass its
            //      `selected` flag is not set when it reports a tap (that left its stand-in with the old image after a theme
            //      change), and a second tap on it must still be reported.
            // [CN] 有子控制器的 PlusButton 在其页面被选中时视为已选中：液态玻璃下上报点击时不再设置它的 `selected`（否则换肤后替身会保留旧图片），
            //      而再次点击仍需上报。
            var isSelected = control.isSelected
            let plusChildViewController = control is CYLPlusButton ? CYLPlusButton.plusChildViewController(forOwner: self) : nil
            if !isSelected, let plusChildViewController, let selectedViewController = tabBarController.selectedViewController {
                isSelected = selectedViewController.cylIsEqual(to: plusChildViewController)
            }
            if isSelected {
                // [CN] FIX: iOS26 无法追加点击事件， 导致无法在选中状态下， 二次点击回调, 被系统手势拦截需要禁用特定手势，因为手势优先级高于 ControlEvents;
                // [EN] FIX: On iOS26 tap events cannot be added, so there is no callback for a second tap in the selected state;
                //      the system gesture intercepts it, so specific gestures must be disabled, because gestures take priority
                //      over ControlEvents;
                tabBarController.tabChanged(to: control)
            }
        }
        if hitView is CYLPlusButton && CYLPlusButton.plusChildViewController(forOwner: self) == nil {
            // [CN] 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
            //      可在PlusButton初始化时设置 reportsTapsToDelegate = NO 来禁止该协议方法触发plusButton回调
            // [EN] Even if the PlusButton has its own tap event, tapping the PlusButton still triggers this delegate method.
            //      Set reportsTapsToDelegate = NO when creating the PlusButton to stop this protocol method from firing the
            //      plusButton callback
            if let plusButton = cylRegisteredPlusButton, cylControlReportsTapsEntryPoint(plusButton), let tabBarController {
                tabBarController.tabChanged(to: plusButton)
            }
            cylSendPlusButtonActionsIfUnreachable(for: gestureRecognizer)
            return false
        }
        return true
    }

    // MARK: - CYLTabBar (CYLTabBarItemAnimation)

    // [EN] Declared in UIControl+CYLTabBarItemAnimation.h (a private header); was UIControl+CYLTabBarItemAnimation.m.
    // [CN] 在 UIControl+CYLTabBarItemAnimation.h（私有头文件）中声明；原为 UIControl+CYLTabBarItemAnimation.m。

    @objc(cyl_playTabBarItemAnimationWithSelectedControl:URL:size:defaultSelected:contentMode:)
    public func cylPlayTabBarItemAnimation(withSelectedControl selectedControl: UIControl?, url: URL?, size: CGSize,
                                    defaultSelected: Bool, contentMode: UIView.ContentMode) {
        guard let url else { return }
        // [CN] 统一使用CYLTabBarItemAnimationPlayingNotification进行动画重置， 故删除手动重置。
        // [EN] Animation reset is handled uniformly via CYLTabBarItemAnimationPlayingNotification, so the manual reset
        //      was removed.
        selectedControl?.cylPlayTabBarItemAnimation(with: url, size: size, defaultSelected: defaultSelected, contentMode: contentMode)
    }

    @objc(cyl_stopAllTabBarItemAnimations)
    public func cylStopAllTabBarItemAnimations() {
        cylEnumerateAnimatedControls { $0.cylStopTabBarItemAnimation() }
    }

    @objc(cyl_restartAllTabBarItemAnimations)
    public func cylRestartAllTabBarItemAnimations() {
        cylEnumerateAnimatedControls { $0.cylRestartTabBarItemAnimation() }
    }

    @objc(cyl_setAllTabBarItemAnimationsSpeed:loops:)
    public func cylSetAllTabBarItemAnimations(speed: CGFloat, loops: Bool) {
        cylEnumerateAnimatedControls { control in
            control.cylSetTabBarItemAnimationSpeed(speed)
            control.cylSetTabBarItemAnimationLoops(loops)
        }
    }

    /// [EN] The tab buttons, then the selected-state layers (Liquid Glass). [CN] Tab 按钮，然后是选中态图层（液态玻璃）。
    private func cylEnumerateAnimatedControls(_ block: (UIControl) -> Void) {
        for control in cylVisibleControls() ?? [] {
            block(control)
        }
        for control in cylPlatterSelectedContentViews() ?? [] {
            block(control)
        }
    }
}

// MARK: - UITabBar (CYLBarBackground)

/**
 * [EN] `UITabBar (CYLBarBackground)`: the views UIKit draws a tab bar's background with, and its blur. Declared in
 *      CYLTabBar.h; translated from Objective-C (step 51).
 * [CN] `UITabBar (CYLBarBackground)`：UIKit 绘制 TabBar 背景所用的视图及其模糊效果。在 CYLTabBar.h 中声明；已从 Objective-C 翻译（第 51 步）。
 */
extension UITabBar {

    func cylBackgroundView() -> UIView? {
        cylValue(forKey: "_backgroundView") as? UIView
    }

    func cylShadowImageView() -> UIImageView? {
        cylTabShadowImageView()
    }

    func cylEffectViews() -> [UIVisualEffectView]? {
        // [EN] Exactly UIVisualEffectView: the shadow is drawn by a subclass. [CN] 必须恰好是 UIVisualEffectView：阴影由其子类绘制。
        let effectViews = (cylBackgroundView()?.subviews ?? []).compactMap { subview -> UIVisualEffectView? in
            type(of: subview) == UIVisualEffectView.self ? subview as? UIVisualEffectView : nil
        }
        return effectViews.isEmpty ? nil : effectViews
    }

    func cylEffectView() -> UIVisualEffectView? {
        cylEffectViews()?.last { !$0.isHidden && $0.alpha > 0.01 }
    }

    /// [EN] Writes into `standardAppearance` and `scrollEdgeAppearance` (when there is one). [CN] 写入 `standardAppearance` 与 `scrollEdgeAppearance`（存在时）。
    private func cylUpdateAppearances(_ block: (UITabBarAppearance) -> Void) {
        let standardAppearance = standardAppearance.copy()
        block(standardAppearance)
        self.standardAppearance = standardAppearance
        if let scrollEdgeAppearance = scrollEdgeAppearance?.copy() {
            block(scrollEdgeAppearance)
            self.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }

    func cylBackgroundEffect() -> UIBlurEffect? {
        standardAppearance.backgroundEffect
    }

    func cylSetBackgroundEffect(_ backgroundEffect: UIBlurEffect?) {
        cylUpdateAppearances { $0.backgroundEffect = backgroundEffect }
    }

    func cylEffectForegroundColor() -> UIColor? {
        standardAppearance.backgroundColor
    }

    func cylSetEffectForegroundColor(_ effectForegroundColor: UIColor?) {
        cylUpdateAppearances { $0.backgroundColor = effectForegroundColor }
    }
}

// MARK: - The public API of `UITabBar (CYLBarBackground)`

/**
 [EN] `UITabBar (CYLBarBackground)` as callers saw it in CYLTabBar.h: the same selectors and Swift names, forwarding to the
      implementation above. Public Swift since docs/Swift-Migration.md step 121.
 [CN] 调用方在 CYLTabBar.h 中看到的 `UITabBar (CYLBarBackground)`：selector 与 Swift 名称不变，转发到上面的实现。自第 121 步起为公开的 Swift。
 */
extension UITabBar {
    /** [EN] The bar's background view. [CN] TabBar 的背景视图。 */
    @objc open var cyl_backgroundView: UIView? { cylBackgroundView() }
    /** [EN] The shadow line's image view. [CN] 阴影线的图片视图。 */
    @objc open var cyl_shadowImageView: UIImageView? { cylShadowImageView() }
    /** [EN] The blur views of the background. [CN] 背景中的模糊视图。 */
    @objc open var cyl_effectViews: [UIVisualEffectView]? { cylEffectViews() }
    /** [EN] The first blur view of the background. [CN] 背景中的第一个模糊视图。 */
    @objc open var cyl_effectView: UIVisualEffectView? { cylEffectView() }
    /** [EN] The background blur. [CN] 背景模糊效果。 */
    @objc open var cyl_backgroundEffect: UIBlurEffect? {
        @objc(cyl_backgroundEffect) get { cylBackgroundEffect() }
        @objc(cyl_setBackgroundEffect:) set { cylSetBackgroundEffect(newValue) }
    }
    /** [EN] The foreground color over the blur. [CN] 模糊效果上的前景色。 */
    @objc open var cyl_effectForegroundColor: UIColor? {
        @objc(cyl_effectForegroundColor) get { cylEffectForegroundColor() }
        @objc(cyl_setEffectForegroundColor:) set { cylSetEffectForegroundColor(newValue) }
    }
}
