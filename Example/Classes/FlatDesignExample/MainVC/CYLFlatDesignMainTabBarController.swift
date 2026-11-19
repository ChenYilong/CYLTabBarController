//
//  CYLFlatDesignMainTabBarController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The key of the spring animation on a tapped tab icon. [CN] 被点击 Tab 图标上弹簧动画的键。
private let CYLSpringAnimationKey = "CYLSpringAnimationKey"

/**
 [EN] The FlatDesign demo tab bar controller, ported to Swift (docs/Swift-Migration.md, step 111): `CYLTabBarController` becomes
      an `open` Swift class in phase ②, which Objective-C cannot subclass. It shows the delegate APIs (login #19, gestures #152)
      where MainTabBarController shows the block APIs. Objective-C files use it through `CYLTabBarControllerDemo-Swift.h`.
 [CN] 扁平样式 Demo 的 TabBarController，已改写为 Swift（docs/Swift-Migration.md，第 111 步）：第 ② 阶段 `CYLTabBarController` 将成为 Objective-C
      无法继承的 `open` Swift 类。它演示代理方式（登录 #19、手势 #152），MainTabBarController 演示 block 方式。Objective-C 文件通过
      `CYLTabBarControllerDemo-Swift.h` 使用它。
 */
@objc(CYLFlatDesignMainTabBarController)
class CYLFlatDesignMainTabBarController: CYLTabBarController, CYLFlatDesignUITabBarControllerDelegate {

    /// [EN] The covers of the first tab, kept so a second decoration moves them. [CN] 第一个 Tab 的封面，保留下来，再次装饰时只移动它们。
    private var contentCover: UIButton?
    private var selectedContentCover: UIButton?

