//
//  MainTabBarController.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit
class MainTabBarController: CYLTabBarController {
    
    // MARK: - Your main designated initializer
    override init(
        viewControllers: [UIViewController],
        tabBarItemsAttributes: [[AnyHashable: Any]],
        imageInsets: UIEdgeInsets,
        titlePositionAdjustment: UIOffset,
        context: String
    ) {
        super.init(
            viewControllers: viewControllers,
            tabBarItemsAttributes: tabBarItemsAttributes,
            imageInsets: imageInsets,
            titlePositionAdjustment: titlePositionAdjustment,
            context: context
        )
    }
    // The ObjC initializer above forwards to this one via `self`, so a Swift subclass
    // must override it too, otherwise: "Use of unimplemented initializer".
    override init(
        viewControllers: [UIViewController],
        tabBarItemsAttributes: [[AnyHashable: Any]],
        imageInsets: UIEdgeInsets,
        titlePositionAdjustment: UIOffset,
        styleType: CYLTabBarStyleType,
        context: String
    ) {
        super.init(
            viewControllers: viewControllers,
            tabBarItemsAttributes: tabBarItemsAttributes,
            imageInsets: imageInsets,
            titlePositionAdjustment: titlePositionAdjustment,
            styleType: styleType,
            context: context
        )
    }
    convenience init(context: String = "") {
        let imageInsets = UIEdgeInsets.zero
        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
        
        self.init(viewControllers: Self.makeViewControllers(), tabBarItemsAttributes: Self.makeTabBarItemsAttributes(), imageInsets: imageInsets, titlePositionAdjustment: titlePositionAdjustment, context: context)
    }
    // MARK: - REQUIRED by UIKit (🔥 Fix here)
    // Must only forward to super: CYLTabBarController's designated initializer calls
    // `[super init]`, which UIKit routes back here via `initWithNibName:bundle:`.
    // Calling `super.init(viewControllers:...)` from here recurses until the stack overflows.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: - REQUIRED
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarStyleType = .liquidGlass

