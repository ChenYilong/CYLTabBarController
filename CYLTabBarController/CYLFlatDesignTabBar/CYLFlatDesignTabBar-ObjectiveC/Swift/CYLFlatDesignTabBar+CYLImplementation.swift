//
//  CYLFlatDesignTabBar+CYLImplementation.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The implementation of `CYLFlatDesignTabBar`, translated from Objective-C (docs/Swift-Migration.md, step 50). The
//      class stays declared in Objective-C: `CYLTabBarController.h` adopts `CYLFlatDesignTabBarDelegate`, which its
//      interface names, so the protocol and the class move with `CYLTabBarController`. CYLFlatDesignTabBar.m keeps the
//      overrides and the public accessors as one-line forwards to the `cyl_flatDesign…` methods below (declared there).
// [CN] `CYLFlatDesignTabBar` 的实现，已从 Objective-C 翻译（docs/Swift-Migration.md，第 50 步）。类仍在 Objective-C 中声明：
//      `CYLTabBarController.h` 遵守其接口引用的 `CYLFlatDesignTabBarDelegate`，因此协议与类随 `CYLTabBarController` 一起迁移。
//      CYLFlatDesignTabBar.m 保留重写方法与公开存取方法，均为一行转发到下面的 `cyl_flatDesign…` 方法（在该文件中声明）。

/**
 * [EN] Private methods of `CYLTabBarController` (Objective-C) that the FlatDesign tab bar calls.
 * [CN] 扁平样式 TabBar 调用的 `CYLTabBarController`（Objective-C）私有方法。
 */
@objc private protocol CYLFlatDesignTabBarControllerPrivateAPI {
    /// FIX: issue #610 — implemented in CYLTabBarController.m.
    @objc(cyl_flatDesignReportDidSelectControl:) func flatDesignReportDidSelectControl(_ control: UIControl)
    /// [EN] The pressed animation (CYLTabBarController+CYLInteraction). [CN] 按下动画（CYLTabBarController+CYLInteraction）。
    @objc(cyl_tabButtonTouchDown:) func tabButtonTouchDown(_ control: UIControl)
    @objc(cyl_tabButtonTouchUp:) func tabButtonTouchUp(_ control: UIControl)
}

/**
 * [EN] The state of one FlatDesign tab bar (its views, buttons, selection and the values of its public properties).
 * [CN] 一个扁平样式 TabBar 的状态（视图、按钮、选中项以及公开属性的值）。
 */
final class CYLFlatDesignTabBarStorage: NSObject {
    var selectedItemIndex = -1
    var buttons: [CYLFlatDesignTabBarButton] = []
    /// FIX: issue #488 — the token of the block-based animation observer, removed in `deinit`.
    var animationPlayingObserver: NSObjectProtocol?
    /// [EN] The appearance the bar was last drawn with, to refresh only when it changes. [CN] 上次绘制所用的 appearance，仅在改变时刷新。
    var appliedAppearance: UITabBarAppearance?
    /// [EN] The top hairline drawn for `UIBarAppearance.shadowColor` without a shadow image. [CN] 没有阴影图片时按 `shadowColor` 绘制的顶部细线。
    var appearanceShadowLineView: UIView?
    let backgroundView = UIView()
    var backgroundEffectView: UIVisualEffectView?
    let backgroundImageView = UIImageView()
    var shadowImageView: UIImageView?
    let contentView = UIView()
    weak var plusButton: UIButton?

    weak var delegate: CYLFlatDesignTabBarDelegate?
    var items: [CYLFlatDesignTabBarItem]?
    var standardAppearance: UITabBarAppearance?
    var tintColor: UIColor?
    var barTintColor: UIColor?
    var backgroundImage: UIImage?
    var shadowImage: UIImage?
    var useLayoutSafeAreaInsets = true
    var respectsVerticalStatusBarSafeArea = false
    var context: String?

    deinit {
        // [EN] A block-based observer is only removed by its token. [CN] 基于 block 的观察者只能通过 token 移除。
        if let animationPlayingObserver {
            NotificationCenter.default.removeObserver(animationPlayingObserver)
        }
    }
}

private enum CYLFlatDesignTabBarKeys {
    static var storage: UInt8 = 0
}

extension CYLFlatDesignTabBar {

    var cylFlatDesignStorage: CYLFlatDesignTabBarStorage {
        if let storage = objc_getAssociatedObject(self, &CYLFlatDesignTabBarKeys.storage) as? CYLFlatDesignTabBarStorage {
            return storage
        }
        let storage = CYLFlatDesignTabBarStorage()
        objc_setAssociatedObject(self, &CYLFlatDesignTabBarKeys.storage, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return storage
    }

    // MARK: - [EN] Life cycle [CN] 生命周期

    /**
     * [EN] Called by `-initWithFrame:`: the push hook, the views, the defaults and the observers.
     * [CN] 由 `-initWithFrame:` 调用：push hook、视图、默认值与观察者。
     */
    @objc(cyl_flatDesignCommonInit)
    func cylFlatDesignCommonInit() {
        // [CN] 引入CYLFlatDesignTabBar，即表示同意 hook push行为
        // [EN] Importing CYLFlatDesignTabBar means you agree to hooking the push behavior.
        UINavigationController.cylNavigationBarActionHook()
        let storage = cylFlatDesignStorage
        // [EN] VoiceOver announces its buttons as tabs ("tab, 2 of 5"). [CN] VoiceOver 将其中的按钮朗读为标签页。
        accessibilityTraits.insert(.tabBar)
        storage.backgroundView.clipsToBounds = false
        addSubview(storage.backgroundView)
        storage.backgroundView.addSubview(storage.backgroundImageView)
        storage.contentView.clipsToBounds = false
        addSubview(storage.contentView)

        barTintColor = .clear
        tintColor = .systemBlue
        // FIX: issue #662 (iPhone Duo follow-up, PR #665)
        // [EN] The default declared in the header (YES): buttons avoid the left/right safe areas; iPhone Duo (iOS 27.1 SDK)
        //      has an 84 pt vertical status bar on the right, which otherwise covers the last tab and clips it during
        //      push / pop. FIX: issue #672 — the one-sided inset of a vertical status bar is ignored by default.
        // [CN] 与头文件声明的默认值一致（YES）：按钮避开左右安全区；iPhone Duo（iOS 27.1 SDK）右侧有 84pt 的竖向状态栏，否则会盖住最后
        //      一个 Tab，并在 push/pop 转场中被裁掉一截。FIX: issue #672——默认忽略竖向状态栏产生的单侧安全区。
        storage.useLayoutSafeAreaInsets = true
        storage.respectsVerticalStatusBarSafeArea = false

        NotificationCenter.default.addObserver(self, selector: #selector(cylFlatDesignTabBarItemDidChange(_:)),
                                               name: NSNotification.Name(CYLFlatDesignTabBarItemDidChange), object: nil)
        // [CN] 仅在引入动画库时监听（#604，运行时判断，以支持任意动画库）。
        // [EN] Observe only with an animation library (#604, checked at runtime so that any library works).
        if CYLTabBarItemAnimationCore.service != nil {
            storage.animationPlayingObserver = NotificationCenter.default.addObserver(
                forName: .CYLTabBarItemAnimationPlaying, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    // Library-neutral (#604): every animation library. 与动画库无关：所有动画库。
                    self?.cylStopAllTabBarItemAnimations()
                }
            }
        }
    }

