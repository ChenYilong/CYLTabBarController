//
//  CYLSettingsDemoRows+Pages.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The demo rows of the settings section, part 2: subviews outside their superview, images from a bundle, navigation
 *      settings without a base class, the slide transition classes, and a plus button whose image is set later. Translated
 *      from Objective-C (docs/Swift-Migration.md, step 33); internal.
 * [CN] 设置分组的演示行，第 2 部分：超出父视图响应点击、从 bundle 加载图片、不继承基类的导航设置、滑动转场类，以及之后才设置图片的 PlusButton。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 33 步）；仅供内部使用。
 */
extension CYLSettingsDemo {

    // MARK: Subviews outside their superview (FIX: issue #535)

    static func outsideBoundsCell(_ tableView: UITableView) -> UITableViewCell {
        let identifier = "CYLOutsideBoundsCell"
        return tableView.dequeueReusableCell(withIdentifier: identifier) as? CYLOutsideBoundsCell
            ?? CYLOutsideBoundsCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: Images from a bundle (FIX: issue #535)

    /**
     * [EN] The icon is the library's sample image, read with `CYLImageInBundle` from its resource bundle (not cached); the
     *      text says whether `CYLBundleImage` finds it in the main bundle (not with `use_frameworks!`) and runs every other
     *      loader once.
     * [CN] 图标是本库的示例图片，由 `CYLImageInBundle` 从资源包读取（不缓存）；文字说明 `CYLBundleImage` 能否在主 bundle 中找到它
     *      （使用 `use_frameworks!` 时找不到），并调用其他每个加载函数一次。
     */
    static func bundleImageCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLBundleImageCell")
        cell.selectionStyle = .none
        let fileName = "cyl_badge_sample_icon@3x.png"
        cell.imageView?.image = CYLImageInBundle(CYLResourceBundle(), nil, fileName)
        let mainBundleResult = CYLBundleImage(nil, "CYLTabBarController", nil, fileName) != nil
            ? CYLLocalizedString("已找到") : CYLLocalizedString("未找到（use_frameworks 时资源包位于 framework 中）")
        func found(_ value: Any?) -> String { value != nil ? "✓" : "✗" }
        let fileManager = FileManager.default
        let pathInBundle = CYLImagePathInBundle(CYLResourceBundle(), nil, "cyl_badge_sample_icon@3x")
        let mainBundlePath = CYLBundleImagePath(nil, "CYLTabBarController", nil, fileName)
        let mainBundleData = CYLBundleImageData(nil, "CYLTabBarController", nil, fileName)
        let imageFromData = CYLBundleImageFromData(nil, "CYLTabBarController", nil, fileName)
        // [EN] `imageNamed:` also takes a path inside a bundle of the main bundle. [CN] `imageNamed:` 也接受主 bundle 中某个 bundle 内的路径。
        let namedImage = CYLImageNamed("CYLTabBarController.bundle/cyl_badge_sample_icon")
        let dataText = mainBundleData.map { ByteCountFormatter.string(fromByteCount: Int64($0.count), countStyle: .file) } ?? found(nil)
        let loaders = "CYLImagePathInBundle \(found(pathInBundle.flatMap { fileManager.fileExists(atPath: $0) ? $0 : nil })) "
            + "(\(pathInBundle.map { ($0 as NSString).lastPathComponent } ?? "-")) · "
            + "CYLBundleImagePath \(found(mainBundlePath.flatMap { fileManager.fileExists(atPath: $0) ? $0 : nil })) · "
            + "CYLBundleImageData \(dataText) · CYLBundleImageFromData \(found(imageFromData)) (@\(imageFromData.map { "\($0.scale)" } ?? "-")x) · "
            + "CYLImageNamed \(found(namedImage))"
        cell.textLabel?.text = CYLLocalizedString("从 bundle 加载图片（issue #535）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("左侧图片由 CYLImageInBundle 从资源包读取（不缓存）。主 bundle 中的 CYLBundleImage：%@"),
                                            mainBundleResult) + "\n" + loaders
        return cell
    }

    // MARK: Navigation bar without a base class (FIX: issue #535)

    static func navigationSettingCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLNavigationSettingCell", symbol: "menubar.rectangle")
        let settingSwitch = cell.accessoryView as? CYLNavigationSettingSwitch ?? CYLNavigationSettingSwitch()
        cell.accessoryView = settingSwitch
        settingSwitch.isOn = UIViewController.cyl_automaticNavigationSettingEnabled
        cell.textLabel?.text = CYLLocalizedString("不继承基类隐藏导航栏（issue #535）")
        cell.detailTextLabel?.text = CYLLocalizedString("打开开关即设置 cyl_automaticNavigationSettingEnabled；点击该行 push 一个普通 UIViewController，它设置了 cyl_navigationBarHidden 与 cyl_hidesAncestorNavigationBars。")
        return cell
    }

