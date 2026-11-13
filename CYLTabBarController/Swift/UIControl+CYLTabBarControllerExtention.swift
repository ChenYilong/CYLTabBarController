//
//  UIControl+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] `UIControl (CYLTabBarControllerExtention)` and `(CYLTabBarControllerExtentionDeprecated)`: what a tab button or plus
 *      button knows about its tab (indexes, identifier, selection), the views shown in place of or over its icon, the Liquid
 *      Glass platter twins, and the deprecated red-dot badge. Translated from Objective-C (docs/Swift-Migration.md, step 26);
 *      every declared selector is kept. The `completion` blocks are now optional, and receive the view passed in (never nil)
 *      with `isReplaced` NO when nothing was replaced.
 * [CN] `UIControl (CYLTabBarControllerExtention)` 与 `(CYLTabBarControllerExtentionDeprecated)`：Tab 按钮或 PlusButton 对其 Tab 的
 *      了解（下标、标识、选中状态）、替换或覆盖其图标的视图、液态玻璃 platter 中的对应控件，以及已废弃的红点角标。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 26 步），保留所有已声明的 selector。`completion` 回调改为可选，未替换时 `isReplaced` 为 NO，
 *      并传回传入的视图（不再为 nil）。
 */
enum CYLControlTabBarKeys {
    static let tabBarItemVisibleIndex = CYLUtilsKeys.key("cyl_tabBarItemVisibleIndex")
    static let tabBarChildViewControllerIndex = CYLUtilsKeys.key("cyl_tabBarChildViewControllerIndex")
    static let tabBarItemIdentifier = CYLUtilsKeys.key("cyl_tabBarItemIdentifier")
    static let tabBadgePointView = CYLUtilsKeys.key("cyl_tabBadgePointView")
    static let tabBadgePointViewOffset = CYLUtilsKeys.key("cyl_tabBadgePointViewOffset")
    /**
     * [EN] The value the deprecated `cyl_shouldNotSelect` stores: apps that still set it keep their behavior.
     * [CN] 废弃的 `cyl_shouldNotSelect` 存储的值：仍在设置它的 App 行为不变。
     */
    static let selectionLocked = CYLUtilsKeys.key("cyl_shouldNotSelect")
}

/**
 * [EN] The completion of the replace and cover methods: whether `newView` is shown, the tab button, the view.
 * [CN] 替换与覆盖方法的回调：`newView` 是否已显示、Tab 按钮、视图。
 */
public typealias CYLTabButtonReplaceCompletion = (_ isReplaced: Bool, _ tabBarButton: UIControl, _ newView: UIView) -> Void

/**
 * FIX: issue #653 (iPhone Duo, vertical bar)
 * [EN] Keeps views that CYL adds to a tab button (animation icon, selected cover, badge point) at a point derived from the
 *      button's own subviews, using frames instead of Auto Layout. Any constraint inside a tab button pulls the whole tab bar
 *      platter into Auto Layout; on iOS 27.1, when the system moves the tab bar to the vertical bar (folded iPhone Duo with
 *      `allowsVerticalBar = YES`), the SwiftUI toolbar hosting the platter then sizes it to the whole free area. The tracker
 *      fills the tab button, so its `layoutSubviews` runs whenever the button is resized and re-centres the views.
 * [CN] 让 CYL 添加到 Tab 按钮上的视图（动画图标、选中遮罩、红点）用 frame 跟随按钮内的参照视图，不再使用 Auto Layout。Tab 按钮内只要有
 *      约束，整个 TabBar 的 platter 都会进入 Auto Layout；iOS 27.1 系统把 TabBar 放到竖向栏时（iPhone Duo 折叠且
 *      `allowsVerticalBar = YES`），承载 platter 的 SwiftUI 工具栏会把它撑满整个可用区域。tracker 铺满 Tab 按钮，按钮尺寸变化时触发
 *      `layoutSubviews`，重新定位这些视图。
 */
final class CYLTabButtonLayoutTracker: UIView {

    typealias CenterProvider = (UIControl) -> CGPoint

    private final class CenterProviderBox {
        let provider: CenterProvider
        init(_ provider: @escaping CenterProvider) { self.provider = provider }
    }

    private let centerProviders = NSMapTable<UIView, CenterProviderBox>.weakToStrongObjects()

    static func tracker(for tabButton: UIControl) -> CYLTabButtonLayoutTracker {
        if let tracker = tabButton.subviews.lazy.compactMap({ $0 as? CYLTabButtonLayoutTracker }).first {
            return tracker
        }
        let tracker = CYLTabButtonLayoutTracker(frame: tabButton.bounds)
        tracker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tracker.isUserInteractionEnabled = false
        tracker.backgroundColor = .clear
        tabButton.insertSubview(tracker, at: 0)
        tracker.cyl_markAsInserted(forTabControl: tabButton)
        return tracker
    }

    /**
     * [EN] Moves `view`'s placement to `newView` (e.g. an animation view swapped for its Dark Mode version, #442).
     * [CN] 把 `view` 的定位改为跟随 `newView`（例如动画视图替换为深色版本，#442）。
     */
    func replaceTrackedView(_ view: UIView, with newView: UIView) {
        guard let box = centerProviders.object(forKey: view) else { return }
        centerProviders.removeObject(forKey: view)
        track(newView, centerProvider: box.provider)
    }