    /// [EN] The content height, once laid out. [CN] 布局后的内容高度。
    @objc(cyl_flatDesignSizeThatFits:)
    func cylFlatDesignSizeThatFits(_ sizeThatFits: CGSize) -> CGSize {
        var size = sizeThatFits
        let height = cylFlatDesignStorage.contentView.frame.height
        if height > 0 {
            size.height = height
        }
        return size
    }

    @objc(cyl_flatDesignLayoutSubviews)
    func cylFlatDesignLayoutSubviews() {
        cylUpdateLayout()
        // [EN] The tab titles move with the tab bar height (which can change at any time in the Flat style): lay the plus
        //      button out again so its title follows them (`+alignsTitleWithTabBarItemTitles`).
        // [CN] Tab 标题随 TabBar 高度移动（扁平样式下随时可能变化）：重新布局 PlusButton，使其标题跟随（`+alignsTitleWithTabBarItemTitles`）。
        CYLPlusButton(forOwner: self)?.cyl_setNeedsTitleAlignment()
    }

    @objc(_tabBarItemDidChange:)
    func cylFlatDesignTabBarItemDidChange(_ note: Notification) {
        let storage = cylFlatDesignStorage
        guard let items = storage.items, !items.isEmpty, let changedItem = note.object as? CYLFlatDesignTabBarItem,
              let index = items.firstIndex(where: { $0 == changedItem }), index < storage.buttons.count else { return }
        storage.buttons[index].tabBarItem = changedItem
        // [EN] The selected item's own `standardAppearance` styles the whole bar. [CN] 选中 item 自身的 `standardAppearance` 作用于整个 TabBar。
        cylUpdateAppearanceIfNeeded()
    }

    // MARK: - [EN] Public properties [CN] 公开属性

    @objc(cyl_flatDesignAddItemWithTitle:tabBarItemImage:tabBarItemSelectedImage:index:titlePositionAdjustment:imageInsets:lottieFilePath:lottieSizeValue:)
    func cylFlatDesignAddItem(title: String?, image: Any?, selectedImage: Any?, index: Int,
                              titlePositionAdjustment: UIOffset, imageInsets: UIEdgeInsets,
                              lottieFilePath: String?, lottieSizeValue: NSValue?) -> CYLFlatDesignTabBarItem {
        CYLFlatDesignTabBarItem(title: title, image: image, selectedImage: selectedImage, index: index,
                                titlePositionAdjustment: titlePositionAdjustment, imagePositionAdjustment: .zero,
                                imageInsets: imageInsets, lottieFilePath: lottieFilePath, lottieSizeValue: lottieSizeValue)
    }

    @objc(cyl_flatDesignTabBarButtons)
    func cylFlatDesignTabBarButtons() -> [CYLFlatDesignTabBarButton] {
        cylFlatDesignStorage.buttons
    }

    @objc(cyl_flatDesignDelegate)
    func cylFlatDesignDelegate() -> CYLFlatDesignTabBarDelegate? {
        cylFlatDesignStorage.delegate
    }

    @objc(cyl_flatDesignSetDelegate:)
    func cylFlatDesignSetDelegate(_ delegate: CYLFlatDesignTabBarDelegate?) {
        let storage = cylFlatDesignStorage
        guard storage.delegate !== delegate else { return }
        // [EN] As on the system tab bar, a tab bar controller's tab bar keeps its delegate.
        // [CN] 与系统 TabBar 相同，TabBarController 的 TabBar 不允许更换代理。
        if storage.delegate != nil, cylFlatDesignOwningTabBarController != nil {
            assert(false, CYLLocalizedString("不允许更改由 tabBarController 管理的 tabBar 的代理"))
            return
        }
        storage.delegate = delegate
    }

    @objc(cyl_flatDesignItems)
    func cylFlatDesignItems() -> [CYLFlatDesignTabBarItem]? {
        cylFlatDesignStorage.items
    }

    @objc(cyl_flatDesignSetItems:)
    func cylFlatDesignSetItems(_ items: [CYLFlatDesignTabBarItem]?) {
        let storage = cylFlatDesignStorage
        // [EN] As before: only two equal arrays are skipped (nil always reloads). [CN] 与以前相同：只跳过两个相等的数组（nil 总会重新加载）。
        if let oldItems = storage.items, let items, (oldItems as NSArray).isEqual(to: items) {
            return
        }
        if let selectedItem = cylFlatDesignSelectedItem(), !(items ?? []).contains(selectedItem) {
            storage.selectedItemIndex = -1
        }
        storage.items = items
        cylReloadItems()
    }