        UIApplication.shared.applicationSupportsShakeToEdit = true
        self.becomeFirstResponder()
        setUpIssue610Demo()
    }

    // MARK: - Issue #610 demo
    // [EN] Issue #610: after replacing `tabBarItem.image` / `selectedImage` at runtime, tapping a tab no longer
    //      called `tabBarController(_:didSelectControl:)`. Tap "Swap icons" (top right), then tap any tab:
    //      the counter at the top must increase on every tap, including a tap on the selected tab.
    // [CN] Issue #610：运行时替换 `tabBarItem.image` / `selectedImage` 后，点击 Tab 不再回调
    //      `tabBarController(_:didSelectControl:)`。点右上角 "Swap icons"，再点任意 Tab：
    //      顶部计数每次点击都要增加，包括点击已选中的 Tab。
    private static let issue610IconSets: [[(normal: String, selected: String)]] = [
        [("home_normal", "home_highlight"), ("mycity_normal", "mycity_highlight"),
         ("message_normal", "message_highlight"), ("account_normal", "account_highlight")],
        [("account_normal", "account_highlight"), ("message_normal", "message_highlight"),
         ("mycity_normal", "mycity_highlight"), ("home_normal", "home_highlight")],
    ]
    private var issue610IconSetIndex = 0
    private var issue610CallbackCount = 0
    private let issue610Label = UILabel()

    private func setUpIssue610Demo() {
        // `tabBarController(_:didSelectControl:)` is a CYLTabBarControllerDelegate method; without a delegate it is never called.
        delegate = self
        issue610Label.translatesAutoresizingMaskIntoConstraints = false
        issue610Label.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        issue610Label.textAlignment = .center
        issue610Label.numberOfLines = 0
        issue610Label.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.85)
        issue610Label.accessibilityIdentifier = "issue610Label"
        issue610Label.text = "#610 didSelectControl: 0"
        view.addSubview(issue610Label)
        NSLayoutConstraint.activate([
            issue610Label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            issue610Label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            issue610Label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Swap icons", style: .plain,
                                                            target: self, action: #selector(issue610SwapIcons))
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-CYL610Landscape"), #available(iOS 16.0, *) {
            // Rotate before the test so it also covers the landscape tab bar layout.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
            }
        }
        if arguments.contains("-CYL610SelfTest") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.issue610RunSelfTest() }
        }
    }

    /// Launch with `-CYL610SelfTest` to run the #610 check without touching the screen. It swaps the icons, lets
    /// only the tab bar lay out (what UIKit does after an item's image changes), then sends `.touchUpInside` to every
    /// tab button (what a finger tap delivers to a classic, non Liquid Glass tab button) before anything lays out the
    /// controller's view again, and logs whether each tap produced a `didSelectControl` callback.
    private func issue610RunSelfTest() {
        if CYLConstants.isLiquidGlassActive() {
            issue610RunLiquidGlassSelfTest()
            return
        }
        let before = issue610TabControls()
        let baseline = issue610Tap(before)
        NSLog("[#610] self-test before the icon swap, callback per tap: %@", baseline)
        issue610SwapIcons()
        tabBar.layoutIfNeeded()
        let after = issue610TabControls()
        let replaced = zip(before, after).filter { $0 !== $1 }.count
        let bound = issue610Bound(after)
        let afterSwap = issue610Tap(after)
        let result = (baseline + bound + afterSwap).contains("0") ? "FAIL" : "PASS"
        let orientation = view.bounds.width > view.bounds.height ? "landscape" : "portrait"
        NSLog("[#610] self-test %@ (classic, %@): UIKit replaced %ld of %ld tab buttons; tap action bound per button: %@; callback per tap: %@",
              result, orientation, replaced, after.count, bound, afterSwap)
    }

    /// Liquid Glass tab buttons take no target-action: a tap makes UIKit call `selectedViewController`'s setter, where
    /// CYLTabBarController reports `didSelectControl`. Do the same for every tab after the icon swap.
    private func issue610RunLiquidGlassSelfTest() {
        issue610SwapIcons()
        tabBar.layoutIfNeeded()
        let tabs = (viewControllers ?? []).filter { !$0.cyl_isPlaceholder }
        let perTab = tabs.map { viewController -> String in
            let count = issue610CallbackCount
            selectedViewController = viewController
            return issue610CallbackCount > count ? "1" : "0"
        }.joined(separator: " ")
        let orientation = view.bounds.width > view.bounds.height ? "landscape" : "portrait"
        NSLog("[#610] self-test %@ (Liquid Glass, %@): callback per tab selected after the icon swap: %@",
              perTab.contains("0") ? "FAIL" : "PASS", orientation, perTab)
    }

    /// Tab buttons that report taps through CYLTabBarController's target-action. The plus button and the plus child
    /// view controller's button report through the plus button instead, so they are left out.
    private func issue610TabControls() -> [UIControl] {
        guard let cylTabBar = tabBar as? CYLTabBar else { return [] }
        return cylTabBar.cyl_visibleControls().filter { !$0.cyl_isPlusControl() }
    }

    /// "1" / "0" per control: does it carry CYLTabBarController's tap action right now?
    private func issue610Bound(_ controls: [UIControl]) -> String {
        controls.map { ($0.actions(forTarget: self, forControlEvent: .touchUpInside) ?? []).isEmpty ? "0" : "1" }
            .joined(separator: " ")
    }

    /// Taps each control in turn and returns "1" / "0" per tap: did `didSelectControl` arrive?
    private func issue610Tap(_ controls: [UIControl]) -> String {
        controls.map { control -> String in
            let count = issue610CallbackCount
            control.sendActions(for: .touchUpInside)
            return issue610CallbackCount > count ? "1" : "0"
        }.joined(separator: " ")
    }


    /// Replaces the icons the way the reporter did: directly on `tabBar.items`, after the controller was built
    /// with `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`.
    @objc private func issue610SwapIcons() {
        issue610IconSetIndex = (issue610IconSetIndex + 1) % Self.issue610IconSets.count
        let icons = Self.issue610IconSets[issue610IconSetIndex]
        // `tabBar.items` also holds the plus button's item; skip it.
        let items = (viewControllers ?? [])
            .filter { !$0.cyl_isPlaceholder && $0 !== CYLPlusChildViewController }
            .map { $0.tabBarItem! }
        for (index, item) in items.enumerated() where index < icons.count {
            item.image = UIImage(named: icons[index].normal)
            item.selectedImage = UIImage(named: icons[index].selected)
        }
        NSLog("[#610] swapped tab bar icons to set %ld", issue610IconSetIndex)
    }

    override func tabBarController(_ tabBarController: CYLTabBarController, didSelect control: UIControl) {
        issue610CallbackCount += 1
        let index = selectedIndex
        issue610Label.text = "#610 didSelectControl: \(issue610CallbackCount) (index \(index))"
        view.bringSubviewToFront(issue610Label)
        NSLog("[#610] didSelectControl #%ld index %ld control %@", issue610CallbackCount, index, control)
    }
    
    
    
}

// MARK: - Delegate
extension MainTabBarController {
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        super.tabBarController(tabBarController, shouldSelect: viewController)
        return true
    }
    
    override func tabBarController(_ tabBarController: CYLTabBarController, shouldShowPlatterLiquidLensViewFor control: UIControl) -> Bool {
//        return super.tabBarController(tabBarController, shouldShowPlatterLiquidLensViewFor: control)
        return true
    }
    
    static func makeViewControllers() -> [UIViewController] {
        let home =  HomeViewController()
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal = UINavigationController(rootViewController: PersonalViewController())

        return [home, connection, message, personal]
    }

    static func makeTabBarItemsAttributes() -> [[AnyHashable: Any]] {

        let tabBarItemOne = [
            CYLTabBarItemTitle: "首页",
            CYLTabBarItemImage: "home_normal",
            CYLTabBarItemSelectedImage: "home_highlight"
        ]

        let tabBarItemTwo = [
            CYLTabBarItemTitle: "鱼塘",
            CYLTabBarItemImage: "fishpond_normal",
            CYLTabBarItemSelectedImage: "fishpond_highlight"
        ]

        let tabBarItemThree = [
            CYLTabBarItemTitle: "消息",
            CYLTabBarItemImage: "message_normal",
            CYLTabBarItemSelectedImage: "message_highlight"
        ]

        let tabBarItemFour = [
            CYLTabBarItemTitle: "我的",
            CYLTabBarItemImage: "account_normal",
            CYLTabBarItemSelectedImage: "account_highlight"
        ]

        return [tabBarItemOne, tabBarItemTwo, tabBarItemThree, tabBarItemFour]
    }
}
