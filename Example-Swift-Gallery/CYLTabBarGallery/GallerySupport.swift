//
//  GallerySupport.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] Shared building blocks of the Swift tab bar gallery: colors, the eight sample tabs, attributes, pages and small
//      drawing helpers. Every tab bar is built with the library's public API only.
// [CN] Swift TabBar 图库共用的组件：颜色、八个示例 Tab、属性、页面与绘制辅助方法。所有 TabBar 只使用本库的公开 API 构建。
enum Gallery {

    /// [EN] The context of the gallery's tab bars: no plus button is registered for it.
    /// [CN] 图库 TabBar 的 context：没有为它注册 PlusButton。
    static let context = "CYLSwiftGallery"
    /// [EN] The context of the irregular scenes, with their own plus button.
    /// [CN] 不规则场景的 context，带有自己的 PlusButton。
    static let irregularContext = "CYLSwiftGalleryIrregular"

    // MARK: Colors

    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: 1.0)
    }

    static func gray(_ white: CGFloat) -> UIColor {
        return UIColor(white: white / 255.0, alpha: 1.0)
    }

    static let teal = rgb(23, 149, 158)
    static let darkTeal = rgb(10, 66, 91)
    static let red = rgb(254, 73, 42)

    // MARK: Tabs

    struct Tab {
        let title: String
        let symbol: String
        let identifier: String
    }

    static let tabs: [Tab] = [
        Tab(title: "Home", symbol: "house", identifier: "home"),
        Tab(title: "Find", symbol: "safari", identifier: "find"),
        Tab(title: "Photo", symbol: "camera", identifier: "photo"),
        Tab(title: "Favor", symbol: "heart", identifier: "favor"),
        Tab(title: "Me", symbol: "person", identifier: "me"),
        Tab(title: "Message", symbol: "message", identifier: "message"),
        Tab(title: "Shop", symbol: "cart", identifier: "shop"),
        Tab(title: "Cardboard", symbol: "shippingbox", identifier: "cardboard"),
    ]

    /// [EN] A template SF Symbol, so per-tab icon colors apply. [CN] 模板 SF Symbol，单个 Tab 的图标颜色可以生效。
    static func symbol(_ name: String, filled: Bool, pointSize: CGFloat = 20) -> UIImage {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize)
        let image = UIImage(systemName: filled ? name + ".fill" : name, withConfiguration: configuration)
            ?? UIImage(systemName: name, withConfiguration: configuration)
            ?? UIImage()
        return image.withRenderingMode(.alwaysTemplate)
    }

    /// [EN] The pages of a scene, optionally each in a navigation controller. [CN] 场景中的页面，可选地分别放进导航控制器。
    static func pages(_ count: Int, embedsInNavigation: Bool = false) -> [UIViewController] {
        return (0..<count).map { index in
            let page = GalleryPageViewController()
            guard embedsInNavigation else {
                return page
            }
            page.title = index == 3 ? "List" : tabs[index].title
            return GalleryNavigationController(rootViewController: page)
        }
    }

    /// [EN] The attributes of `count` tabs; `extra` adds keys per tab (colors, fonts...).
    /// [CN] `count` 个 Tab 的属性；`extra` 为每个 Tab 添加键（颜色、字体……）。
    static func attributes(_ count: Int, showsTitles: Bool = true, pointSize: CGFloat = 20,
                           extra: ((Int) -> [String: Any])? = nil) -> [[String: Any]] {
        return (0..<count).map { index in
            let tab = tabs[index]
            var item: [String: Any] = [
                CYLTabBarItemImage: symbol(tab.symbol, filled: false, pointSize: pointSize),
                CYLTabBarItemSelectedImage: symbol(tab.symbol, filled: true, pointSize: pointSize),
                CYLTabBarItemIdentifier: tab.identifier,
            ]
            if showsTitles {
                item[CYLTabBarItemTitle] = tab.title
            }
            extra?(index).forEach { item[$0.key] = $0.value }
            return item
        }
    }

    /*!
     * [EN] A CYLTabBarController that is its own delegate, so its `-tabBarController:shouldSelectViewController:` runs
     *      the hijack checks before UIKit selects a tab. Assigned through `UITabBarController.delegate`, whose type the
     *      controller satisfies.
     * [CN] 作为自己代理的 CYLTabBarController，其 `-tabBarController:shouldSelectViewController:` 会在 UIKit 选中 Tab 之前执行劫持检查。
     *      通过 `UITabBarController.delegate` 赋值，控制器满足其类型要求。
     */
    static func tabBarController(pages: [UIViewController], attributes: [[String: Any]],
                                 styleType: CYLTabBarStyleType = .default, context: String = Gallery.context) -> CYLTabBarController {
        let controller = CYLTabBarController(viewControllers: pages, tabBarItemsAttributes: attributes,
                                             styleType: styleType, context: context)
        (controller as UITabBarController).delegate = controller
        return controller
    }

    /// [EN] The system UITabBarController, for comparison. [CN] 系统 UITabBarController，用于对照。
    static func systemTabBarController(_ count: Int) -> UITabBarController {
        let controller = UITabBarController()
        let pages = Gallery.pages(count)
        for (index, page) in pages.enumerated() {
            let tab = tabs[index]
            page.tabBarItem = UITabBarItem(title: tab.title,
                                           image: symbol(tab.symbol, filled: false),
                                           selectedImage: symbol(tab.symbol, filled: true))
        }
        controller.viewControllers = pages
        return controller
    }

    /// [EN] iOS 26+ draws Liquid Glass by default; FlatDesign shows the full-width tab bar of the earlier systems.
    /// [CN] iOS 26+ 默认液态玻璃；扁平样式显示以前系统的全宽 TabBar。
    static var fullWidthStyle: CYLTabBarStyleType {
        if #available(iOS 26.0, *) {
            return .flatDesign
        }
        return .default
    }

    static func setBackgroundColor(of tabBarController: UITabBarController, to color: UIColor) {
        let appearance = tabBarController.tabBar.standardAppearance.copy() as? UITabBarAppearance ?? UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = color
        appearance.shadowColor = .clear
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
    }

    static func embed(_ tabBarController: UITabBarController) -> UIViewController {
        tabBarController.title = "Example"
        return GalleryNavigationController(rootViewController: tabBarController)
    }

    // MARK: Tab buttons

    /// [EN] The tab button of `viewController`. `UIBarItem.cyl_tabButton` is imported as non-optional but is nil before
    ///      the button exists, so it is read into an optional first.
    /// [CN] `viewController` 的 Tab 按钮。`UIBarItem.cyl_tabButton` 被导入为非可选类型，但按钮创建前为 nil，因此先读入可选值。
    static func tabButton(of viewController: UIViewController) -> UIControl? {
        let itemButton: UIControl? = viewController.tabBarItem.cyl_tabButton
        return itemButton ?? viewController.cyl_tabButton
    }

    /// [EN] Runs `body` with each tab button once the tab bar has them. [CN] TabBar 的按钮就绪后，对每个 Tab 按钮执行 `body`。
    static func forEachTabButton(of tabBarController: CYLTabBarController, _ body: @escaping (UIControl, Int) -> Void) {
        tabBarController.performWhenTabBarItemsReady { controller in
            for (index, viewController) in (controller.viewControllers ?? []).enumerated() {
                if let button = tabButton(of: viewController) {
                    body(button, index)
                }
            }
        }
    }

    static func iconView(of tabBarController: UITabBarController, at index: Int) -> UIView? {
        guard let viewControllers = tabBarController.viewControllers, index < viewControllers.count else {
            return nil
        }
        return tabButton(of: viewControllers[index])?.cyl_tabImageView()
    }

    // MARK: Drawing and animation

    static func playKeyframes(on view: UIView?, keyPath: String, values: [Any], duration: CFTimeInterval) {
        guard let view = view else {
            return
        }
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        animation.duration = duration
        animation.calculationMode = .cubic
        view.layer.add(animation, forKey: nil)
    }

    static let bounceValues: [Any] = [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0]

    /// [EN] A speech bubble with its tail at the bottom right. [CN] 尾巴在右下角的气泡。
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

    /// [EN] A bubble with `text`, added to `button` at `frame`. [CN] 在 `button` 的 `frame` 处添加一个带 `text` 的气泡。
    @discardableResult
    static func addBubble(to button: UIControl, text: String, color: UIColor, frame: CGRect, font: UIFont) -> UIView {
        let bubble = UIImageView(image: bubbleImage(color: color))
        bubble.frame = frame
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .white
        label.sizeToFit()
        label.center = CGPoint(x: frame.width / 2.0, y: (frame.height - 6) / 2.0)
        bubble.addSubview(label)
        button.clipsToBounds = false
        button.addSubview(bubble)
        return bubble
    }

    // MARK: Intercepted "Photo" tab

    /// [EN] The dialog of an intercepted tab; `dismissed` runs when any button closes it.
    /// [CN] 被拦截的 Tab 弹出的对话框；任一按钮关闭它时执行 `dismissed`。
    static func presentMoreFeatures(from presenter: UIViewController, dismissed: @escaping () -> Void) {
        guard presenter.presentedViewController == nil else {
            dismissed()
            return
        }
        let alert = UIAlertController(title: "More features", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in dismissed() })
        alert.addAction(UIAlertAction(title: "About us", style: .default) { _ in dismissed() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in dismissed() })
        presenter.present(alert, animated: true)
    }

    /// [EN] Swaps the pages of two tabs while each keeps its title and icon (a spare page frees one slot first).
    /// [CN] 交换两个 Tab 的页面，各 Tab 保持自己的标题与图标（先用一个临时页面腾出一个位置）。
    static func swapPages(of tabBarController: CYLTabBarController, _ first: Int, _ second: Int) -> Bool {
        guard let viewControllers = tabBarController.viewControllers,
              first != second, first < viewControllers.count, second < viewControllers.count else {
            return false
        }
        let firstPage = viewControllers[first]
        let secondPage = viewControllers[second]
        return tabBarController.replaceViewController(at: first, with: UIViewController(), attributes: nil)
            && tabBarController.replaceViewController(at: second, with: firstPage, attributes: nil)
            && tabBarController.replaceViewController(at: first, with: secondPage, attributes: nil)
    }

    /*!
     * [EN] "Photo" opens a dialog instead of its page (`cyl_hijackedTabBarItemIdentifiers` + `cyl_didHijackHandler`); while
     *      the dialog is up, "Photo" looks selected over the current page, then everything is restored.
     * [CN] "Photo" 打开对话框而不是页面（`cyl_hijackedTabBarItemIdentifiers` + `cyl_didHijackHandler`）；对话框显示期间，"Photo" 显示为
     *      选中而页面不变，关闭后全部恢复。
     */
    static func hijackPhotoTab(of tabBarController: CYLTabBarController) {
        tabBarController.cyl_hijackedTabBarItemIdentifiers = ["photo"]
        tabBarController.cyl_didHijackHandler = { controller, photoPage in
            DispatchQueue.main.async { [weak controller, weak photoPage] in
                guard let controller = controller, let photoPage = photoPage,
                      let photoIndex = controller.viewControllers?.firstIndex(of: photoPage) else {
                    return
                }
                let currentIndex = controller.selectedIndex
                let swapped = swapPages(of: controller, currentIndex, photoIndex)
                if swapped {
                    controller.selectedIndex = photoIndex
                }
                presentMoreFeatures(from: controller) { [weak controller] in
                    guard swapped, let controller = controller, swapPages(of: controller, currentIndex, photoIndex) else {
                        return
                    }
                    controller.selectedIndex = currentIndex
                }
            }
        }
    }
}