    func track(_ view: UIView, centerProvider: @escaping CenterProvider) {
        centerProviders.setObject(CenterProviderBox(centerProvider), forKey: view)
        updateTrackedView(view)
    }

    private func updateTrackedView(_ view: UIView) {
        guard let tabButton = superview as? UIControl, view.superview === tabButton,
              let box = centerProviders.object(forKey: view) else { return }
        let center = box.provider(tabButton)
        if center.x.isNaN || center.y.isNaN || view.center == center { return }
        view.center = center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerProviders.keyEnumerator().allObjects.compactMap { $0 as? UIView }.forEach(updateTrackedView)
    }

    /**
     * [EN] `point` of `view` in `tabButton`'s coordinates; the button's centre when `view` is not in a window tree.
     * [CN] `view` 中的 `point` 转换到 `tabButton` 坐标系；`view` 不在视图树中时为按钮中心。
     */
    static func point(_ point: CGPoint, of view: UIView?, in tabButton: UIControl) -> CGPoint {
        guard let view, view.superview != nil else {
            return CGPoint(x: tabButton.bounds.midX, y: tabButton.bounds.midY)
        }
        return view.convert(point, to: tabButton)
    }

    /**
     * FIX: issue #653 / #662
     * [EN] Places `newView` (fixed size) by frame: centre X on `imageView`, centre Y on `replacedView`, plus `offset`. Calling
     *      it again for a tracked view replaces its offset (e.g. the FlatDesign plus button's offset follows the tab bar
     *      height, which changes when the iPhone Duo folds) and re-centres it at once.
     * [CN] 用 frame 定位 `newView`（固定尺寸）：X 中心对齐 `imageView`，Y 中心对齐 `replacedView`，再加 `offset`。对已跟踪的视图再次调用会
     *      替换其偏移量（如扁平样式加号按钮的偏移随 TabBar 高度变化，iPhone Duo 折叠时会变）并立即重新定位。
     */
    static func track(_ newView: UIView, size: CGSize, in tabButton: UIControl, imageView: UIView?, replacedView: UIView?,
                      offset: UIOffset) {
        newView.translatesAutoresizingMaskIntoConstraints = true
        if size.width > 0 && size.height > 0 {
            newView.bounds = CGRect(origin: .zero, size: size)
        }
        tracker(for: tabButton).track(newView) { [weak imageView, weak replacedView] tabButton in
            let replaced = replacedView ?? imageView
            let centerX = point(CGPoint(x: imageView?.bounds.midX ?? 0, y: imageView?.bounds.midY ?? 0), of: imageView, in: tabButton)
            let centerY = point(CGPoint(x: replaced?.bounds.midX ?? 0, y: replaced?.bounds.midY ?? 0), of: replaced, in: tabButton)
            return CGPoint(x: centerX.x + offset.horizontal, y: centerY.y + offset.vertical)
        }
    }
}

// MARK: - Selection lock and tap reports (declared in CYLTabBarController+CYLPrivate.h)

/**
 * [EN] The library's lock on the selected tab button (the value the deprecated `cyl_shouldNotSelect` stores).
 * [CN] 库对已选中 Tab 按钮的锁定（废弃的 `cyl_shouldNotSelect` 存储的值）。
 */
@_cdecl("CYLControlIsSelectionLocked")
func cylControlIsSelectionLockedEntryPoint(_ control: UIControl?) -> Bool {
    guard let control else { return false }
    return (objc_getAssociatedObject(control, CYLControlTabBarKeys.selectionLocked) as? NSNumber)?.boolValue ?? false
}