    @objc(cyl_flatDesignSelectedItem)
    func cylFlatDesignSelectedItem() -> CYLFlatDesignTabBarItem? {
        let storage = cylFlatDesignStorage
        guard let items = storage.items, storage.selectedItemIndex >= 0, storage.selectedItemIndex < items.count else { return nil }
        return items[storage.selectedItemIndex]
    }

    @objc(cyl_flatDesignSetSelectedItem:)
    func cylFlatDesignSetSelectedItem(_ selectedItem: CYLFlatDesignTabBarItem?) {
        let storage = cylFlatDesignStorage
        if let selectedItem {
            if let index = storage.items?.firstIndex(where: { $0 == selectedItem }), storage.selectedItemIndex != index {
                cylSetSelectedIndex(index)
            }
        } else if cylFlatDesignSelectedItem() != nil {
            storage.buttons[storage.selectedItemIndex].isSelected = false
            storage.selectedItemIndex = -1
        }
    }

    /**
     * [EN] The selected index, 0 when nothing is selected. (The Objective-C getter read a value that was never written and
     *      always returned 0.)
     * [CN] 选中的下标，没有选中项时为 0。（Objective-C 的 getter 读取的值从未被写入，始终返回 0。）
     */
    @objc(cyl_flatDesignSelectedIndex)
    func cylFlatDesignSelectedIndex() -> UInt {
        UInt(max(cylFlatDesignStorage.selectedItemIndex, 0))
    }

    @objc(cyl_flatDesignSetSelectedIndex:)
    func cylFlatDesignSetSelectedIndex(_ selectedIndex: UInt) {
        cylSetSelectedIndex(Int(selectedIndex))
    }

    @objc(cyl_flatDesignTintColor)
    func cylFlatDesignTintColor() -> UIColor? {
        cylFlatDesignStorage.tintColor
    }

    @objc(cyl_flatDesignSetTintColor:)
    func cylFlatDesignSetTintColor(_ tintColor: UIColor?) {
        let storage = cylFlatDesignStorage
        guard storage.tintColor !== tintColor else { return }
        storage.tintColor = tintColor
        storage.buttons.forEach { $0.tintColor = tintColor }
    }

    @objc(cyl_flatDesignBarTintColor)
    func cylFlatDesignBarTintColor() -> UIColor? {
        cylFlatDesignStorage.barTintColor
    }

    @objc(cyl_flatDesignSetBarTintColor:)
    func cylFlatDesignSetBarTintColor(_ barTintColor: UIColor?) {
        let storage = cylFlatDesignStorage
        guard storage.barTintColor !== barTintColor else { return }
        storage.barTintColor = barTintColor
        cylUpdateBackground()
    }

    @objc(cyl_flatDesignBackgroundImage)
    func cylFlatDesignBackgroundImage() -> UIImage? {
        cylFlatDesignStorage.backgroundImage
    }

    @objc(cyl_flatDesignSetBackgroundImage:)
    func cylFlatDesignSetBackgroundImage(_ backgroundImage: UIImage?) {
        let storage = cylFlatDesignStorage
        guard storage.backgroundImage !== backgroundImage else { return }
        storage.backgroundImage = backgroundImage
        cylUpdateBackground()
    }

    @objc(cyl_flatDesignShadowImage)
    func cylFlatDesignShadowImage() -> UIImage? {
        cylFlatDesignStorage.shadowImage
    }

    @objc(cyl_flatDesignSetShadowImage:)
    func cylFlatDesignSetShadowImage(_ shadowImage: UIImage?) {
        let storage = cylFlatDesignStorage
        guard storage.shadowImage !== shadowImage else { return }
        storage.shadowImage = shadowImage
        cylUpdateBackground()
    }

    @objc(cyl_flatDesignStandardAppearance)
    func cylFlatDesignStandardAppearance() -> UITabBarAppearance? {
        cylFlatDesignStorage.standardAppearance
    }

    @objc(cyl_flatDesignSetStandardAppearance:)
    func cylFlatDesignSetStandardAppearance(_ standardAppearance: UITabBarAppearance?) {
        let storage = cylFlatDesignStorage
        guard storage.standardAppearance !== standardAppearance else { return }
        storage.standardAppearance = standardAppearance?.copy() as? UITabBarAppearance
        cylUpdateAppearanceIfNeeded()
    }

    @objc(cyl_flatDesignUseLayoutSafeAreaInsets)
    func cylFlatDesignUseLayoutSafeAreaInsets() -> Bool {
        cylFlatDesignStorage.useLayoutSafeAreaInsets
    }

    @objc(cyl_flatDesignSetUseLayoutSafeAreaInsets:)
    func cylFlatDesignSetUseLayoutSafeAreaInsets(_ useLayoutSafeAreaInsets: Bool) {
        let storage = cylFlatDesignStorage
        guard storage.useLayoutSafeAreaInsets != useLayoutSafeAreaInsets else { return }
        storage.useLayoutSafeAreaInsets = useLayoutSafeAreaInsets
        setNeedsLayout()
    }

    @objc(cyl_flatDesignRespectsVerticalStatusBarSafeArea)
    func cylFlatDesignRespectsVerticalStatusBarSafeArea() -> Bool {
        cylFlatDesignStorage.respectsVerticalStatusBarSafeArea
    }

    @objc(cyl_flatDesignSetRespectsVerticalStatusBarSafeArea:)
    func cylFlatDesignSetRespectsVerticalStatusBarSafeArea(_ respects: Bool) {
        let storage = cylFlatDesignStorage
        guard storage.respectsVerticalStatusBarSafeArea != respects else { return }
        storage.respectsVerticalStatusBarSafeArea = respects
        setNeedsLayout()
    }

    @objc(cyl_flatDesignContext)
    func cylFlatDesignContext() -> String? {
        cylFlatDesignStorage.context
    }