    // MARK: Slide transition classes (FIX: issue #535)

    static func slideTransitionCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLSlideTransitionCell", symbol: "rectangle.split.3x1")
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = CYLLocalizedString("滑动转场（CYLTabBarSlideTransitionAnimator）")
        cell.detailTextLabel?.text = CYLLocalizedString("点击打开一个系统 UITabBarController：点击 Tab 或在页面上左右拖动，页面跟随手指滑动切换。")
        return cell
    }

    // MARK: Plus button image set later

    /**
     * [EN] The demo's own context, so the app's plus button stays as it is. [CN] 演示专用的 context，App 自己的 PlusButton 保持不变。
     */
    static let lateImageContext = "CYLLateImagePlusButtonDemo"

    /**
     * [EN] What happens to the plus button's picture 2 seconds after it is created; the last three are ready at launch, to
     *      compare with.
     * [CN] PlusButton 创建 2 秒后其图片的变化；最后三个在启动时即已就绪，用于对照。
     */
    enum LateImageCase: Int, CaseIterable {
        case loaded, replaced, removed, backgroundLoaded, readyImage, readyLargerImage, readyBackground

        var title: String {
            switch self {
            case .loaded: return CYLLocalizedString("加载图片")
            case .replaced: return CYLLocalizedString("替换为更大的图片")
            case .removed: return CYLLocalizedString("移除图片")
            case .backgroundLoaded: return CYLLocalizedString("加载背景图片")
            case .readyImage: return CYLLocalizedString("对照：启动时即有图片")
            case .readyLargerImage: return CYLLocalizedString("对照：启动时即有更大的图片")
            case .readyBackground: return CYLLocalizedString("对照：启动时即有背景图片")
            }
        }

        var isReadyAtLaunch: Bool {
            rawValue >= LateImageCase.readyImage.rawValue
        }
    }

    /**
     * [EN] The case the next demo runs; set right before its plus button is registered. [CN] 下一次演示的场景，注册 PlusButton 之前设置。
     */
    static var lateImageCase = LateImageCase.loaded

    /**
     * [EN] A purple circle with a white plus. [CN] 紫色圆形加白色加号。
     */
    static func lateImageCircle(_ diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let plus = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .bold))?
            .withTintColor(.white)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.systemPurple.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            if let plus {
                plus.draw(at: CGPoint(x: (size.width - plus.size.width) / 2, y: (size.height - plus.size.height) / 2))
            }
        }
    }

    static func lateImageCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLLateImageCell", symbol: "photo.badge.arrow.down")
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = CYLLocalizedString("PlusButton 图片之后才加载")
        cell.detailTextLabel?.text = CYLLocalizedString("点击选择场景，push 一个 TabBarController：PlusButton 创建时没有图片，2 秒后加载、替换、移除图片或加载背景图片；最终布局应与启动时就有图片一致。")
        return cell
    }

    /**
     * [EN] Asks for a case, then pushes the demo (or presents it without a navigation controller). On iPad only, the sheet is
     *      anchored to the row, else the list, else the page: on iPhone an anchor turns it into a popover (iOS 26), which cut
     *      off the last cases.
     * [CN] 选择场景后 push 演示（没有导航控制器时 present）。仅 iPad 上把操作表锚定到该行，没有时到列表，再没有时到页面：iPhone 上设置锚点会
     *      让它变成弹出框（iOS 26），最后几个场景被截断。
     */
    static func showLateImageDemo(from viewController: UIViewController, _ tableView: UITableView?, _ indexPath: IndexPath) {
        let alert = UIAlertController(title: CYLLocalizedString("PlusButton 图片之后才加载"), message: nil, preferredStyle: .actionSheet)
        let styleType = (viewController.cyl_owningTabBarController() ?? viewController.cyl_tabBarController)?.tabBarStyleType ?? .liquidGlass
        for lateCase in LateImageCase.allCases {
            alert.addAction(UIAlertAction(title: lateCase.title, style: .default) { [weak viewController] _ in
                guard let presenter = viewController else { return }
                let demo = CYLLateImageDemoTabBarController.demo(with: lateCase, styleType: styleType)
                if let navigationController = presenter.navigationController {
                    navigationController.pushViewController(demo, animated: true)
                } else {
                    demo.modalPresentationStyle = .fullScreen
                    presenter.present(demo, animated: true)
                }
            })
        }
        alert.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
        if UIDevice.current.userInterfaceIdiom == .pad {
            let sourceView: UIView = tableView?.cellForRow(at: indexPath) ?? tableView ?? viewController.view
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        viewController.present(alert, animated: true)
    }
}

