//
//  CYLGalleryPlusButtons.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/**
 * [EN] The large round center button of the irregular scenes: a teal circle with a light border, raised above the tab
 *      bar, that only responds inside its circle. A tap plays a ripple and shows an action sheet instead of selecting a
 *      page.
 * [CN] 不规则场景中的大号圆形中间按钮：带浅色描边的青色圆形，凸出于 TabBar 之上，只在圆形内响应点击。点击时播放波纹并弹出操作表，
 *      而不是选中某个页面。
 */
final class CYLGalleryIrregularPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    private let circleView = UIView()
    private let iconView = UIImageView()

    static func plusButton() -> Any {
        let diameter: CGFloat = 70
        let button = CYLGalleryIrregularPlusButton(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        button.circleView.frame = button.bounds
        button.circleView.isUserInteractionEnabled = false
        button.circleView.backgroundColor = CYLGallery.rgb(23, 149, 158)
        button.circleView.layer.cornerRadius = diameter / 2
        button.circleView.layer.borderWidth = 3
        button.circleView.layer.borderColor = CYLGallery.gray(235).cgColor
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        button.iconView.image = UIImage(systemName: "camera.fill", withConfiguration: configuration)
        button.iconView.sizeToFit()
        button.iconView.tintColor = .white
        button.iconView.center = CGPoint(x: diameter / 2, y: diameter / 2)
        button.circleView.addSubview(button.iconView)
        button.addSubview(button.circleView)
        button.accessibilityLabel = "Camera"
        button.addTarget(button, action: #selector(galleryDidTap), for: .touchUpInside)
        return button
    }

    static func tabBarContext() -> String {
        CYLGallery.irregularContext
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        2
    }

    static func multiplier(ofTabBarHeight _: CGFloat) -> CGFloat {
        0.25
    }

    static func tabBarItemIdentifier() -> String {
        "camera"
    }

    /**
     * [EN] Only the circle responds. [CN] 只有圆形区域响应。
     */
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let radius = bounds.width / 2
        let dx = point.x - bounds.midX
        let dy = point.y - bounds.midY
        return (dx * dx + dy * dy).squareRoot() <= radius
    }

    override var isHighlighted: Bool {
        didSet {
            let highlighted = isHighlighted
            UIView.animate(withDuration: 0.2) {
                self.circleView.transform = highlighted ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
            }
        }
    }

    @objc private func galleryDidTap() {
        playRipple()
        let presenter = cyl_owningTabBarController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: cylDemoLocalizedString("拍照"), style: .default))
            sheet.addAction(UIAlertAction(title: cylDemoLocalizedString("从相册选择"), style: .default))
            sheet.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel))
            sheet.popoverPresentationController?.sourceView = self
            sheet.popoverPresentationController?.sourceRect = self?.bounds ?? .zero
            presenter?.present(sheet, animated: true)
        }
    }

    /**
     * [EN] A dot that grows over the circle and fades out. [CN] 一个小圆点放大覆盖圆形后淡出。
     */
    private func playRipple() {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        dot.layer.cornerRadius = 1
        dot.backgroundColor = CYLGallery.rgb(10, 66, 91)
        dot.alpha = 0.5
        dot.center = CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY)
        circleView.insertSubview(dot, belowSubview: iconView)
        let scale = circleView.bounds.width / 2
        UIView.animate(withDuration: 0.4, animations: {
            dot.transform = CGAffineTransform(scaleX: scale, y: scale)
            dot.alpha = 0
        }, completion: { _ in
            dot.removeFromSuperview()
        })
    }
}

/**
 * [EN] A plus button that selects its own page (`plusChildViewController()`), so on Liquid Glass the library puts its
 *      stand-in (built from `selectedContentImage()`) in the selected layer: the view that
 *      `cyl_layOutPlusButtonInLiquidGlassLayers` installs on every layout pass.
 * [CN] 选中自己页面（`plusChildViewController()`）的 PlusButton，因此在液态玻璃下本库会把它的替身（由 `selectedContentImage()` 生成）
 *      放进选中层：即 `cyl_layOutPlusButtonInLiquidGlassLayers` 在每次布局时安装的视图。
 */