    @objc(cyl_flatDesignSetContext:)
    func cylFlatDesignSetContext(_ context: String?) {
        cylFlatDesignStorage.context = context
        cyl_context = context
    }

    // MARK: - [EN] UITabBarAppearance mapping [CN] UITabBarAppearance 映射

    /**
     * [EN] The appearance the bar is drawn with: the selected item's own one, else `standardAppearance`; nil when neither is
     *      set (the flat design look and `barTintColor` / `backgroundImage` / `shadowImage`).
     * [CN] TabBar 绘制所用的 appearance：选中 item 自身的，否则为 `standardAppearance`；二者都未设置时为 nil（使用扁平样式外观及
     *      `barTintColor` / `backgroundImage` / `shadowImage`）。
     */
    private var cylEffectiveAppearance: UITabBarAppearance? {
        cylFlatDesignSelectedItem()?.standardAppearance ?? cylFlatDesignStorage.standardAppearance
    }

    /// [EN] Redraws the background and every button when the effective appearance changed. [CN] 有效 appearance 改变时重绘背景与所有按钮。
    private func cylUpdateAppearanceIfNeeded() {
        let storage = cylFlatDesignStorage
        let appearance = cylEffectiveAppearance
        guard appearance !== storage.appliedAppearance else { return }
        storage.appliedAppearance = appearance
        cylUpdateBackground()
        storage.buttons.forEach { $0.cylUpdateTabBarButton() }
        setNeedsLayout()
    }

    private func cylSetBackgroundEffect(_ effect: UIVisualEffect?) {
        let storage = cylFlatDesignStorage
        guard let effect else {
            storage.backgroundEffectView?.removeFromSuperview()
            storage.backgroundEffectView = nil
            return
        }
        let effectView = storage.backgroundEffectView ?? UIVisualEffectView(effect: effect)
        effectView.effect = effect
        storage.backgroundEffectView = effectView
        storage.backgroundView.insertSubview(effectView, at: 0)
    }

    private func cylSetShadowImage(_ shadowImage: UIImage?, tintColor: UIColor?) {
        let storage = cylFlatDesignStorage
        guard let shadowImage else {
            storage.shadowImageView?.removeFromSuperview()
            storage.shadowImageView = nil
            return
        }
        let imageView = storage.shadowImageView ?? UIImageView()
        storage.shadowImageView = imageView
        imageView.image = shadowImage
        imageView.tintColor = tintColor
        storage.backgroundView.addSubview(imageView)
    }

    private func cylSetShadowLineColor(_ color: UIColor?) {
        let storage = cylFlatDesignStorage
        guard let color else {
            storage.appearanceShadowLineView?.removeFromSuperview()
            storage.appearanceShadowLineView = nil
            return
        }
        let lineView = storage.appearanceShadowLineView ?? UIView()
        storage.appearanceShadowLineView = lineView
        lineView.backgroundColor = color
        storage.backgroundView.addSubview(lineView)
    }

    /**
     * [EN] Draws the background and the top shadow, from the effective `UITabBarAppearance` if there is one, else from the
     *      flat design properties (an image hides the blur; otherwise `barTintColor` over a blur).
     * [CN] 绘制背景与顶部阴影：有有效的 `UITabBarAppearance` 时按其绘制，否则按扁平样式属性（有背景图时不显示模糊，否则在模糊之上显示
     *      `barTintColor`）。
     */
    private func cylUpdateBackground() {
        let storage = cylFlatDesignStorage
        if let appearance = cylEffectiveAppearance {
            cylSetBackgroundEffect(appearance.backgroundEffect)
            storage.backgroundImageView.image = appearance.backgroundImage
            storage.backgroundImageView.contentMode = appearance.backgroundImageContentMode
            storage.backgroundImageView.backgroundColor = appearance.backgroundColor ?? .clear
            let shadowImage = appearance.shadowImage
            cylSetShadowImage(shadowImage, tintColor: appearance.shadowColor)
            cylSetShadowLineColor(shadowImage == nil ? appearance.shadowColor : nil)
            setNeedsLayout()
            return
        }
        storage.backgroundImageView.image = storage.backgroundImage
        storage.backgroundImageView.contentMode = .scaleToFill
        if storage.backgroundImage != nil {
            cylSetBackgroundEffect(nil)
            storage.backgroundImageView.backgroundColor = .clear
        } else {
            storage.backgroundImageView.backgroundColor = storage.barTintColor
            cylSetBackgroundEffect(UIBlurEffect(style: .prominent))
        }
        cylSetShadowImage(storage.shadowImage, tintColor: nil)
        cylSetShadowLineColor(nil)
        setNeedsLayout()
    }

    // MARK: - [EN] Taps [CN] 点击

    /// [EN] The tab bar controller this bar belongs to: its delegate. [CN] 本 TabBar 所属的 TabBarController：即其代理。
    private var cylFlatDesignOwningTabBarController: UITabBarController? {
        cylFlatDesignStorage.delegate as? UITabBarController
    }

    private func cylPrivateAPI(of controller: UITabBarController) -> CYLFlatDesignTabBarControllerPrivateAPI {
        unsafeBitCast(controller as AnyObject, to: CYLFlatDesignTabBarControllerPrivateAPI.self)
    }

    /// [EN] Touch down / up on a tab button: the pressed animation of the tab bar controller.
    /// [CN] 手指按下 / 抬起 Tab 按钮：TabBarController 的按下动画。
    @objc(_tabBarDidTouchDownButton:)
    func cylTabBarDidTouchDownButton(_ tabBarButton: CYLFlatDesignTabBarButton) {
        guard !tabBarButton.cyl_isPlaceholder, let controller = cylFlatDesignOwningTabBarController as? CYLTabBarController,
              controller.responds(to: NSSelectorFromString("cyl_tabButtonTouchDown:")) else { return }
        cylPrivateAPI(of: controller).tabButtonTouchDown(tabBarButton)
    }

