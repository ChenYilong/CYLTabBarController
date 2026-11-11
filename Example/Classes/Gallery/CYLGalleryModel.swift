//
//  CYLGalleryModel.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/**
 * [EN] One row of the tab bar gallery: a tab bar built with the library's public API, presented when the row is tapped
 *      (or pushed onto the gallery's navigation controller when `pushes` is true).
 * [CN] TabBar 图库中的一行：用本库公开 API 构建的 TabBar，点击该行时展示（`pushes` 为 true 时 push 到图库的导航控制器）。
 */
final class CYLGalleryScene {
    let title: String
    let subtitle: String
    let builder: () -> UIViewController
    let didPresent: ((UIViewController) -> Void)?
    let pushes: Bool

    init(title: String, subtitle: String, pushes: Bool = false, builder: @escaping () -> UIViewController,
         didPresent: ((UIViewController) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.pushes = pushes
        self.builder = builder
        self.didPresent = didPresent
    }
}

/**
 * [EN] A section of the gallery: a title and its scenes. [CN] 图库中的一组：标题及其场景。
 */
final class CYLGallerySection {
    let title: String
    let scenes: [CYLGalleryScene]

    init(title: String, scenes: [CYLGalleryScene]) {
        self.title = title
        self.scenes = scenes
    }
}

/**
 * [EN] The page shown in every tab: a line of text that changes every two seconds, and a button that pops or dismisses.
 *      Tapping anywhere else pushes a detail page (or presents it without a navigation controller).
 * [CN] 每个 Tab 中显示的页面：每两秒更换一次的文字，以及返回或关闭的按钮。点击其他位置会 push 一个详情页（没有导航控制器时 present）。
 */
final class CYLGalleryPageViewController: UIViewController {

    private static let lines = [
        "Tap a tab to switch pages.",
        "Tap the selected tab again to see its reselect behavior.",
        "Press and hold a tab to see its pressed animation.",
        "Tap anywhere on this page to push a detail page.",
        "Every tab bar here is built with the public API.",
        "Badges, colors and fonts can differ from tab to tab.",
        "The same code runs with and without Liquid Glass.",
        "Use the button below to go back to the gallery.",
    ]

    private let textLabel = UILabel()
    private let backgroundButton = UIButton(type: .custom)
    private let closeButton = UIButton(type: .custom)
    private var textTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemBackground : CYLGallery.rgb(244, 245, 245)
        }
        backgroundButton.addTarget(self, action: #selector(pushDetailPage), for: .touchUpInside)
        view.addSubview(backgroundButton)

        textLabel.font = .systemFont(ofSize: 24, weight: .medium)
        textLabel.textColor = .secondaryLabel
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.text = Self.randomLine(excluding: nil)
        view.addSubview(textLabel)

        let buttonColor = CYLGallery.gray(100)
        closeButton.setTitle("  \(cylDemoLocalizedString("点击返回或关闭"))  ", for: .normal)
        closeButton.setTitleColor(buttonColor, for: .normal)
        closeButton.layer.borderWidth = 2
        closeButton.layer.borderColor = buttonColor.cgColor
        closeButton.layer.cornerRadius = 16
        closeButton.addTarget(self, action: #selector(popOrDismiss), for: .touchUpInside)
        view.addSubview(closeButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textTimer?.invalidate()
        textTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            textLabel.text = Self.randomLine(excluding: textLabel.text)
            view.setNeedsLayout()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        textTimer?.invalidate()
        textTimer = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.bounds
        backgroundButton.frame = bounds
        let padding: CGFloat = 24
        let labelWidth = bounds.width - padding * 2
        let labelSize = textLabel.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude))
        textLabel.frame = CGRect(x: padding, y: (bounds.height - labelSize.height) / 2 - 24, width: labelWidth, height: labelSize.height)
        let buttonSize = closeButton.sizeThatFits(bounds.size)
        closeButton.frame = CGRect(x: (bounds.width - buttonSize.width) / 2, y: bounds.height - 120, width: buttonSize.width, height: 42)
    }

    private static func randomLine(excluding current: String?) -> String {
        var line = current
        while line == nil || line == current {
            line = lines.randomElement()
        }
        return line ?? lines[0]
    }

    @objc private func pushDetailPage() {
        let detail = CYLGalleryPageViewController()
        detail.title = cylDemoLocalizedString("详情")
        detail.hidesBottomBarWhenPushed = true
        if let navigationController {
            navigationController.pushViewController(detail, animated: true)
            return
        }
        present(detail, animated: true)
    }

    @objc private func popOrDismiss() {
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
            return
        }
        dismiss(animated: true)
    }
}

/**
 * [EN] A long list, to see `cyl_reselectBehavior` scroll it back to the top. Inset grouped, like every demo list.
 * [CN] 一个长列表，用于观察 `cyl_reselectBehavior` 滚动回顶部。与所有示例列表一样使用 inset grouped。
 */