@_cdecl("CYLControlSetSelectionLocked")
func cylControlSetSelectionLockedEntryPoint(_ control: UIControl?, _ locked: Bool) {
    guard let control else { return }
    objc_setAssociatedObject(control, CYLControlTabBarKeys.selectionLocked, NSNumber(value: locked), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

/**
 * [EN] Whether a tap on `control` is reported through `tabBarController:didSelectControl:`: `reportsTapsToDelegate` for a
 *      plus button, "not locked" for any other control.
 * [CN] 点击 `control` 是否通过 `tabBarController:didSelectControl:` 上报：PlusButton 为 `reportsTapsToDelegate`，其他控件为“未锁定”。
 */
@_cdecl("CYLControlReportsTaps")
func cylControlReportsTapsEntryPoint(_ control: UIControl?) -> Bool {
    guard let control else { return false }
    if let plusButton = control as? CYLPlusButton {
        return plusButton.reportsTapsToDelegate
    }
    return !cylControlIsSelectionLockedEntryPoint(control)
}

// MARK: - UIControl (CYLTabBarControllerExtention)

extension UIControl {

    // MARK: What the control knows about its tab

    /**
     * [EN] YES if the control is the plus button that has a child view controller added to the tab bar.
     * [CN] 判断当前控件是否为已添加子控制器的 PlusButton。
     */
    @objc(cyl_isChildViewControllerPlusButton)
    public func cyl_isChildViewControllerPlusButton() -> Bool {
        guard CYLPlusButton.plusChildViewController(forOwner: self)?.cyl_plusViewControllerEverAdded == true else {
            return false
        }
        if cyl_isPlusButton() {
            return true
        }
        return CYLPlusButton(forOwner: self)?.cyl_tabBarItemVisibleIndex == cyl_tabBarItemVisibleIndex
    }

    /**
     * [EN] YES if the control is selected and its tab is the tab bar controller's selected index.
     * [CN] 判断当前控件是否处于选中状态，且对应的 Tab 为 TabBarController 当前选中的索引。
     */
    @objc(cyl_isSelected)
    public func cyl_isSelected() -> Bool {
        guard let tabBarController = cyl_tabBarController else {
            return false
        }
        var isSelected = self.isSelected && tabBarController.selectedIndex == cyl_tabBarChildViewControllerIndex
        if tabBarController.tabBar.isKind(of: CYLTabBar.self), tabBarController.tabBar.cyl_hasPlusChildViewController() {
            isSelected = isSelected && CYLPlusButton.plusChildViewController(forOwner: self)?.cyl_plusViewControllerEverAdded == true
        }
        return isSelected
    }

    /**
     * [EN] YES if the control is the plus button (the registered plus button class, or the plus child view controller's button).
     * [CN] 判断当前控件是否为 PlusButton（已注册的 PlusButton 类，或 PlusButton 子控制器对应的按钮）。
     */
    @objc(cyl_isPlusControl)
    public func cyl_isPlusControl() -> Bool {
        CYLPlusButton.isPlusButtonView(self) || cyl_isChildViewControllerPlusButton()
    }

    /**
     * [EN] The index of the tab's child view controller; `NSNotFound` for a control that is no tab button or plus button.
     * [CN] Tab 对应子控制器的下标；不是 Tab 按钮或 PlusButton 时为 `NSNotFound`。
     */
    @objc(cyl_tabBarChildViewControllerIndex)
    public var cyl_tabBarChildViewControllerIndex: Int {
        @objc(cyl_tabBarChildViewControllerIndex) get {
            cyl_isTabButtonOrPlusButton ? integer(for: CYLControlTabBarKeys.tabBarChildViewControllerIndex) : NSNotFound
        }
        @objc(cyl_setTabBarChildViewControllerIndex:) set {
            setInteger(newValue, for: CYLControlTabBarKeys.tabBarChildViewControllerIndex)
        }
    }

    /**
     * [EN] The visible index: the plus button has its own, like a tab button.
     * [CN] 可见下标：PlusButton 与 Tab 按钮一样有自己的可见下标。
     */
    @objc(cyl_tabBarItemVisibleIndex)
    public var cyl_tabBarItemVisibleIndex: Int {
        @objc(cyl_tabBarItemVisibleIndex) get {
            cyl_isTabButtonOrPlusButton ? integer(for: CYLControlTabBarKeys.tabBarItemVisibleIndex) : NSNotFound
        }
        @objc(cyl_setTabBarItemVisibleIndex:) set {
            setInteger(newValue, for: CYLControlTabBarKeys.tabBarItemVisibleIndex)
        }
    }

    /**
     * FIX: issue #408
     * [EN] The identifier of this tab button or plus button, nil when it has none, for `-tabBarController:didSelectControl:`.
     *      In order: a value set here; for a plus button, `+[CYLPlusButtonSubclassing tabBarItemIdentifier]`, else its class
     *      name; the identifier of the tab it selects (`CYLTabBarItemIdentifier`, else the default).
     * [CN] 该 Tab 按钮或 PlusButton 的标识，没有时为 nil，供 `-tabBarController:didSelectControl:` 使用。依次取：这里设置的值；PlusButton
     *      的 `+[CYLPlusButtonSubclassing tabBarItemIdentifier]`，未实现时为其类名；所选 Tab 的标识（`CYLTabBarItemIdentifier`，未设置时为默认值）。
     */
    @objc(cyl_tabBarItemIdentifier)
    public var cyl_tabBarItemIdentifier: String? {
        @objc(cyl_tabBarItemIdentifier) get {
            if let identifier = objc_getAssociatedObject(self, CYLControlTabBarKeys.tabBarItemIdentifier) as? String {
                return identifier
            }
            // [EN] A plus button: its class's identifier, the same for every tab bar controller's copy.
            // [CN] PlusButton：其类的标识，多个 TabBarController 的副本共用。
            if cyl_isPlusButton() {
                return cyl_plusButtonClassIdentifier
            }
            // [EN] A FlatDesign tab button knows its tab through its item (no child view controller index, and no
            //      `cyl_isTabButton` under Liquid Glass). Found by name, so Core does not depend on FlatDesign.
            // [CN] 扁平样式的 Tab 按钮通过其 item 找到 Tab（没有子控制器下标，液态玻璃下也不算 `cyl_isTabButton`）。按类名查找，Core 不依赖扁平样式。
            if let flatButtonClass = CYLControlTabBarSupport.flatDesignTabBarButtonClass, isKind(of: flatButtonClass) {
                return (value(forKeyPath: "tabBarItem.childViewController") as? UIViewController)?.cyl_tabBarItemIdentifier
            }
            let index = cyl_tabBarChildViewControllerIndex
            guard let viewControllers = cyl_tabBarController?.viewControllers,
                  index >= 0, index != NSNotFound, index < viewControllers.count else {
                return nil
            }
            return viewControllers[index].cyl_tabBarItemIdentifier
        }
        @objc(cyl_setTabBarItemIdentifier:) set {
            objc_setAssociatedObject(self, CYLControlTabBarKeys.tabBarItemIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /**
     * [EN] A name to show for this tab button or plus button (an alert, a log): its accessibility label, else
     *      `cyl_tabBarItemIdentifier`, else its class name. An identifier can be a generated class name, so the title comes first.
     * [CN] 用于显示该 Tab 按钮或 PlusButton 的名称（弹框、日志）：依次取其 accessibility label、`cyl_tabBarItemIdentifier`、类名。标识可能是
     *      自动生成的类名，因此优先使用标题。
     */
    @objc(cyl_tabBarItemDisplayName)
    public var cyl_tabBarItemDisplayName: String {
        if let label = accessibilityLabel, !label.isEmpty {
            return label
        }
        return cyl_tabBarItemIdentifier ?? NSStringFromClass(type(of: self))
    }

    /**
     * [EN] Deprecated: it was both the app's switch for the plus button's delegate reports and the library's lock on the
     *      selected tab button. Use `CYLPlusButton.reportsTapsToDelegate`. While that is not set, YES here still keeps the
     *      plus button's taps out of the delegate.
     * [CN] 已废弃：它同时是 App 控制 PlusButton 代理回调的开关和库对已选中 Tab 按钮的锁定。请使用 `CYLPlusButton.reportsTapsToDelegate`。
     *      未设置它时，这里设为 YES 仍会阻止 PlusButton 的点击回调代理。
     */
    @available(*, deprecated, message: "Use CYLPlusButton.reportsTapsToDelegate")
    @objc(cyl_shouldNotSelect)
    public var cyl_shouldNotSelect: Bool {
        @objc(cyl_shouldNotSelect) get { cylControlIsSelectionLockedEntryPoint(self) }
        @objc(cyl_setShouldNotSelect:) set { cylControlSetSelectionLockedEntryPoint(self, newValue) }
    }

    /**
     * [EN] Deprecated, same as `cyl_shouldNotSelect`. Use `CYLPlusButton.reportsTapsToDelegate`.
     * [CN] 已废弃，同 `cyl_shouldNotSelect`。请使用 `CYLPlusButton.reportsTapsToDelegate`。
     */
    @available(*, deprecated, message: "Use CYLPlusButton.reportsTapsToDelegate")
    @objc(cyl_userInteractionDisabled)
    public var cyl_userInteractionDisabled: Bool {
        @objc(cyl_userInteractionDisabled) get { cylControlIsSelectionLockedEntryPoint(self) }
        @objc(cyl_setUserInteractionDisabled:) set { cylControlSetSelectionLockedEntryPoint(self, newValue) }
    }

    // MARK: Replacing and covering the tab's icon

    /**
     * [EN] Replaces the tab image view with `newView`.
     * [CN] 用 newView 替换 Tab 按钮的图片视图。
     */
    @objc(cyl_replaceTabImageViewWithNewView:show:)
    public func cyl_replaceTabImageView(withNewView newView: UIView, show: Bool) {
        cyl_replaceTabImageView(withNewView: newView, offset: .zero, show: show, completion: nil)
    }

    /**
     * [EN] Replaces the tab image view with `newView` at `offset`, calling `completion` with the result.
     * [CN] 用 newView 替换 Tab 按钮的图片视图并应用 offset 偏移，完成后通过 completion 回调结果。
     */
    @objc(cyl_replaceTabImageViewWithNewView:offset:show:completion:)
    public func cyl_replaceTabImageView(withNewView newView: UIView, offset: UIOffset, show: Bool,
                                        completion: CYLTabButtonReplaceCompletion?) {
        cyl_replace(isTabButton: false, newView: newView, offset: offset, show: show, autoHidesNewView: true,
                    hidesOriginalView: true, completion: completion)
    }

    /**
     * [EN] Replaces the whole tab button with `newView` and hides the original image view.
     * [CN] 用 newView 替换整个 Tab 按钮，并隐藏原图片视图。
     */
    @objc(cyl_replaceTabButtonWithNewView:show:)
    public func cyl_replaceTabButton(withNewView newView: UIView, show: Bool) {
        cyl_replaceTabButton(withNewView: newView, offset: .zero, show: show) { isReplaced, tabBarButton, _ in
            if isReplaced {
                tabBarButton.cyl_swappableImageViewViewInTabBarButton()?.isHidden = true
            }
        }
    }

    /**
     * [EN] Replaces the whole tab button with `newView` at `offset`, calling `completion` with the result.
     * [CN] 用 newView 替换整个 Tab 按钮并应用 offset 偏移，完成后通过 completion 回调结果。
     */
    @objc(cyl_replaceTabButtonWithNewView:offset:show:completion:)
    public func cyl_replaceTabButton(withNewView newView: UIView, offset: UIOffset, show: Bool,
                                     completion: CYLTabButtonReplaceCompletion?) {
        cyl_replace(isTabButton: true, newView: newView, offset: offset, show: show, autoHidesNewView: true,
                    hidesOriginalView: true, completion: completion)
    }

    /**
     * [EN] Covers the tab image view (or the whole button) with `newView` without hiding the original; waits `delay` seconds
     *      if the button is not ready yet (e.g. an animation still loading).
     * [CN] 用 newView 覆盖 Tab 图片视图（或整个按钮），不隐藏原视图；按钮未就绪（如动画未加载完成）时延迟 delay 秒执行。
     */
    @objc(cyl_coverTabImageViewOrTabButton:newView:offset:show:delayIfNeededForSeconds:completion:)
    public func cyl_coverTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool,
                                                 delayIfNeededForSeconds delay: CGFloat,
                                                 completion: CYLTabButtonReplaceCompletion?) {
        // [EN] An animation icon that is not ready yet is waited for; otherwise the cover lands before it is laid out.
        // [CN] 动画图标未就绪时需要等待，否则会在其布局完成前覆盖，位置错误。
        let delaySeconds = (self as UIView).cyl_isReady() ? 0 : max(TimeInterval(delay), 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
            self.cyl_replace(isTabButton: isTabButton, newView: newView, offset: offset, show: show, autoHidesNewView: false,
                             hidesOriginalView: false) { isReplaced, tabBarButton, newView in
                if isReplaced {
                    tabBarButton.cyl_showCover(newView, show: show)
                }
                (tabBarButton as UIView).cyl_perform(NSSelectorFromString(show ? "cyl_clearBadge" : "cyl_resumeBadge"))
                completion?(isReplaced, tabBarButton, newView)
            }
        }
    }

    /**
     * [EN] Same as `-cyl_coverTabImageViewOrTabButton:…`, applied to the platter selected-state control (or self).
     * [CN] 同 -cyl_coverTabImageViewOrTabButton:…，但作用于 Platter 选中态控件（没有则作用于自身）。
     */
    @objc(cyl_coverSeclectContentTabImageViewOrTabButton:newView:offset:show:delayIfNeededForSeconds:completion:)
    public func cyl_coverSeclectContentTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset,
                                                               show: Bool, delayIfNeededForSeconds delay: CGFloat,
                                                               completion: CYLTabButtonReplaceCompletion?) {
        (cyl_platterSelected() ?? self).cyl_coverTabImageViewOrTabButton(
            isTabButton, newView: newView, offset: offset, show: show, delayIfNeededForSeconds: delay, completion: completion)
    }

    /**
     * [EN] Covers the visible tab image view (or button) with `newView`; forwards to the selected-content variant.
     * [CN] 用 newView 覆盖当前可见的 Tab 图片视图（或按钮），内部转调选中态内容的覆盖方法。
     */
    @objc(cyl_coverVisiableTabImageViewOrTabButton:newView:offset:show:delayIfNeededForSeconds:completion:)
    public func cyl_coverVisiableTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool,
                                                         delayIfNeededForSeconds delay: CGFloat,
                                                         completion: CYLTabButtonReplaceCompletion?) {
        cyl_coverSeclectContentTabImageViewOrTabButton(isTabButton, newView: newView, offset: offset, show: show,
                                                       delayIfNeededForSeconds: delay, completion: completion)
    }

    /**
     * [EN] Covers the normal-state content with `contentNewView` and the selected-state content with `seclectContentNewView`.
     * [CN] 分别用 contentNewView 覆盖常态内容、用 seclectContentNewView 覆盖选中态内容。
     */
    @objc(cyl_coverVisiableTabImageViewOrTabButton:contentNewView:seclectContentNewView:offset:show:delayIfNeededForSeconds:completion:)
    public func cyl_coverVisiableTabImageViewOrTabButton(_ isTabButton: Bool, contentNewView: UIView,
                                                         seclectContentNewView: UIView, offset: UIOffset, show: Bool,
                                                         delayIfNeededForSeconds delay: CGFloat,
                                                         completion: CYLTabButtonReplaceCompletion?) {
        cyl_coverTabImageViewOrTabButton(isTabButton, newView: contentNewView, offset: offset, show: show,
                                         delayIfNeededForSeconds: delay) { isReplaced, tabBarButton, newView in
            guard isReplaced, tabBarButton.cyl_platterSelected() != nil else {
                completion?(isReplaced, tabBarButton, newView)
                return
            }
            tabBarButton.cyl_coverSeclectContentTabImageViewOrTabButton(isTabButton, newView: seclectContentNewView,
                                                                        offset: offset, show: show,
                                                                        delayIfNeededForSeconds: delay, completion: completion)
        }
    }

    // MARK: Liquid Glass platter twins

    /**
     * [EN] YES if the control is a Liquid Glass platter selected-state control.
     * [CN] 判断当前控件是否为液态玻璃 Platter 中的选中态控件。
     */
    @objc(cyl_isPlatterSelectedControl)
    public func cyl_isPlatterSelectedControl() -> Bool {
        guard CYLConstants.isLiquidGlassActive(), let superview, cyl_hasCYLTabBar else {
            return false
        }
        return superview.cyl_isPlatterSelectedContentView()
    }

    /**
     * [EN] The platter selected-state control matching this control, or self if none; nil outside a `CYLTabBar`.
     * [CN] 与当前控件对应的 Platter 选中态控件，没有则返回自身；不在 `CYLTabBar` 中时为 nil。
     */
    @objc(cyl_platterSelectedControl)
    public func cyl_platterSelected() -> UIControl? {
        guard cyl_hasCYLTabBar, let tabBar = cyl_tabBarController?.tabBar as CYLTabBar? else {
            return nil
        }
        return tabBar.cyl_selectedContentControl(fromContentControl: self) ?? self
    }

    /**
     * [EN] YES if the control lives in the platter content view (normal state).
     * [CN] 判断当前控件是否位于 Platter 内容视图中（常态控件）。
     */
    @objc(cyl_isPlatterNormalControl)
    public func cyl_isPlatterNormalControl() -> Bool {
        guard cyl_hasCYLTabBar else {
            return false
        }
        return superview?.cyl_isPlatterContentView() ?? false
    }

    /**
     * [EN] The platter normal-state control matching this control, or self if none.
     * [CN] 与当前控件对应的 Platter 常态控件，没有则返回自身。
     */
    @objc(cyl_platterNormalControl)
    public func cyl_platterNormal() -> UIControl {
        cyl_tabBarController?.tabBar.cyl_normalContentControl(fromSelectedContentControl: self) ?? self
    }

    /**
     * [EN] Hides the control and its selected-state counterpart, including labels and images, and disables their interaction.
     * [CN] 隐藏当前控件及其选中态对应控件（包括标题与图片），并禁用交互。
     */
    @objc(cyl_hideControl)
    public func cyl_hideControl() {
        for control in [self, cyl_platterSelected()].compactMap({ $0 }) {
            control.isHidden = true
            control.cyl_tabLabel()?.isHidden = true
            control.cyl_swappableImageViewViewInTabBarButton()?.isHidden = true
            control.isUserInteractionEnabled = false
        }
    }

    // MARK: Deprecated Lottie names (forward to the library-neutral API of UIControl+CYLTabBarItemAnimation)

    /**
     * [EN] Deprecated: use `cyl_tabBarItemAnimationView()`. [CN] 已废弃：请使用 `cyl_tabBarItemAnimationView()`。
     */
    @available(*, deprecated, message: "Use -cyl_tabBarItemAnimationView")
    @objc(cyl_lottieAnimationView)
    public func cyl_lottieAnimationView() -> UIView? {
        cyl_tabBarItemAnimationView()
    }

    /**
     * [EN] Deprecated: use `cyl_isTabBarItemAnimationReady()`. [CN] 已废弃：请使用 `cyl_isTabBarItemAnimationReady()`。
     */
    @available(*, deprecated, message: "Use -cyl_isTabBarItemAnimationReady")
    @objc(cyl_isLottieReady)
    public func cyl_isLottieReady() -> Bool {
        cyl_isTabBarItemAnimationReady()
    }

    /**
     * [EN] Deprecated: use `cyl_addTabBarItemAnimation(with:size:contentMode:)`. [CN] 已废弃：请使用 `cyl_addTabBarItemAnimation(with:size:contentMode:)`。
     */
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:")
    @objc(cyl_addLottieImageWithLottieURL:size:contentMode:)
    public func cyl_addLottieImage(withLottieURL lottieURL: URL?, size: CGSize, contentMode: UIView.ContentMode) {
        cyl_addTabBarItemAnimation(with: lottieURL, size: size, contentMode: contentMode)
    }

    /**
     * [EN] Deprecated: use `cyl_addTabBarItemAnimation(with:size:contentMode:)` with a file URL. [CN] 已废弃：请传入文件 URL 使用 `cyl_addTabBarItemAnimation(with:size:contentMode:)`。
     */
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode: with a file URL")
    @objc(cyl_addLottieImageWithLottieFilePath:size:contentMode:)
    public func cyl_addLottieImage(withLottieFilePath lottieFilePath: String, size: CGSize, contentMode: UIView.ContentMode) {
        cyl_addTabBarItemAnimation(with: CYLConstants.cyl_getURL(from: lottieFilePath), size: size, contentMode: contentMode)
    }

    /**
     * [EN] Deprecated: use `cyl_addTabBarItemAnimation(with:size:contentMode:animationSpeed:)`. [CN] 已废弃：请使用 `cyl_addTabBarItemAnimation(with:size:contentMode:animationSpeed:)`。
     */
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:animationSpeed:")
    @objc(cyl_addLottieImageWithLottieURL:size:contentMode:animationSpeed:)
    public func cyl_addLottieImage(withLottieURL lottieURL: URL?, size: CGSize, contentMode: UIView.ContentMode,
                                   animationSpeed: CGFloat) {
        cyl_addTabBarItemAnimation(with: lottieURL, size: size, contentMode: contentMode, animationSpeed: animationSpeed)
    }

    /**
     * [EN] Deprecated: use `cyl_setTabBarItemAnimationSpeed(_:)`. [CN] 已废弃：请使用 `cyl_setTabBarItemAnimationSpeed(_:)`。
     */
    @available(*, deprecated, message: "Use -cyl_setTabBarItemAnimationSpeed:")
    @objc(cyl_setLottieAnimationSpeed:)
    public func cyl_setLottieAnimationSpeed(_ animationSpeed: CGFloat) {
        cyl_setTabBarItemAnimationSpeed(animationSpeed)
    }

    /**
     * FIX: issue #442
     * [EN] Deprecated: use `cyl_reloadTabBarItemAnimationViewForCurrentStyle()`. [CN] 已废弃：请使用 `cyl_reloadTabBarItemAnimationViewForCurrentStyle()`。
     */
    @available(*, deprecated, message: "Use -cyl_reloadTabBarItemAnimationViewForCurrentStyle")
    @objc(cyl_reloadLottieAnimationViewForCurrentStyle)
    public func cyl_reloadLottieAnimationViewForCurrentStyle() {
        cyl_reloadTabBarItemAnimationViewForCurrentStyle()
    }

    /**
     * [EN] Deprecated: use `cyl_playTabBarItemAnimation(with:size:defaultSelected:contentMode:)`. [CN] 已废弃：请使用 `cyl_playTabBarItemAnimation(with:size:defaultSelected:contentMode:)`。
     */
    @available(*, deprecated, message: "Use -cyl_playTabBarItemAnimationWithURL:size:defaultSelected:contentMode:")
    @objc(cyl_animationLottieImageWithLottieURL:size:defaultSelected:contentMode:)
    public func cyl_animationLottieImage(withLottieURL lottieURL: URL, size: CGSize, defaultSelected: Bool,
                                         contentMode: UIView.ContentMode) {
        cyl_playTabBarItemAnimation(with: lottieURL, size: size, defaultSelected: defaultSelected, contentMode: contentMode)
    }

    /**
     * [EN] Deprecated: use `cyl_stopTabBarItemAnimation()`. [CN] 已废弃：请使用 `cyl_stopTabBarItemAnimation()`。
     */
    @available(*, deprecated, message: "Use -cyl_stopTabBarItemAnimation")
    @objc(cyl_stopAnimationOfLottieView)
    public func cyl_stopAnimationOfLottieView() {
        cyl_stopTabBarItemAnimation()
    }

    // MARK: Private

    /**
     * [EN] YES when the tab bar is a `CYLTabBar` at run time (the property is typed so, but an app can set another class).
     * [CN] TabBar 在运行时为 `CYLTabBar` 时为 YES（属性声明为该类型，但 App 可以设置其他类）。
     */
    private var cyl_hasCYLTabBar: Bool {
        cyl_tabBarController?.tabBar.isKind(of: CYLTabBar.self) ?? false
    }

    private var cyl_isTabButtonOrPlusButton: Bool {
        cyl_isTabButton() || cyl_isPlusButton()
    }

    private func integer(for key: UnsafeRawPointer) -> Int {
        (objc_getAssociatedObject(self, key) as? NSNumber)?.intValue ?? 0
    }

    private func setInteger(_ value: Int, for key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, NSNumber(value: value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The plus button class's `+tabBarItemIdentifier`, else its class name (e.g. "CYLPlusButtonSubclass").
     * [CN] PlusButton 类的 `+tabBarItemIdentifier`，未实现时为类名（如 "CYLPlusButtonSubclass"）。
     */
    private var cyl_plusButtonClassIdentifier: String {
        let buttonClass: AnyClass = type(of: self)
        let selector = NSSelectorFromString("tabBarItemIdentifier")
        if (buttonClass as AnyObject).responds(to: selector),
           let identifier = (buttonClass as AnyObject).perform(selector)?.takeUnretainedValue() as? String,
           !identifier.isEmpty {
            return identifier
        }
        return CYLTabBarController.cyl_defaultTabBarItemIdentifier(for: buttonClass)
    }

    /**
     * [EN] Shows `cover` over every other subview (as a badge is, `-cyl_bringBadgeToFront:`), or puts it back.
     * [CN] 让 `cover` 位于其他所有子视图之上（与角标一样，`-cyl_bringBadgeToFront:`），或恢复原状。
     */
    private func cyl_showCover(_ cover: UIView, show: Bool) {
        // [EN] Issue #601: the views shown in place of the tab's icon stay hidden under the cover.
        // [CN] 替换图标的视图在封面下保持隐藏。
        cover.cyl_tabButtonCoverView = show
        if show {
            bringSubviewToFront(cover)
            cover.layer.zPosition = .greatestFiniteMagnitude
        } else {
            cover.layer.zPosition = 0
        }
        cyl_swappableImageViewViewInTabBarButton()?.isHidden = true
        for subview in subviews where subview !== cover && !(subview is CYLTabButtonLayoutTracker) {
            subview.cyl_setHidden(show)
        }
    }

    /**
     * [EN] Shows `newView` in place of the tab image view (or the whole button), placed by frame (#653).
     * [CN] 用 `newView` 替换 Tab 图片视图（或整个按钮）显示，用 frame 定位（#653）。
     */
    private func cyl_replace(isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool, autoHidesNewView: Bool,
                             hidesOriginalView: Bool, completion: CYLTabButtonReplaceCompletion?) {
        let swappableImageView = cyl_tabImageView()
        guard let replacedView: UIView = isTabButton ? self : swappableImageView else {
            completion?(false, self, newView)
            return
        }
        // [EN] TODO: tell the cover and the replace cases apart and decide whether to limit the new view's size; it is not
        //      limited for now, as covering is the main case. A size set on `newView` decides how large it shows.
        // [CN] TODO：区分覆盖与替换两种场景，决定是否限制新视图尺寸；目前不限制，因为主要场景为覆盖。`newView` 设置的尺寸决定其显示大小。
        if newView.frame.width == 0 || newView.frame.height == 0 {
            if cyl_tabBarController?.adjustTabBarItemImageViewSizeDependOnSuperView == true {
                newView.frame.size = frame.size
            } else {
                newView.frame.size = swappableImageView?.image?.size ?? .zero
            }
        }
        let isInThisButton = newView.superview === self
        if newView.superview != nil && !isInThisButton {
            newView.removeFromSuperview()
        }
        if isInThisButton && show {
            // FIX: issue #662 — already shown: refresh its placement with the current offset.
            // [CN] 已显示：用当前的 offset 刷新定位。
            CYLTabButtonLayoutTracker.track(newView, size: newView.bounds.size, in: self, imageView: swappableImageView,
                                            replacedView: replacedView, offset: offset)
            completion?(true, self, newView)
            return
        }
        if hidesOriginalView {
            swappableImageView?.isHidden = show
            if isTabButton {
                cyl_tabLabel()?.isHidden = show
            }
        }
        if show && newView.superview == nil {
            addSubview(newView)
            // [EN] Marked: found again in one pass, and recognized in an old button after UIKit rebuilt them.
            // [CN] 标记：可一次性找到；UIKit 重建按钮后仍在旧按钮中时也能被识别。
            newView.cyl_markAsInserted(forTabControl: self)
            CYLTabButtonLayoutTracker.track(newView, size: newView.frame.size, in: self, imageView: swappableImageView,
                                            replacedView: replacedView, offset: offset)
            completion?(true, self, newView)
            return
        }
        if newView.superview != nil && autoHidesNewView {
            newView.removeFromSuperview()
        }
        completion?(false, self, newView)
    }
}

enum CYLControlTabBarSupport {
    static let flatDesignTabBarButtonClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBarButton")
}

// MARK: - UIControl (CYLTabBarControllerExtentionDeprecated)

extension UIControl {

    /**
     * [EN] Deprecated in 1.19.0: the red-dot view. Use the methods of `CYLBadgeProtocol`.
     * [CN] 1.19.0 起废弃：红点视图。请使用 `CYLBadgeProtocol` 中的方法。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_tabBadgePointView)
    public var cyl_tabBadgePointView: UIView {
        @objc(cyl_tabBadgePointView) get {
            if let view = objc_getAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointView) as? UIView {
                return view
            }
            let view = UIView.cyl_tabBadgePointView(withClolor: .red, radius: 4.5)
            objc_setAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return view
        }
        @objc(cyl_setTabBadgePointView:) set {
            (objc_getAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointView) as? UIView)?.removeFromSuperview()
            newValue.removeFromSuperview()
            newValue.isHidden = true
            objc_setAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Deprecated in 1.19.0: the red dot's offset; positive values move it right and down.
     * [CN] 1.19.0 起废弃：红点的偏移量；正值向右下偏移。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_tabBadgePointViewOffset)
    public var cyl_tabBadgePointViewOffset: UIOffset {
        @objc(cyl_tabBadgePointViewOffset) get {
            (objc_getAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointViewOffset) as? NSValue)?.uiOffsetValue ?? .zero
        }
        @objc(cyl_setTabBadgePointViewOffset:) set {
            objc_setAssociatedObject(self, CYLControlTabBarKeys.tabBadgePointViewOffset, NSValue(uiOffset: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Deprecated. Shows the red dot; a system badge added before is hidden, not removed. Use
     *      `-[UIViewController cyl_showBadgeValue:animationType:]`.
     * [CN] 已废弃。显示红点；之前添加的系统角标只是被隐藏、未被移除。请改用 -[UIViewController cyl_showBadgeValue:animationType:]。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_showTabBadgePoint)
    public func cyl_showTabBadgePoint() {
        cyl_setShowsTabBadgePoint(true)
    }

    /**
     * [EN] Deprecated. Removes the red dot and shows the system badge again. Use `-[UIViewController cyl_clearBadge]`.
     * [CN] 已废弃。移除红点并重新显示系统角标。请改用 -[UIViewController cyl_clearBadge]。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_removeTabBadgePoint)
    public func cyl_removeTabBadgePoint() {
        cyl_setShowsTabBadgePoint(false)
    }

    /**
     * [EN] Deprecated. YES if the red dot is shown. Use `-[UIViewController cyl_isShowBadge]`.
     * [CN] 已废弃。判断红点是否显示，请改用 -[UIViewController cyl_isShowBadge]。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_isShowTabBadgePoint)
    public func cyl_isShowTabBadgePoint() -> Bool {
        !cyl_tabBadgePointView.isHidden
    }

    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    private func cyl_setShowsTabBadgePoint(_ shows: Bool) {
        let pointView = cyl_tabBadgePointView
        if shows && pointView.superview == nil {
            cyl_bringSubview(toFront: pointView)
            // FIX: issue #653 — frames, not constraints: centre at the image view's top-right corner plus the offset.
            // [CN] 用 frame 而非约束：中心位于图片视图右上角，再加偏移量。
            pointView.translatesAutoresizingMaskIntoConstraints = true
            CYLTabButtonLayoutTracker.tracker(for: self).track(pointView) { [weak imageView = cyl_tabImageView()] tabButton in
                let topRight = CYLTabButtonLayoutTracker.point(
                    CGPoint(x: imageView?.bounds.maxX ?? 0, y: imageView?.bounds.minY ?? 0), of: imageView, in: tabButton)
                let offset = tabButton.cyl_tabBadgePointViewOffset
                return CGPoint(x: topRight.x + offset.horizontal, y: topRight.y + offset.vertical)
            }
        }
        pointView.isHidden = !shows
        cyl_tabBadgeView()?.isHidden = shows
    }
}

// MARK: - UIView (CYLTabBarItemAnimationCoreSupport), declared in UIControl+CYLTabBarItemAnimation.h

extension UIView {

    /**
     * [EN] Moves the layout tracking of `view` (#653) to `newView`, which also keeps the tab button mark of `view`.
     * [CN] 把 `view` 的布局跟踪（#653）改为跟随 `newView`，`newView` 同时沿用 `view` 的 Tab 按钮标记。
     */
    @objc(cyl_replaceTrackedSubview:withView:)
    func cyl_replaceTrackedSubview(_ view: UIView, withView newView: UIView) {
        if let tabControl = view.cyl_insertedForTabControl ?? (self as? UIControl) {
            newView.cyl_markAsInserted(forTabControl: tabControl)
        }
        for case let tracker as CYLTabButtonLayoutTracker in subviews {
            tracker.replaceTrackedView(view, with: newView)
        }
    }
}