    @objc(_tabBarDidTouchUpButton:)
    func cylTabBarDidTouchUpButton(_ tabBarButton: CYLFlatDesignTabBarButton) {
        guard !tabBarButton.cyl_isPlaceholder, let controller = cylFlatDesignOwningTabBarController as? CYLTabBarController,
              controller.responds(to: NSSelectorFromString("cyl_tabButtonTouchUp:")) else { return }
        cylPrivateAPI(of: controller).tabButtonTouchUp(tabBarButton)
    }

    @objc(_tabBarDidSelectButton:)
    func cylTabBarDidSelectButton(_ tabBarButton: CYLFlatDesignTabBarButton) {
        let storage = cylFlatDesignStorage
        guard let selectedIndex = storage.buttons.firstIndex(where: { $0 === tabBarButton }),
              let items = storage.items, selectedIndex < items.count else { return }
        let item = items[selectedIndex]
        guard item.isEnabled else { return }

        // FIX: issue #19 — a tab that needs login, tapped while logged out: the button is not selected (no animation), the
        // tap is not reported as a selection, and the login starts instead.
        // 需要登录的 Tab 在未登录时被点击：按钮不会被选中（不播放动画），不作为选中上报，改为发起登录。
        if let loginTabBarController = cylOwningTabBarController(), !tabBarButton.cyl_isPlaceholder,
           let viewControllers = loginTabBarController.viewControllers, selectedIndex < viewControllers.count {
            if loginTabBarController.cylInterceptLoginIfNeeded(for: viewControllers[selectedIndex]) {
                return
            }
            // [EN] A custom action tab (CYLCustomTabAction): not selected, not reported; its action runs instead.
            // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）：不选中、不上报，改为执行对应操作。
            if loginTabBarController.cyl_performCustomTabActionIfNeeded(for: viewControllers[selectedIndex]) {
                return
            }
        }

        // FIX: issue #610
        // [EN] Report the tap through `tabBarController:didSelectControl:`, as the other styles do, here where every tab
        //      button tap arrives (the selection below takes one of three paths). The button under the plus button (a plus
        //      button with a child view controller, tapped outside its own outline) reports the plus button.
        // [CN] 与其他样式一样，通过 `tabBarController:didSelectControl:` 上报点击，放在每次点击 Tab 按钮都会经过的这里（下面的选中逻辑有三条
        //      路径）。PlusButton 下方的占位按钮（有子控制器的 PlusButton，点在其轮廓外）上报的是 PlusButton。
        let owningTabBarController = cylFlatDesignOwningTabBarController
        if let controller = owningTabBarController as? CYLTabBarController,
           controller.responds(to: NSSelectorFromString("cyl_flatDesignReportDidSelectControl:")) {
            var control: UIControl? = tabBarButton
            if tabBarButton.cyl_isPlaceholder {
                // [EN] Only a plus button with a child view controller selects a tab from here; one without reports itself
                //      (`-cyl_flatDesignPlusButtonTouchUpInside:`).
                // [CN] 只有带子控制器的 PlusButton 会在这里选中 Tab；没有子控制器的由 `-cyl_flatDesignPlusButtonTouchUpInside:` 上报。
                control = cylFlatDesignHasPlusChildViewController() ? storage.plusButton : nil
            }
            if let control {
                cylPrivateAPI(of: controller).flatDesignReportDidSelectControl(control)
            }
        }

        storage.delegate?.tabBar?(self, didSelect: item)

        guard let owningTabBarController else {
            cylSetSelectedIndex(selectedIndex)
            return
        }
        // [EN] UIKit's own handler, with the system item of this button's view controller (FIX: placeholder count mismatch —
        //      the system tab bar has no item for a placeholder slot, so its indexes differ after the slot).
        // [CN] UIKit 自己的处理方法，传入该按钮对应控制器的系统 item（FIX：占位导致的数量不匹配——系统 TabBar 中没有占位 slot 的 item，
        //      slot 之后的下标不一致）。
        // [EN] Kept exactly as before: without a colon, which UIKit does not answer, so taps take the library's own
        //      `_cyltabBarItemClicked:` below, which also updates the plus button's selection. With the colon, UIKit's handler
        //      ran instead and a selected plus button stayed selected after another tab was tapped (found in step 50).
        // [CN] 与以前完全一致：不带冒号，UIKit 不会响应，因此点击走下面本库的 `_cyltabBarItemClicked:`，它同时更新 PlusButton 的选中状态。
        //      带冒号时会改走 UIKit 的方法，选中的 PlusButton 在点击其他 Tab 后仍保持选中（第 50 步中发现）。
        let systemSelector = NSSelectorFromString("_tab" + "BarItem" + "Clicked")
        var systemItem = item.childViewController?.tabBarItem
        if let candidate = systemItem, !(owningTabBarController.tabBar.items ?? []).contains(candidate) {
            systemItem = nil
        }
        if let systemItem, owningTabBarController.responds(to: systemSelector) {
            _ = owningTabBarController.perform(systemSelector, with: systemItem)
            return
        }
        // [CN] 容错处理, 防止版本系统修改方法名称
        // [EN] Fault tolerance, in case a system version renames the method
        let customSelector = NSSelectorFromString("_cyltabBarItemClicked:")
        if owningTabBarController.responds(to: customSelector) {
            _ = owningTabBarController.perform(customSelector, with: item)
        } else {
            cylSetSelectedIndex(selectedIndex)
        }
    }