/**
 * FIX: issue #535
 * [EN] A gray box with a button that sticks out of it to the right: off, only the part inside responds; on sets
 *      `cyl_respondsOutsideSuperviewBounds`. Each tap plays `-cyl_addScaleBounceAnimationWithCompletion:` and counts.
 * [CN] 灰色方框中有一个向右超出方框的按钮：关闭时只有方框内的部分响应；打开即设置 `cyl_respondsOutsideSuperviewBounds`。每次点击播放
 *      `-cyl_addScaleBounceAnimationWithCompletion:` 并计数。
 */
final class CYLOutsideBoundsCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let boxView = UIView()
    private let outsideButton = UIButton(type: .system)
    private let outsideSwitch = UISwitch()
    private var tapCount = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.numberOfLines = 0
        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = .gray
        summaryLabel.numberOfLines = 0
        boxView.backgroundColor = UIColor(white: 0.5, alpha: 0.25)
        boxView.translatesAutoresizingMaskIntoConstraints = false
        outsideButton.backgroundColor = .systemBlue
        outsideButton.layer.cornerRadius = 6
        outsideButton.setTitleColor(.white, for: .normal)
        outsideButton.setTitle(CYLLocalizedString("点我"), for: .normal)
        // [EN] Inside the box (left half) and outside it (right half). [CN] 左半部分在方框内，右半部分在方框外。
        outsideButton.frame = CGRect(x: 40, y: 8, width: 80, height: 28)
        outsideButton.addTarget(self, action: #selector(outsideButtonTapped), for: .touchUpInside)
        boxView.addSubview(outsideButton)
        outsideSwitch.addTarget(self, action: #selector(switchDidChange), for: .valueChanged)
        accessoryView = outsideSwitch
        let stackView = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, boxView])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: margins.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            boxView.widthAnchor.constraint(equalToConstant: 80),
            boxView.heightAnchor.constraint(equalToConstant: 44),
        ])
        reload()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    private func reload() {
        titleLabel.text = CYLLocalizedString("超出父视图响应点击（issue #535）")
        outsideSwitch.isOn = outsideButton.cyl_respondsOutsideSuperviewBounds
        summaryLabel.text = String(format: CYLLocalizedString("打开开关后，点击灰色方框外的按钮部分也能响应；点击会播放放大再缩小动画。已点击：%@ 次"),
                                   NSNumber(value: tapCount))
    }

    @objc private func switchDidChange() {
        outsideButton.cyl_respondsOutsideSuperviewBounds = outsideSwitch.isOn
        reload()
    }

    @objc private func outsideButtonTapped() {
        tapCount += 1
        outsideButton.cyl_addScaleBounceAnimation(completion: nil)
        reload()
    }
}

