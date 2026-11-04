//
//  GalleryPageViewController.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The page shown in every tab: a line of text that changes every two seconds, and a button that pops or dismisses.
//      Tapping anywhere else pushes a detail page (or presents it without a navigation controller).
// [CN] 每个 Tab 中显示的页面：每两秒更换一次的文字，以及返回或关闭的按钮。点击其他位置会 push 一个详情页（没有导航控制器时 present）。
final class GalleryPageViewController: UIViewController {

    static let lines = [
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
            traits.userInterfaceStyle == .dark ? .systemBackground : Gallery.rgb(244, 245, 245)
        }

        backgroundButton.addTarget(self, action: #selector(pushDetailPage), for: .touchUpInside)
        view.addSubview(backgroundButton)

        textLabel.font = .systemFont(ofSize: 24, weight: .medium)
        textLabel.textColor = .secondaryLabel
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.text = randomLine(excluding: nil)
        view.addSubview(textLabel)

        let buttonColor = Gallery.gray(100)
        closeButton.setTitle("  Click to pop or dismiss  ", for: .normal)
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
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.textLabel.text = self.randomLine(excluding: self.textLabel.text)
            self.view.setNeedsLayout()
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

    private func randomLine(excluding current: String?) -> String {
        var line = current
        while line == nil || line == current {
            line = Self.lines.randomElement()
        }
        return line ?? ""
    }

    @objc private func pushDetailPage() {
        let detail = GalleryPageViewController()
        detail.title = "Detail"
        detail.hidesBottomBarWhenPushed = true
        if let navigationController = navigationController {
            navigationController.pushViewController(detail, animated: true)
            return
        }
        present(detail, animated: true)
    }

    @objc private func popOrDismiss() {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
            return
        }
        dismiss(animated: true)
    }
}

// [EN] A long list, to see `cyl_reselectBehavior` scroll it back to the top.
// [CN] 一个长列表，用于观察 `cyl_reselectBehavior` 滚动回顶部。
final class GalleryListViewController: UITableViewController {

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row") ?? UITableViewCell(style: .default, reuseIdentifier: "row")
        cell.textLabel?.text = "Row \(indexPath.row + 1): tap to push, tap the tab again to go back"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let page = GalleryPageViewController()
        page.title = "Row \(indexPath.row + 1)"
        navigationController?.pushViewController(page, animated: true)
    }
}

// [EN] Light navigation bar; pages pushed after the root hide the tab bar.
// [CN] 浅色导航栏；根页面之后 push 的页面隐藏 TabBar。
final class GalleryNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let titleColor = Gallery.rgb(38, 38, 38)
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
        if !viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}