    private func cylReloadItems() {
        let storage = cylFlatDesignStorage
        storage.buttons.forEach { $0.removeFromSuperview() }
        storage.buttons.removeAll()
        let selectedItem = cylFlatDesignSelectedItem()
        for item in storage.items ?? [] {
            let button = CYLFlatDesignTabBarButton(tabBarItem: item)
            button.tintColor = storage.tintColor
            button.isSelected = (item === selectedItem)
            button.addTarget(self, action: #selector(cylTabBarDidSelectButton(_:)), for: .touchUpInside)
            // [EN] The pressed animation, forwarded to the tab bar controller at touch time (it may not be set yet here).
            // [CN] 按下动画，在触摸时转给 TabBarController（此时可能尚未设置）。
            button.addTarget(self, action: #selector(cylTabBarDidTouchDownButton(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(cylTabBarDidTouchUpButton(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            button.clipsToBounds = false
            storage.contentView.insertSubview(button, at: 0)
            storage.buttons.append(button)
        }
        // [EN] A different item may be selected now. [CN] 现在选中的可能是另一个 item。
        cylUpdateAppearanceIfNeeded()
        setNeedsLayout()
    }

    private func cylSetSelectedIndex(_ selectedIndex: Int) {
        let storage = cylFlatDesignStorage
        guard storage.selectedItemIndex != selectedIndex else { return }
        // [EN] Animations are reset through this notification. [CN] 通过该通知统一重置动画。
        NotificationCenter.default.post(name: .CYLTabBarItemAnimationPlaying, object: self)
        storage.selectedItemIndex = selectedIndex
        for (index, button) in storage.buttons.enumerated() {
            button.isSelected = (index == selectedIndex)
        }
        // [EN] The newly selected item may bring its own appearance. [CN] 新选中的 item 可能有自己的 appearance。
        cylUpdateAppearanceIfNeeded()
    }

    // MARK: - [EN] Layout [CN] 布局

    private func cylUpdateLayout() {
        guard !bounds.isEmpty else { return }
        let storage = cylFlatDesignStorage
        storage.backgroundView.frame = bounds
        storage.backgroundImageView.frame = storage.backgroundView.bounds
        storage.backgroundEffectView?.frame = storage.backgroundView.bounds

        // [CN] 像素比例取自当前 trait，而非 UIScreen.mainScreen（iPhone Duo 内外屏可能不同）
        // [EN] The pixel scale comes from the current trait, not UIScreen.mainScreen (the iPhone Duo's screens may differ).
        let displayScale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 1
        let hairlineHeight = 1 / displayScale
        let backgroundWidth = storage.backgroundView.frame.width
        if let shadowImageView = storage.shadowImageView {
            var shadowHeight = hairlineHeight
            // [EN] An appearance's shadow image keeps its own height, as on `UITabBar`. [CN] appearance 的阴影图片保持自身高度，与 `UITabBar` 相同。
            if storage.appliedAppearance != nil, let imageHeight = shadowImageView.image?.size.height, imageHeight > 0 {
                shadowHeight = imageHeight
            }
            shadowImageView.frame = CGRect(x: 0, y: -shadowHeight, width: backgroundWidth, height: shadowHeight)
        }
        storage.appearanceShadowLineView?.frame = CGRect(x: 0, y: -hairlineHeight, width: backgroundWidth, height: hairlineHeight)

        let layoutInsets = cylSafeAreaInsetsForLayout()
        storage.contentView.frame = CGRect(x: 0, y: 0, width: frame.width, height: bounds.height - layoutInsets.bottom)

        let items = storage.items ?? []
        let itemCount = items.count
        guard itemCount > 0, storage.buttons.count == itemCount else { return }

        let buttonInsets = cylHorizontalButtonInsets(from: layoutInsets)
        let contentWidth = storage.contentView.frame.width - buttonInsets.left - buttonInsets.right
        var margin: CGFloat = 0
        var buttonSpace: CGFloat = 0
        let buttonY: CGFloat = 0
        let count = CGFloat(itemCount)
        var buttonWidth = itemCount == 1 ? contentWidth - margin * 2 : (contentWidth - margin * 2 - (count - 1) * buttonSpace) / count
        // [EN] `UITabBarAppearance.stackedItemPositioning == .centered`: items of `stackedItemWidth` (or an equal share), spaced
        //      by `stackedItemSpacing`, centered; when they do not fit, they fill the width as before.
        // [CN] `stackedItemPositioning` 为 `.centered` 时：item 宽度为 `stackedItemWidth`（或平分宽度），间距为 `stackedItemSpacing`，整体居中；
        //      放不下时与之前一样铺满宽度。
        if let appearance = cylEffectiveAppearance, appearance.stackedItemPositioning == .centered {
            let centeredSpace = max(appearance.stackedItemSpacing, 0)
            let centeredWidth = appearance.stackedItemWidth > 0 ? appearance.stackedItemWidth : (contentWidth - (count - 1) * centeredSpace) / count
            let totalWidth = count * centeredWidth + (count - 1) * centeredSpace
            if centeredWidth > 0 && totalWidth <= contentWidth {
                buttonWidth = centeredWidth
                buttonSpace = centeredSpace
                margin = (contentWidth - totalWidth) / 2
            }
        }
        let buttonHeight = storage.contentView.frame.height - buttonY
        let isRightToLeft = cyl_isRightToLeftLayout()
        for (index, button) in storage.buttons.enumerated() {
            button.tabBarItem = items[index]
            // [CN] RTL（如阿语）下按钮从右到左排列，第 0 个 Tab 位于最右侧
            // [EN] In RTL (e.g. Arabic), buttons are laid out right to left, and tab 0 is on the far right.
            let visibleIndex = CGFloat(isRightToLeft ? itemCount - 1 - index : index)
            let buttonX = margin + visibleIndex * (buttonWidth + buttonSpace) + buttonInsets.left
            button.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        }
        if cylFlatDesignHasPlusButton() {
            cylLayoutPlusButton()
        }
    }

    private func cylLayoutPlusButton() {
        guard let plusButton = CYLPlusButton(forOwner: self) else { return }
        let storage = cylFlatDesignStorage
        let tabBarHeight = storage.contentView.frame.height
        let centerYOffset = plusButton.constantOfPlusButtonCenterYOffset(forTabBarHeight: tabBarHeight)
        plusButton.layer.contentsGravity = CALayerContentsGravity.center
        if let scale = CYLGetRootWindow()?.windowScene?.screen.scale {
            plusButton.layer.contentsScale = scale
        }
        storage.plusButton = plusButton
        // FIX: issue #610 — a plus button without a child view controller has no action here: report its taps through
        // `tabBarController:didSelectControl:` too. 没有子控制器的 PlusButton 在这里没有事件：同样回调 `tabBarController:didSelectControl:`。
        let tapSelector = NSSelectorFromString("cyl_flatDesignPlusButtonTouchUpInside:")
        if let controller = cylFlatDesignOwningTabBarController as? CYLTabBarController,
           CYLPlusButton.plusChildViewController(forOwner: controller) == nil, controller.responds(to: tapSelector) {
            plusButton.removeTarget(controller, action: tapSelector, for: .touchUpInside)
            plusButton.addTarget(controller, action: tapSelector, for: .touchUpInside)
        }
        // [EN] Never index past this tab bar's own buttons: the plus button index comes from the tab items count, which may
        //      describe another tab bar or be stale while the items change.
        // [CN] 不能越过本 TabBar 自己的按钮取下标：PlusButton 的 index 来自 Tab 数量，可能描述的是另一个 TabBar，或在 items 变化时已过期。
        let plusButtonIndex = Int(cyl_plusButtonIndex())
        guard plusButtonIndex < storage.buttons.count else { return }
        let placeholder = storage.buttons[plusButtonIndex]
        guard placeholder.tabBarItem != nil else { return }
        // FIX: issue #662 — the plus button is placed by frame (`CYLTabButtonLayoutTracker`); keep it out of Auto Layout, or
        // a later layout pass could restore a stale frame (after the iPhone Duo was folded, it moved down).
        // 加号按钮由 frame 定位（`CYLTabButtonLayoutTracker`）；不能让它进入无约束的 Auto Layout，否则之后的布局可能恢复旧 frame
        // （iPhone Duo 折叠后加号按钮会下移）。
        plusButton.translatesAutoresizingMaskIntoConstraints = true
        placeholder.cyl_coverVisiableTabImageViewOrTabButton(true, contentNewView: plusButton, seclectContentNewView: plusButton,
                                                             offset: UIOffset(horizontal: 0, vertical: centerYOffset), show: true,
                                                             delayIfNeededForSeconds: 0.1) { _, tabBarButton, newView in
            newView.layoutIfNeeded()
            tabBarButton.cyl_isPlaceholder = true
        }
    }

    /**
     * FIX: issue #672
     * [EN] Left/right insets the button row keeps clear of. A vertical status bar (folded iPhone Duo held upright) insets one
     *      side only, a landscape notch both; the one-sided inset is ignored unless `respectsVerticalStatusBarSafeArea`.
     * [CN] 按钮行需要避开的左右安全区。竖向状态栏（iPhone Duo 折叠且竖屏）只在一侧产生安全区，横屏刘海两侧都有；除非
     *      `respectsVerticalStatusBarSafeArea` 为 YES，否则忽略单侧安全区。
     */
    private func cylHorizontalButtonInsets(from safeAreaInsets: UIEdgeInsets) -> UIEdgeInsets {
        let storage = cylFlatDesignStorage
        guard storage.useLayoutSafeAreaInsets else { return .zero }
        let isOneSided = (safeAreaInsets.left > 0) != (safeAreaInsets.right > 0)
        if isOneSided && !storage.respectsVerticalStatusBarSafeArea {
            return .zero
        }
        return UIEdgeInsets(top: 0, left: safeAreaInsets.left, bottom: 0, right: safeAreaInsets.right)
    }

    /**
     * FIX: issue #662 (push / pop follow-up, PR #665)
     * [EN] Safe area insets for the content. During a FlatDesign push / pop the bar sits in
     *      `_CYLFlatDesignTabBarParallaxOverlayView` on a page that carries the tab bar height as extra bottom inset, so the
     *      bar's own inset grew to its whole height and the content collapsed; there the insets are read live from the tab
     *      bar controller's view, the bar's home.
     * [CN] 内容使用的安全区。扁平样式 push / pop 期间 TabBar 位于页面上的 `_CYLFlatDesignTabBarParallaxOverlayView` 中，该页面带有等于
     *      TabBar 高度的额外底部 inset，TabBar 自身的 inset 变成整个高度，内容被压缩；此时实时读取其原宿主 TabBarController.view 的安全区。
     */
    private func cylSafeAreaInsetsForLayout() -> UIEdgeInsets {
        if superview is _CYLFlatDesignTabBarParallaxOverlayView,
           let homeView = cylFlatDesignOwningTabBarController?.viewIfLoaded, homeView.window != nil {
            let homeInsets = homeView.safeAreaInsets
            return UIEdgeInsets(top: 0, left: homeInsets.left, bottom: min(homeInsets.bottom, bounds.height), right: homeInsets.right)
        }
        return UIEdgeInsets(top: 0, left: safeAreaInsets.left, bottom: safeAreaInsets.bottom, right: safeAreaInsets.right)
    }

    // MARK: - [EN] Animations [CN] 动画

    /**
     * FIX: issue #604
     * [EN] Stops the animations of every tab, whatever their library.
     * [CN] 停止所有 Tab 的动画，与动画库无关。
     */
    @objc(stopAllTabBarItemAnimations)
    func cylStopAllTabBarItemAnimations() {
        guard CYLTabBarItemAnimationCore.service != nil else { return }
        cylFlatDesignStorage.buttons.forEach { $0.cyl_stopTabBarItemAnimation() }
    }

    /// [EN] Kept for compatibility; any animation library (#604). [CN] 为兼容而保留；适用于任意动画库（#604）。
    @objc(stopAnimationOfAllLottieView)
    func cylStopAnimationOfAllLottieView() {
        cylStopAllTabBarItemAnimations()
    }

    // MARK: - [EN] Touches [CN] 触摸

    /**
     * [EN] `-hitTest:withEvent:`. The plus button first (its interactive subviews, #202; its touchable area in this bar's
     *      coordinates, #91), then the tab buttons (their frame, or an image that sticks out of the bar), then super and
     *      the subviews; it never returns nil where super would not.
     * [CN] `-hitTest:withEvent:`。先处理 PlusButton（其可交互子视图，#202；其可点击区域按本 TabBar 坐标计算，#91），再处理 Tab 按钮（其
     *      frame，或超出 TabBar 的图片），最后交给 super 与子视图；super 不返回 nil 时不会返回 nil。
     */
    @objc(cyl_flatDesignHitTest:withEvent:)
    func cylFlatDesignHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // [CN] 1. 边界情况：不能响应点击事件 [EN] 1. Edge case: cannot respond to tap events
        if cyl_canNotResponseEvent() {
            return super.hitTest(point, with: event)
        }
        // [CN] 2.1 clipsToBounds：子 view 超出部分没有显示出来 [EN] 2.1 clipsToBounds: parts outside the bounds are not shown
        if clipsToBounds && !self.point(inside: point, with: event) {
            return super.hitTest(point, with: event)
        }
        let storage = cylFlatDesignStorage
        if let plusButton = storage.plusButton {
            // FIX: issue #202 — a subview of the plus button that takes touches gets them first.
            // PlusButton 中自己接收触摸的子视图优先获得触摸。
            let cylPlusButton = plusButton as? CYLPlusButton
            if let cylPlusButton, let subview = cylPlusButton.hitTestInteractiveSubview(cylPlusButton.convert(point, from: self), with: event) {
                return subview
            }
            // FIX: issue #91 — `-touchableRect` is in the plus button's superview coordinates.
            // `-touchableRect` 位于 PlusButton 父视图坐标系。
            let touchableFrame: CGRect
            if let cylPlusButton {
                touchableFrame = cylPlusButton.touchableRect(in: self)
            } else {
                let touchableRect = (plusButton as? CYLPlusButtonSubclassing)?.touchableRect?() ?? plusButton.frame
                touchableFrame = plusButton.superview.map { $0.convert(touchableRect, to: self) } ?? touchableRect
            }
            // [EN] With a plus child view controller, a touch inside the bar goes to the tab button under the plus button; a
            //      touch in the part of the area outside the bar goes to the plus button (#91).
            // [CN] 有 PlusButton 子控制器时，TabBar 内的点击交给 PlusButton 下方的 Tab 按钮；可点击区域中位于 TabBar 之外的部分交给 PlusButton（#91）。
            let isOutsideBar = !self.point(inside: point, with: event)
            if touchableFrame.contains(point) && (!cylFlatDesignHasPlusChildViewController() || isOutsideBar) {
                return plusButton
            }
            if let plusSuperview = plusButton.superview, plusSuperview.frame.contains(point), plusSuperview.cyl_isPlaceholder,
               plusSuperview.cyl_canNotResponseEvent(), !plusButton.cyl_canNotResponseEvent() {
                // [CN] 防止误触PlusButton轮廓外， 且在tabBarButton范围内，否则会切换到空白 placeholder vc 上。
                // [EN] Prevent taps outside the plus button but inside its tab button from switching to the blank placeholder page.
                return plusButton
            }
        }
        for button in storage.buttons {
            // [CN] 如果imageView超出TabBar范围，增加imageView响应区域 [EN] An image view that sticks out of the bar takes touches too
            let imageRect = button.actualBadgeSuperView().convert(button.imageView.bounds, to: self)
            if (button.frame.contains(point) || imageRect.contains(point)) && !button.cyl_canNotResponseEvent() {
                return button
            }
        }
        // [CN] 3. 最后处理 TabBarItems 凸出的部分、自定义视图、空白区域
        // [EN] 3. Finally the protruding parts of the tab items, custom views and empty areas
        if let result = super.hitTest(point, with: event) {
            return result
        }
        for subview in subviews.reversed() {
            if let result = subview.hitTest(subview.convert(point, from: self), with: event) {
                return result
            }
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - [EN] Plus button [CN] PlusButton

    /**
     * [EN] A standalone tab bar: one the app added to a page by itself, not the tab bar of a CYLTabBarController (whose
     *      `delegate` is that controller). It must not take the controller's plus button: its index belongs to the other bar
     *      ("index 2 beyond bounds [0 .. 1]"), and the shared plus button would leave the controller's own bar.
     * [CN] 独立 TabBar：App 自己添加到页面上的 TabBar，而不是某个 CYLTabBarController 的 TabBar（其 `delegate` 就是该控制器）。它不能拿走
     *      控制器的 PlusButton：其 index 属于另一个 TabBar（"index 2 beyond bounds [0 .. 1]"），共享的 PlusButton 也会被移出控制器自己的 TabBar。
     */
    @objc(cyl_isStandaloneTabBar)
    func cylIsStandaloneTabBar() -> Bool {
        if cylFlatDesignStorage.delegate is CYLTabBarController {
            return false
        }
        // [EN] Not inside any CYLTabBarController (not attached yet): keep the context lookup.
        // [CN] 不在任何 CYLTabBarController 中（尚未挂上）：保留按 context 查找。
        return cylOwningTabBarController() != nil
    }

    @objc(cyl_flatDesignHasPlusButton)
    func cylFlatDesignHasPlusButton() -> Bool {
        // [EN] Bound to the CYLTabBarController that owns this tab bar, see `-[CYLTabBar hasPlusButton]`.
        // [CN] 绑定的是拥有本 TabBar 的 CYLTabBarController，见 `-[CYLTabBar hasPlusButton]`。
        !cylIsStandaloneTabBar() && CYLPlusButton(forOwner: self) != nil
    }

    @objc(cyl_flatDesignHasPlusChildViewController)
    func cylFlatDesignHasPlusChildViewController() -> Bool {
        !cylIsStandaloneTabBar() && CYLPlusButton.plusChildViewController(forOwner: self) != nil
    }
}