/**
 * [EN] A plain UIViewController (no CYLBaseViewController) that hides the navigation bar, and the outer one when the tab
 *      bar controller is pushed; its button goes back, since there is no bar.
 * [CN] 一个普通的 UIViewController（没有继承 CYLBaseViewController），隐藏导航栏；TabBarController 被 push 时外层导航栏也隐藏。由于没有
 *      导航栏，用页面上的按钮返回。
 */
final class CYLNavigationSettingDemoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        cyl_navigationBarHidden = true
        cyl_hidesAncestorNavigationBars = true
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = CYLLocalizedString("这是一个普通的 UIViewController，没有继承 CYLBaseViewController。导航栏已隐藏。")
        let backButton = UIButton(type: .system)
        backButton.setTitle(CYLLocalizedString("关闭"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        let stackView = UIStackView(arrangedSubviews: [label, backButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
}

/**
 * [EN] Turns `cyl_automaticNavigationSettingEnabled` on or off. [CN] 打开或关闭 `cyl_automaticNavigationSettingEnabled`。
 */
final class CYLNavigationSettingSwitch: UISwitch {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    @objc private func valueDidChange() {
        UIViewController.cyl_automaticNavigationSettingEnabled = isOn
    }
}

/**
 * [EN] A system UITabBarController whose delegate uses `CYLTabBarSlideTransitionAnimator`, driven by a pan through
 *      `CYLTabBarInteractiveTransition`: the two classes with a delegate of your own.
 * [CN] 一个系统 UITabBarController，其代理使用 `CYLTabBarSlideTransitionAnimator`，并由拖动手势通过 `CYLTabBarInteractiveTransition` 驱动：
 *      演示在自己的代理中使用这两个类。
 */
final class CYLSlideTransitionDemoTabBarController: UITabBarController, UITabBarControllerDelegate {
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        viewControllers = [UIColor.systemRed, .systemGreen, .systemBlue].enumerated().map { index, color in
            let page = UIViewController()
            page.view.backgroundColor = color
            page.tabBarItem.title = String(format: CYLLocalizedString("页面 %@"), NSNumber(value: index + 1))
            let closeButton = UIButton(type: .system)
            closeButton.setTitle(CYLLocalizedString("关闭"), for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            page.view.addSubview(closeButton)
            NSLayoutConstraint.activate([closeButton.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
                                         closeButton.centerYAnchor.constraint(equalTo: page.view.centerYAnchor)])
            return page
        }
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    /**
     * [EN] The pan only starts the switch; the interactive transition follows it. [CN] 拖动只负责开始切换，交互式转场跟随手势。
     */
    @objc private func pan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .began, transitionCoordinator == nil else { return }
        let velocityX = recognizer.velocity(in: view).x
        if velocityX < 0 && selectedIndex + 1 < (viewControllers?.count ?? 0) {
            selectedIndex += 1
        } else if velocityX > 0 && selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let viewControllers = tabBarController.viewControllers ?? []
        let forward = (viewControllers.firstIndex(of: toVC) ?? 0) > (viewControllers.firstIndex(of: fromVC) ?? 0)
        return CYLTabBarSlideTransitionAnimator(targetEdge: forward ? .left : .right)
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        let state = panGestureRecognizer.state
        return state == .began || state == .changed ? CYLTabBarInteractiveTransition(gestureRecognizer: panGestureRecognizer) : nil
    }
}

/**
 * [EN] A plus button whose picture changes 2 seconds after it is created (`CYLSettingsDemo.lateImageCase`), as when loaded
 *      from the network. Every style must end with the layout a picture set at launch gets. Registered in its own context.
 * [CN] 创建 2 秒后图片发生变化的 PlusButton（`CYLSettingsDemo.lateImageCase`），模拟从网络加载。所有样式最终都应与启动时就设置图片的布局一致。
 *      注册在自己的 context 中。
 */
@objc(CYLLateImageDemoPlusButton)
final class CYLLateImageDemoPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    static func plusButton() -> Any {
        let lateCase = CYLSettingsDemo.lateImageCase
        let image: UIImage
        switch lateCase {
        case .replaced, .removed, .readyImage: image = CYLSettingsDemo.lateImageCircle(44)
        case .readyLargerImage: image = CYLSettingsDemo.lateImageCircle(60)
        default: image = UIImage()
        }
        let button = cyl_plusButton(with: image, title: CYLLocalizedString("发布"), selectedTitle: nil, selectedTitleColor: nil)
        if lateCase == .readyBackground {
            button.setBackgroundImage(CYLSettingsDemo.lateImageCircle(60), for: .normal)
            button.sizeToFit()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak button] in
            switch lateCase {
            case .loaded: button?.cyl_updateTitle(nil, image: CYLSettingsDemo.lateImageCircle(44), selectedImage: nil)
            case .replaced: button?.cyl_updateTitle(nil, image: CYLSettingsDemo.lateImageCircle(60), selectedImage: nil)
            case .removed: button?.setImage(nil, for: .normal)
            case .backgroundLoaded: button?.setBackgroundImage(CYLSettingsDemo.lateImageCircle(60), for: .normal)
            case .readyImage, .readyLargerImage, .readyBackground: break
            }
        }
        return button
    }

    static func tabBarContext() -> String {
        CYLSettingsDemo.lateImageContext
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        2
    }

    static func alignsTitleWithTabBarItemTitles() -> Bool {
        true
    }

    static func tabBarItemIdentifier() -> String {
        "plus"
    }

    static func plusChildViewController() -> UIViewController {
        let page = UIViewController()
        page.view.backgroundColor = .systemPurple
        page.title = CYLLocalizedString("发布")
        return page
    }
}

/**
 * [EN] The tab bar controller the row pushes: four pages and `CYLLateImageDemoPlusButton`, in the style of the app's tab bar
 *      controller; its context's plus button is removed when it leaves.
 * [CN] 点击该行后 push 的 TabBarController：四个页面与 `CYLLateImageDemoPlusButton`，样式与 App 的 TabBarController 相同；离开时移除其
 *      context 的 PlusButton。
 */
final class CYLLateImageDemoTabBarController: CYLTabBarController {

    static func demo(with lateCase: CYLSettingsDemo.LateImageCase, styleType: CYLTabBarStyleType) -> CYLLateImageDemoTabBarController {
        CYLSettingsDemo.lateImageCase = lateCase
        CYLLateImageDemoPlusButton.register()
        let symbols = ["house", "heart", "bell", "person"]
        var viewControllers: [UIViewController] = []
        var attributes: [[String: Any]] = []
        for (index, color) in [UIColor.systemRed, .systemGreen, .systemBlue, .systemOrange].enumerated() {
            let page = UIViewController()
            page.view.backgroundColor = color
            let label = UILabel()
            label.text = lateCase.isReadyAtLaunch ? lateCase.title : String(format: CYLLocalizedString("2 秒后：%@"), lateCase.title)
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            page.view.addSubview(label)
            NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
                                         label.centerYAnchor.constraint(equalTo: page.view.centerYAnchor)])
            viewControllers.append(page)
            let image = UIImage(systemName: symbols[index]) ?? UIImage()
            attributes.append([
                CYLTabBarItemTitle: String(format: CYLLocalizedString("页面 %@"), NSNumber(value: index + 1)),
                CYLTabBarItemImage: image,
                CYLTabBarItemSelectedImage: image,
            ])
        }
        let tabBarController = CYLLateImageDemoTabBarController(viewControllers: viewControllers, tabBarItemsAttributes: attributes,
                                                                imageInsets: .zero, titlePositionAdjustment: .zero, styleType: styleType,
                                                                context: CYLSettingsDemo.lateImageContext)
        tabBarController.title = lateCase.title
        tabBarController.hidesBottomBarWhenPushed = true
        return tabBarController
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // [EN] A badge, shown before the picture changes: it must end on the picture. [CN] 在图片变化之前显示角标：最终应位于图片上。
        CYLPlusButton(forOwner: self)?.cyl_showBadgeValue("1", animationType: .none)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            CYLPlusButton.removePlusButton(forTabBarContext: CYLSettingsDemo.lateImageContext)
        }
    }
}
