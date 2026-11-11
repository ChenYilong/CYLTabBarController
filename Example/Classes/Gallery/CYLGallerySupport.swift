//
//  CYLGallerySupport.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/**
 * [EN] Shared values and helpers of the tab bar gallery. [CN] TabBar 图库共用的值与辅助方法。
 */
enum CYLGallery {

    /**
     * [EN] The context of the gallery's tab bars: no plus button is registered for it. [CN] 图库 TabBar 的 context：没有为它注册 PlusButton。
     */
    static let context = "CYLGallery"
    /**
     * [EN] The context of the irregular scenes, with their own plus button. [CN] 不规则场景的 context，带有自己的 PlusButton。
     */
    static let irregularContext = "CYLGalleryIrregular"
    /**
     * [EN] The context of the plus button that has its own page (Liquid Glass stand-in scenes).
     * [CN] 拥有自己页面的 PlusButton 所属的 context（液态玻璃替身场景）。
     */
    static let plusPageContext = "CYLGalleryPlusPage"

    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }

    static func gray(_ white: CGFloat) -> UIColor {
        UIColor(white: white / 255, alpha: 1)
    }

    static func playKeyframes(on view: UIView?, keyPath: String, values: [Any], duration: CFTimeInterval) {
        guard let view else {
            return
        }
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        animation.duration = duration
        animation.calculationMode = .cubic
        view.layer.add(animation, forKey: nil)
    }

    /**
     * [EN] Eight tabs: title, SF Symbol and identifier. [CN] 八个 Tab：标题、SF Symbol 与标识。
     */
    static let tabSpecs: [(title: String, symbol: String, identifier: String)] = [
        ("Home", "house", "home"), ("Find", "safari", "find"), ("Photo", "camera", "photo"), ("Favor", "heart", "favor"),
        ("Me", "person", "me"), ("Message", "message", "message"), ("Shop", "cart", "shop"), ("Cardboard", "shippingbox", "cardboard"),
    ]

    /**
     * [EN] A template SF Symbol, so per-tab icon colors apply. [CN] 模板 SF Symbol，单个 Tab 的图标颜色可以生效。
     */
    static func symbol(_ name: String, filled: Bool, pointSize: CGFloat) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
        let image = UIImage(systemName: filled ? name + ".fill" : name, withConfiguration: configuration)
            ?? UIImage(systemName: name, withConfiguration: configuration)
            ?? UIImage()
        return image.withRenderingMode(.alwaysTemplate)
    }

    /**
     * [EN] The pages of a scene, optionally each in a navigation controller. [CN] 场景中的页面，可选地分别放进导航控制器。
     */
    static func pages(_ count: Int, embedsInNavigation: Bool) -> [UIViewController] {
        (0..<count).map { index in
            let page = CYLGalleryPageViewController()
            guard embedsInNavigation else {
                return page
            }
            page.title = (index == 3) ? "List" : tabSpecs[index].title
            return CYLGalleryNavigationController(rootViewController: page)
        }
    }

    /**
     * [EN] The attributes of `count` tabs. `showsTitles` false gives image-only tabs; `extra` adds keys per tab (colors,
     *      fonts...) and can return nil.
     * [CN] `count` 个 Tab 的属性。`showsTitles` 为 false 时为纯图标 Tab；`extra` 为每个 Tab 添加键（颜色、字体……），可以返回 nil。
     */
    static func attributes(_ count: Int, showsTitles: Bool, pointSize: CGFloat,
                           extra: ((Int) -> [String: Any]?)? = nil) -> [[String: Any]] {
        (0..<count).map { index in
            let spec = tabSpecs[index]
            var item: [String: Any] = [CYLTabBarItemImage: symbol(spec.symbol, filled: false, pointSize: pointSize),
                                       CYLTabBarItemSelectedImage: symbol(spec.symbol, filled: true, pointSize: pointSize),
                                       CYLTabBarItemIdentifier: spec.identifier]
            if showsTitles {
                item[CYLTabBarItemTitle] = spec.title
            }
            if let more = extra?(index) {
                item.merge(more) { _, new in new }
            }
            return item
        }
    }

    /**
     * [EN] The tabs of the icon rendering mode scenes (#787), with the example's own colored images.
     * [CN] 图标渲染方式场景（#787）的 Tab，使用示例自带的彩色图片。
     */
    static func iconRenderingAttributes() -> [[String: Any]] {
        [
            [CYLTabBarItemTitle: "Home", CYLTabBarItemImage: "home_normal", CYLTabBarItemIdentifier: "home",
             CYLTabBarItemIconRenderingMode: "template", CYLTabBarItemIconColor: UIColor.systemGray, CYLTabBarItemSelectedIconColor: UIColor.systemRed],
            [CYLTabBarItemTitle: "Video", CYLTabBarItemImage: symbol("play.rectangle", filled: false, pointSize: 20), CYLTabBarItemIdentifier: "video",
             CYLTabBarItemIconRenderingMode: "template"],
            [CYLTabBarItemTitle: "Fishpond", CYLTabBarItemImage: "fishpond_highlight", CYLTabBarItemIdentifier: "fishpond",
             CYLTabBarItemIconRenderingMode: "original", CYLTabBarItemIconColor: UIColor.systemGray],
            [CYLTabBarItemTitle: "Account", CYLTabBarItemImage: "account_highlight", CYLTabBarItemIdentifier: "account"],
        ]
    }

    /**
     * [EN] A tab bar controller that is its own delegate, so its `tabBarController(_:shouldSelect:)` runs the custom action
     *      (and login) checks before UIKit selects a tab, in every style.
     * [CN] 作为自己代理的 TabBarController，其 `tabBarController(_:shouldSelect:)` 会在 UIKit 选中 Tab 之前执行自定义操作（及登录）检查，
     *      适用于所有样式。
     */
    static func tabBarController(pages: [UIViewController], attributes: [[String: Any]], styleType: CYLTabBarStyleType,
                                 context: String) -> CYLTabBarController {
        let tabBarController = CYLTabBarController(viewControllers: pages, tabBarItemsAttributes: attributes, styleType: styleType, context: context)
        tabBarController.delegate = tabBarController as? (CYLTabBarControllerDelegate & CYLFlatDesignUITabBarControllerDelegate)
        return tabBarController
    }

    /**
     * [EN] The system UITabBarController, for comparison. [CN] 系统 UITabBarController，用于对照。
     */
    static func systemTabBarController(_ count: Int) -> UITabBarController {
        let tabBarController = UITabBarController()
        let pages = pages(count, embedsInNavigation: false)
        for (index, page) in pages.enumerated() {
            let spec = tabSpecs[index]
            page.tabBarItem = UITabBarItem(title: spec.title, image: symbol(spec.symbol, filled: false, pointSize: 20),
                                           selectedImage: symbol(spec.symbol, filled: true, pointSize: 20))
        }
        tabBarController.viewControllers = pages
        return tabBarController
    }

    /**
     * [EN] The dialog of a tab with a custom action; `dismissed` runs when any button closes it.
     * [CN] 执行自定义操作的 Tab 弹出的对话框；任一按钮关闭它时执行 `dismissed`。
     */
    static func presentMoreFeatures(from presenter: UIViewController?, dismissed: @escaping () -> Void) {
        guard let presenter, presenter.presentedViewController == nil else {
            dismissed()
            return
        }
        let handler: (UIAlertAction) -> Void = { _ in dismissed() }
        let alert = UIAlertController(title: "More features", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cylDemoLocalizedString("设置"), style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: cylDemoLocalizedString("关于我们"), style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel, handler: handler))
        presenter.present(alert, animated: true)
    }

    /**
     * [EN] Swaps the pages of the tabs at `first` and `second` while each tab keeps its title and icon, with
     *      `replaceViewController(at:with:attributes:)` (a spare page frees one slot first).
     * [CN] 交换 `first` 与 `second` 两个 Tab 的页面，各 Tab 保持自己的标题与图标（先用一个临时页面腾出一个位置）。
     */
    static func swapPages(of tabBarController: CYLTabBarController, _ first: Int, _ second: Int) -> Bool {
        let viewControllers = tabBarController.viewControllers ?? []
        guard first < viewControllers.count, second < viewControllers.count, first != second else {
            return false
        }
        let firstPage = viewControllers[first]
        let secondPage = viewControllers[second]
        return tabBarController.replaceViewController(at: UInt(first), with: UIViewController(), attributes: nil)
            && tabBarController.replaceViewController(at: UInt(second), with: firstPage, attributes: nil)
            && tabBarController.replaceViewController(at: UInt(first), with: secondPage, attributes: nil)
    }

    /**
     * [EN] The "Photo" tab opens a dialog instead of a page: with the library through `cyl_customActionTabBarItemIdentifiers`
     *      and `cyl_customTabActionHandler`.
     * [CN] "Photo" Tab 打开对话框而不是页面：通过本库的 `cyl_customActionTabBarItemIdentifiers` 与 `cyl_customTabActionHandler` 实现。
     */
    static func useCustomActionForPhotoTab(of tabBarController: CYLTabBarController) {
        tabBarController.cyl_customActionTabBarItemIdentifiers = ["photo"]
        tabBarController.cyl_customTabActionHandler = { controller, viewController in
            // [EN] Next run loop turn (outside the tap): "Photo" looks selected over the current page while the dialog is
            //      up, then everything is restored.
            // [CN] 在下一个 runloop（点击处理之外）执行：对话框显示期间，"Photo" 显示为选中而页面保持不变，关闭后全部恢复。
            DispatchQueue.main.async { [weak controller, weak viewController] in
                guard let controller, let photoPage = viewController,
                      let photoIndex = controller.viewControllers?.firstIndex(of: photoPage) else {
                    return
                }
                let currentIndex = controller.selectedIndex
                let swapped = swapPages(of: controller, currentIndex, photoIndex)
                if swapped {
                    controller.selectedIndex = photoIndex
                }
                presentMoreFeatures(from: controller) { [weak controller] in
                    if swapped, let controller, swapPages(of: controller, currentIndex, photoIndex) {
                        controller.selectedIndex = currentIndex
                    }
                }
            }
        }
    }

    /**
     * [EN] Runs `body` once the tab bar has its items (`perform(whenTabBarItemsReady:)`), with a trailing closure.
     * [CN] TabBar 的 item 就绪后执行 `body`（`perform(whenTabBarItemsReady:)`），可使用尾随闭包。
     */
    static func whenTabBarItemsReady(_ tabBarController: CYLTabBarController, _ body: @escaping (CYLTabBarController) -> Void) {
        tabBarController.perform(whenTabBarItemsReady: body)
    }

    /**
     * [EN] Runs `body` with each tab button once the tab bar has them. [CN] TabBar 的按钮就绪后，对每个 Tab 按钮执行 `body`。
     */
    static func forEachTabButton(of tabBarController: CYLTabBarController, _ body: @escaping (UIControl, Int) -> Void) {
        CYLGallery.whenTabBarItemsReady(tabBarController) { controller in
            for (index, viewController) in (controller.viewControllers ?? []).enumerated() {
                if let button = viewController.tabBarItem.cyl_tabButton ?? viewController.cyl_tabButton {
                    body(button, index)
                }
            }
        }
    }

    /**
     * [EN] A speech bubble with its tail at the bottom right. [CN] 尾巴在右下角的气泡。
     */
    static func bubbleImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 40, height: 34)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: 28), cornerRadius: 8).fill()
            let tail = UIBezierPath()
            tail.move(to: CGPoint(x: size.width - 22, y: 27))
            tail.addLine(to: CGPoint(x: size.width - 10, y: 27))
            tail.addLine(to: CGPoint(x: size.width - 16, y: size.height))
            tail.close()
            tail.fill()
        }
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 12, right: 25), resizingMode: .stretch)
    }

    /**
     * [EN] A bubble with `text`, added above the right edge of `button`. [CN] 在 `button` 右上方添加一个带 `text` 的气泡。
     */
    @discardableResult
    static func addBubble(to button: UIView, text: String, color: UIColor, frame: CGRect, font: UIFont) -> UIView {
        let bubble = UIImageView(image: bubbleImage(color: color))
        bubble.frame = frame
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .white
        label.sizeToFit()
        label.center = CGPoint(x: frame.width / 2, y: (frame.height - 6) / 2)
        bubble.addSubview(label)
        button.clipsToBounds = false
        button.addSubview(bubble)
        return bubble
    }

    /**
     * [EN] The dark look of the background scenes: dark tabs, the selected one darker, white icons when selected.
     * [CN] 背景色场景的深色外观：深色 Tab，选中的更深，选中时图标为白色。
     */
    static func darkTabAttributes(special: Bool) -> [String: Any] {
        if special {
            return [CYLTabBarItemIconColor: UIColor.white, CYLTabBarItemSelectedIconColor: UIColor.white,
                    CYLTabBarItemBackgroundColor: rgb(17, 86, 136), CYLTabBarItemSelectedBackgroundColor: rgb(22, 24, 25)]
        }
        return [CYLTabBarItemIconColor: gray(165), CYLTabBarItemSelectedIconColor: UIColor.white,
                CYLTabBarItemBackgroundColor: rgb(37, 39, 42), CYLTabBarItemSelectedBackgroundColor: rgb(22, 24, 25)]
    }

    static func setTabBarBackgroundColor(_ tabBarController: UITabBarController, _ color: UIColor) {
        let appearance = tabBarController.tabBar.standardAppearance.copy()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = color
        appearance.shadowColor = .clear
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
    }

    static func embed(_ tabBarController: CYLTabBarController) -> UIViewController {
        tabBarController.title = cylDemoLocalizedString("示例")
        return CYLGalleryNavigationController(rootViewController: tabBarController)
    }

    /**
     * [EN] iOS 26+ draws Liquid Glass by default; FlatDesign shows the full-width tab bar of the earlier systems.
     * [CN] iOS 26+ 默认液态玻璃；扁平样式显示以前系统的全宽 TabBar。
     */
    static var fullWidthStyle: CYLTabBarStyleType {
        if #available(iOS 26.0, *) {
            return .flatDesign
        }
        return .default
    }

    /**
     * [EN] The look of the background scenes: image-only, the middle tab highlighted and larger.
     * [CN] 背景色场景的外观：纯图标，中间 Tab 突出且更大。
     */
    static func backgroundTabBarController() -> CYLTabBarController {
        let attributes = attributes(5, showsTitles: false, pointSize: 22) { index in
            var item = darkTabAttributes(special: index == 2)
            if index == 2 {
                item[CYLTabBarItemImage] = symbol("camera", filled: false, pointSize: 28)
                item[CYLTabBarItemSelectedImage] = symbol("camera", filled: true, pointSize: 28)
            }
            return item
        }
        // [EN] Full width (FlatDesign on iOS 26+): Liquid Glass draws its own selection and ignores tab backgrounds.
        // [CN] 全宽样式（iOS 26+ 为扁平样式）：液态玻璃自带选中效果，会忽略 Tab 的背景色。
        let tabBarController = tabBarController(pages: pages(5, embedsInNavigation: false), attributes: attributes,
                                                styleType: fullWidthStyle, context: context)
        setTabBarBackgroundColor(tabBarController, rgb(37, 39, 42))
        return tabBarController
    }

    /**
     * [EN] Runs `body` every `interval` seconds while `tabBarController` is alive.
     * [CN] 在 `tabBarController` 存活期间每 `interval` 秒执行一次 `body`。
     */
    static func repeatEvery(_ interval: TimeInterval, while tabBarController: CYLTabBarController,
                            _ body: @escaping (CYLTabBarController) -> Void) {
        let timer = Timer(timeInterval: interval, repeats: true) { [weak tabBarController] timer in
            guard let tabBarController else {
                timer.invalidate()
                return
            }
            body(tabBarController)
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    /**
     * [EN] The icon view of the tab at `index`. [CN] 第 `index` 个 Tab 的图标视图。
     */
    static func iconView(of tabBarController: CYLTabBarController, at index: Int) -> UIView? {
        guard let viewControllers = tabBarController.viewControllers, index < viewControllers.count else {
            return nil
        }
        let viewController = viewControllers[index]
        return (viewController.tabBarItem.cyl_tabButton ?? viewController.cyl_tabButton)?.cyl_tabImageView()
    }

    /**
     * [EN] The look of the tips and irregular scenes: white titles, teal when selected, on a dark teal bar.
     * [CN] 提示与不规则场景的外观：白色标题，选中时为青色，深青色 TabBar。
     */
    static func tealTabAttributes() -> [String: Any] {
        let teal = rgb(23, 149, 158)
        return [CYLTabBarItemTitleColor: UIColor.white, CYLTabBarItemSelectedTitleColor: teal,
                CYLTabBarItemIconColor: UIColor.white, CYLTabBarItemSelectedIconColor: teal]
    }

    static func redTabAttributes() -> [String: Any] {
        let gray = gray(175)
        let red = rgb(254, 73, 42)
        return [CYLTabBarItemTitleColor: gray, CYLTabBarItemSelectedTitleColor: red,
                CYLTabBarItemIconColor: gray, CYLTabBarItemSelectedIconColor: red]
    }

    /**
     * [EN] The views the library marked (`cyl_markAsInserted(forTabControl:)`) inside `tabBar`.
     * [CN] `tabBar` 中被本库标记（`cyl_markAsInserted(forTabControl:)`）的视图。
     */
    static func markedViews(in tabBar: UIView?) -> [UIView] {
        guard let tabBar else {
            return []
        }
        return UIView.cyl_insertedTabControlViews().filter { $0.isDescendant(of: tabBar) }
    }

    /**
     * [EN] A bar button item that runs `handler`. [CN] 点击后执行 `handler` 的导航栏按钮。
     */
    static func barButtonItem(_ title: String, _ handler: @escaping () -> Void) -> UIBarButtonItem {
        UIBarButtonItem(primaryAction: UIAction(title: title) { _ in handler() })
    }

    /**
     * [EN] A star drawn in place of a tab's icon, which the library marks as inserted.
     * [CN] 替换 Tab 图标的星形视图，本库会将其标记为插入视图。
     */
    static func starView() -> UIView {
        let starView = UIImageView(image: symbol("star", filled: true, pointSize: 22))
        starView.tintColor = .systemOrange
        return starView
    }
}