    /**
     [EN] A FlatDesign tab bar controller of these tabs, for a context. [CN] 由这些 Tab 组成的扁平样式 TabBarController，对应一个 context。
     */
    @objc(initWithViewControllers:tabBarItemsAttributes:context:)
    convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[String: Any]], context: String) {
        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: .zero,
                   titlePositionAdjustment: titlePositionAdjustment, styleType: .flatDesign, context: context)
        // [EN] One UITabBarAppearance for every style: the same as MainTabBarController's, mapped onto the FlatDesign tab bar.
        // [CN] 所有样式共用一个 UITabBarAppearance：与 MainTabBarController 的相同，映射到扁平样式 TabBar。
        tabBar.standardAppearance = MainTabBarController.demoStandardAppearance(titlePositionAdjustment: titlePositionAdjustment)
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// [EN] The required designated initializer (see MainTabBarController). [CN] 必需的指定初始化方法（见 MainTabBarController）。
    required init(configuration: [String: Any]) {
        super.init(configuration: configuration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] Issue #426: unload the unselected tabs' views on a memory warning. [CN] Issue #426：内存警告时卸载未选中 Tab 的视图。
        unloadsUnselectedViewsOnMemoryWarning = true
        delegate = self
        customizeInterface()
        // [EN] Used only while no `standardAppearance` is set. [CN] 仅在没有设置 `standardAppearance` 时使用。
        if let flatTabBar = cyl_tabBar as? CYLFlatDesignTabBar {
            flatTabBar.barTintColor = .systemBackground
            flatTabBar.shadowImage = UIImage.cyl_image(with: UIColor.lightGray.withAlphaComponent(0.5), size: CGSize(width: 1, height: 1))
        }
    }

    /// [EN] Issue #428: 1.5 times as fast, as in the other styles. [CN] Issue #428：1.5 倍速，与其他样式一致。
    override var tabBarItemAnimationSpeed: CGFloat {
        get { 1.5 }
        set { super.tabBarItemAnimationSpeed = newValue }
    }

    // MARK: - CYLFlatDesignUITabBarControllerDelegate

    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // [EN] #19: this override does not call super, so it asks for the login check itself.
        // [CN] #19：此重写没有调用 super，因此自行调用登录检查。
        if cyl_interceptLoginIfNeeded(for: viewController) {
            return false
        }
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return true }
        if let flatTabBar = cyl_tabBar as? CYLFlatDesignTabBar, index < flatTabBar.tabBarButtons.count {
            springAnimation(on: flatTabBar.tabBarButtons[index].imageView)
        }
        // [EN] The middle tab opens a modal page instead (`-tabBar:didSelectItem:`). [CN] 中间的 Tab 改为打开模态页面（`-tabBar:didSelectItem:`）。
        return index != 2
    }

    /// [EN] #19, delegate API: the last two tabs need login (the tabs share one class, so by position). [CN] #19 代理方式：最后两个 Tab 需要登录（按位置判断）。
    override func tabBarController(_ tabBarController: CYLTabBarController, requiresLoginToSelect viewController: UIViewController) -> Bool {
        guard let viewControllers = tabBarController.viewControllers, let index = viewControllers.firstIndex(of: viewController) else { return false }
        return viewControllers.count >= 2 && index >= viewControllers.count - 2
    }

    override func tabBarController(_ tabBarController: CYLTabBarController, presentLoginFor viewController: UIViewController,
                          completion: @escaping @Sendable (Bool) -> Void) {
        tabBarController.cyl_demo_presentLogin(for: viewController, completion: completion)
    }

    /// [EN] #152: the delegate API of the tab item gestures. [CN] #152：TabBarItem 手势的代理方式。
    override func tabBarController(_ tabBarController: CYLTabBarController, didRecognize gesture: CYLTabBarItemGesture, control: UIControl,
                          viewController: UIViewController?) {
        guard let viewController else { return }
        tabBarController.cyl_demo_handleTabBarItemGesture(gesture, control: control, viewController: viewController)
    }

    override func tabBarController(_ tabBarController: UITabBarController, didSelect control: UIControl) {
        guard let tabBarController = tabBarController as? CYLTabBarController else { return }
        #if DEBUG
        // [EN] #610 / #408: every tab button and the plus button report here; the identifier tells which.
        // [CN] #610 / #408：每个 Tab 按钮和 PlusButton 都会回调；用标识区分。
        NSLog("🟢 #610 flat design tapped \"%@\" (%@)", control.cyl_tabBarItemIdentifier ?? "", control.cyl_isPlusButton() ? "plus button" : "tab button")
        #endif
        // [EN] #535: the plus button's badge changes on every tap; checked first. [CN] #535：每次点击 PlusButton 角标都会变化；需先判断。
        let isPlusControl = tabBarController.hasPlusButton() && control.cyl_isPlusControl()
        if isPlusControl {
            tabBarController.cyl_demo_plusButtonDidTap()
        } else if control.cyl_isTabButton() {
            // [EN] Toggle the red dot. [CN] 切换红点。
            let isFlatDesign = tabBarController.tabBarStyleType == .flatDesign
            if control.cyl_isShowBadge() {
                if isFlatDesign {
                    control.cyl_clearBadge()
                } else {
                    tabBarController.selectedViewController?.cyl_clearBadge()
                }
            } else if isFlatDesign {
                control.cyl_showBadgeValue("", animationType: .scaleOnce)
            } else {
                tabBarController.selectedViewController?.cyl_showBadge()
            }
        }
    }

    // MARK: - CYLFlatDesignTabBarDelegate

    /// [EN] The middle item opens a modal page; the last one turns the bar black. [CN] 中间的 item 打开模态页面；最后一个让 TabBar 变黑。
    override func tabBar(_ tabBar: CYLFlatDesignTabBar, didSelect item: CYLFlatDesignTabBarItem) {
        let index = tabBar.items?.firstIndex(of: item)
        if index == 2 {
            present(CYLFlatDesignModalViewController(), animated: true)
            return
        }
        let isBlackTheme = index == 4
        let titleTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: isBlackTheme ? UIColor.white : UIColor.gray]
        tabBar.barTintColor = isBlackTheme ? .black : .white
        for viewController in viewControllers ?? [] {
            viewController.cyl_tabBarItem?.setTitleTextAttributes(titleTextAttributes, for: .normal)
        }
    }

    func tabBarController(_ tabBarController: CYLTabBarController!, willShow tabBar: CYLFlatDesignTabBar!) {
        cyl_demo_log(#function)
    }

    func tabBarController(_ tabBarController: CYLTabBarController!, didShow tabBar: CYLFlatDesignTabBar!) {
        cyl_demo_log(#function)
    }

    func tabBarController(_ tabBarController: CYLTabBarController!, willHide tabBar: CYLFlatDesignTabBar!) {
        cyl_demo_log(#function)
    }

    func tabBarController(_ tabBarController: CYLTabBarController!, didHide tabBar: CYLFlatDesignTabBar!) {
        cyl_demo_log(#function)
    }

    private func cyl_demo_log(_ function: String) {
        #if DEBUG
        NSLog(cylDemoLocalizedString("🔴类名与方法名：%@（在第%@行）, 描述：%@"), function, "\(#line)", "")
        #endif
    }

    // MARK: - Decoration 装饰

    private func customizeInterface() {
        setViewDidLayoutSubViewsBlockInvokeOnce(true) { [weak self] tabBarController in
            // [EN] The delay only makes the badge animations easy to see. [CN] 延迟只是为了方便看清角标动画。
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard let self, let viewControllers = tabBarController.viewControllers, viewControllers.count >= 4 else { return }
                let first = viewControllers[0]
                first.cyl_badgeBackgroundColor = .cyl_randomColor
                first.cyl_badgeRadius = 11 / 2
                first.cyl_showBadgeValue("", animationType: .breathe)
                self.setSelectedCoverShow(true)
                viewControllers[1].cyl_badgeBackgroundColor = .cyl_randomColor
                viewControllers[1].cyl_showBadgeValue("", animationType: .scale)
                viewControllers[2].cyl_showBadgeValue("", animationType: .shake)
                viewControllers[3].cyl_showBadgeValue("100", animationType: .bounce)
                if viewControllers.count > 4 {
                    // [EN] Differs from the global offset. [CN] 与全局偏移不同。
                    viewControllers[4].cyl_badgeCenterOffset = CGPoint(x: -1, y: 3)
                    viewControllers[4].cyl_showBadgeValue("NEW", animationType: .breathe)
                }
                // [EN] #535: the plus button's badge; each tap adds 1. [CN] #535：PlusButton 的角标；每次点击加 1。
                tabBarController.cyl_demo_showPlusButtonBadge()
            }
        }
    }

    /// [EN] A cover over the selected first tab; decorative. [CN] 选中的第一个 Tab 上的封面；装饰性。
    private func makeSelectedCover() -> UIButton {
        let cover = UIButton(type: .custom)
        cover.accessibilityElementsHidden = true
        let image = UIImage(named: "home_select_cover")
        cover.setImage(image, for: .normal)
        cover.frame.size = image?.size ?? .zero
        cover.contentMode = .center
        cover.imageView?.contentMode = .scaleAspectFit
        cover.translatesAutoresizingMaskIntoConstraints = false
        cover.isUserInteractionEnabled = false
        cover.cyl_setHidden(false)
        return cover
    }

    /// [EN] Shows or hides the cover of the first tab. [CN] 显示或隐藏第一个 Tab 的封面。
    @objc(setSelectedCoverShow:)
    func setSelectedCoverShow(_ show: Bool) {
        guard let firstTabButton = viewControllers?.first?.cyl_tabButton else { return }
        if contentCover == nil {
            contentCover = makeSelectedCover()
            selectedContentCover = makeSelectedCover()
        }
        guard let contentCover, let selectedContentCover else { return }
        // [EN] A Lottie icon needs the delay. [CN] Lottie 图标需要延迟。
        firstTabButton.cyl_coverVisiableTabImageViewOrTabButton(true, contentNewView: contentCover, seclectContentNewView: selectedContentCover,
                                                                offset: .zero, show: show, delayIfNeededForSeconds: 0.5) { [weak self] isReplaced, _, newView in
            guard let self, isReplaced, show else { return }
            newView.layoutIfNeeded()
            self.viewControllers?.first?.cyl_clearBadge()
            // [EN] Liquid Glass has its own scale animation. [CN] 液态玻璃自带缩放动画。
            if !CYLConstants.isLiquidGlassActive() {
                newView.layer.add(CAAnimation.cyl_badge_once_scale_AnimationRepeatTimes(1, duration: 0.5), forKey: "animation")
            }
        }
    }

    // MARK: - Spring animation 弹簧动画

    private func springAnimation(on view: UIView?) {
        guard let view else { return }
        view.layer.removeAnimation(forKey: CYLSpringAnimationKey)
        view.layer.add(CAKeyframeAnimation.cyl_springAnimation(forDuration: 0.6), forKey: CYLSpringAnimationKey)
    }
}