final class CYLGalleryListViewController: UITableViewController {

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] Pull to refresh, empty / no-network placeholders and the offline red bar (CYLTableViewPlaceHolder).
        // [CN] 下拉刷新、无数据 / 无网络占位图与断网红条（CYLTableViewPlaceHolder）。
        CYLDemoPlaceholder.install(on: tableView, in: self, animation: .lottie)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row") ?? UITableViewCell(style: .default, reuseIdentifier: "row")
        cell.textLabel?.text = "Row \(indexPath.row + 1): tap to push, tap the tab again to go back"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let page = CYLGalleryPageViewController()
        page.title = "Row \(indexPath.row + 1)"
        navigationController?.pushViewController(page, animated: true)
    }
}

/**
 * [EN] Light navigation bar; pages pushed after the root hide the tab bar, except under a list (the reselect scene).
 * [CN] 浅色导航栏；根页面之后 push 的页面隐藏 TabBar，列表（重复点击场景）之下的除外。
 */
final class CYLGalleryNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let titleColor = CYLGallery.rgb(38, 38, 38)
        navigationBar.isTranslucent = true
        navigationBar.tintColor = titleColor
        navigationBar.titleTextAttributes = [.foregroundColor: titleColor, .font: UIFont.systemFont(ofSize: 16)]
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if !(viewControllerToPresent is UIAlertController) {
            viewControllerToPresent.modalPresentationStyle = .fullScreen
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // [EN] The reselect scene (a list at the root) keeps the tab bar on pushed pages: its rows say "tap the tab again to
        //      go back", which needs the tab bar.
        // [CN] 重复点击场景（根页面为列表）在 push 的页面上保留 TabBar：其行写着「再次点击 Tab 返回」，需要能看到 TabBar。
        let keepsTabBar = viewControllers.first is CYLGalleryListViewController
        if !viewControllers.isEmpty, !keepsTabBar {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}

// MARK: - Tab button animations

/**
 * [EN] A springy scale on select and on reselect. [CN] 选中与重复点击时的弹性缩放。
 */
final class CYLGalleryBounceAnimation: NSObject, CYLTabButtonAnimation {
    func cylPlaySelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        CYLGallery.playKeyframes(on: iconView, keyPath: "transform.scale", values: [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0], duration: 0.6)
    }

    func cylPlayReselectAnimation(withTabButton button: UIControl, iconView: UIView, titleLabel: UILabel?) {
        cylPlaySelectAnimation(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
    }
}

/**
 * [EN] Icons drawn 15% larger; a press shrinks the icon to 80% and the release brings it back.
 * [CN] 图标放大 15% 显示；按下缩小到 80%，抬起后恢复。
 */
final class CYLGalleryHighlightAnimation: NSObject, CYLTabButtonAnimation {
    private static let largeIconScale: CGFloat = 1.15

    func cylPlaySelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        iconView.transform = CGAffineTransform(scaleX: Self.largeIconScale, y: Self.largeIconScale)
    }

    func cylPlayHighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeIconScale * 0.8, y: Self.largeIconScale * 0.8)
        }
    }

    func cylPlayDehighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeIconScale, y: Self.largeIconScale)
        }
    }
}

/**
 * [EN] Press animation plus a full turn on reselect (the newer protocol hooks). [CN] 按下动画，加上重复点击时旋转一周（新增的协议方法）。
 */
final class CYLGalleryPressAndReselectAnimation: CYLTabButtonPressAnimation {
    override func cylPlayReselectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        CYLGallery.playKeyframes(on: iconView, keyPath: "transform.rotation.z", values: [0, Double.pi, 2 * Double.pi], duration: 0.5)
    }
}

extension CYLGallery {
    /**
     * [EN] When a badge appears, the icon jumps (badge-changed hook), built with `CYLTabButtonBlockAnimation`: only the
     *      block that is set plays, so selecting the tab plays nothing.
     * [CN] 角标出现时图标跳动（角标变化回调），用 `CYLTabButtonBlockAnimation` 实现：只有设置了的 block 会播放，选中 Tab 时不播放动画。
     */
    static func badgeJumpAnimation() -> CYLTabButtonBlockAnimation {
        let animation = CYLTabButtonBlockAnimation()
        animation.badgeChangedAnimation = { _, iconView, _ in
            playKeyframes(on: iconView, keyPath: "transform.translation.y", values: [0, -8, 4, -4, 3, -2, 0], duration: 0.6)
        }
        return animation
    }

    /**
     * [EN] When a badge appears, the badge itself scales in (badge-changed hook, `CYLTabButtonBlockAnimation`).
     * [CN] 角标出现时角标自身缩放弹出（角标变化回调，`CYLTabButtonBlockAnimation`）。
     */
    static func badgeScaleAnimation() -> CYLTabButtonBlockAnimation {
        let animation = CYLTabButtonBlockAnimation()
        animation.badgeChangedAnimation = { _, iconView, badgeView in
            playKeyframes(on: badgeView ?? iconView, keyPath: "transform.scale", values: [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0], duration: 0.6)
        }
        return animation
    }
}