final class CYLGalleryPagePlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    static func plusButton() -> Any {
        let button = CYLGalleryPagePlusButton(type: .custom)
        button.setImage(contentImage(), for: .normal)
        button.setImage(selectedContentImage(), for: .selected)
        button.tintColor = .systemIndigo
        button.frame = CGRect(x: 0, y: 0, width: 64, height: 49)
        button.accessibilityLabel = "Compose"
        return button
    }

    static func contentImage() -> UIImage {
        CYLGallery.symbol("plus.circle", filled: false, pointSize: 30)
    }

    static func selectedContentImage() -> UIImage {
        CYLGallery.symbol("plus.circle", filled: true, pointSize: 30)
    }

    static func plusChildViewController() -> UIViewController {
        let page = CYLGalleryPageViewController()
        page.title = cylDemoLocalizedString("撰写")
        return page
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        2
    }

    static func tabBarContext() -> String {
        CYLGallery.plusPageContext
    }

    static func tabBarItemIdentifier() -> String {
        "compose"
    }
}

/**
 * [EN] The same custom action for the system UITabBarController, through its delegate.
 * [CN] 系统 UITabBarController 通过代理实现同样的自定义操作。
 */
final class CYLGallerySystemPhotoActionDelegate: NSObject, UITabBarControllerDelegate {

    static let shared = CYLGallerySystemPhotoActionDelegate()

    /**
     * [EN] Swaps two tabs' pages while each keeps its title and icon (UITab entries on iOS 18+ when the controller uses them).
     * [CN] 交换两个 Tab 的页面，各 Tab 保持自己的标题与图标（iOS 18+ 且控制器使用 UITab 时交换 UITab）。
     */
    private func swapTab(at first: Int, with second: Int, in tabBarController: UITabBarController) {
        if #available(iOS 18.0, *), tabBarController.tabs.count > max(first, second) {
            var tabs = tabBarController.tabs
            tabs.swapAt(first, second)
            tabBarController.tabs = tabs
            let firstTab = tabs[first]
            let secondTab = tabs[second]
            let title = firstTab.title
            let image = firstTab.image
            firstTab.title = secondTab.title
            firstTab.image = secondTab.image
            secondTab.title = title
            secondTab.image = image
            return
        }
        guard var viewControllers = tabBarController.viewControllers, max(first, second) < viewControllers.count else {
            return
        }
        viewControllers.swapAt(first, second)
        tabBarController.setViewControllers(viewControllers, animated: false)
        let firstItem = viewControllers[first].tabBarItem
        viewControllers[first].tabBarItem = viewControllers[second].tabBarItem
        viewControllers[second].tabBarItem = firstItem
    }

    /**
     * [EN] "Photo" looks selected over the current page while the dialog is up, then it is restored.
     * [CN] 对话框显示期间 "Photo" 显示为选中且页面不变，关闭后恢复。
     */
    private func showPhotoAction(at photoIndex: Int, selectedIndex currentIndex: Int, in tabBarController: UITabBarController) {
        DispatchQueue.main.async { [weak self, weak tabBarController] in
            guard let self, let tabBarController else {
                return
            }
            swapTab(at: currentIndex, with: photoIndex, in: tabBarController)
            tabBarController.selectedIndex = photoIndex
            CYLGallery.presentMoreFeatures(from: tabBarController) { [weak self, weak tabBarController] in
                guard let self, let tabBarController else {
                    return
                }
                swapTab(at: currentIndex, with: photoIndex, in: tabBarController)
                tabBarController.selectedIndex = currentIndex
            }
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let currentIndex = tabBarController.selectedIndex
        guard viewController.tabBarItem.title == "Photo",
              let photoIndex = tabBarController.viewControllers?.firstIndex(of: viewController),
              currentIndex != NSNotFound, photoIndex != currentIndex else {
            return true
        }
        showPhotoAction(at: photoIndex, selectedIndex: currentIndex, in: tabBarController)
        return false
    }

    @available(iOS 18.0, *)
    func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        guard tab.title == "Photo", let photoIndex = tabBarController.tabs.firstIndex(of: tab),
              let selectedTab = tabBarController.selectedTab, let currentIndex = tabBarController.tabs.firstIndex(of: selectedTab),
              photoIndex != currentIndex else {
            return true
        }
        showPhotoAction(at: photoIndex, selectedIndex: currentIndex, in: tabBarController)
        return false
    }
}
