//
//  CYLDefaultTintViewController.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The built-in default tint (docs/Animated-Item.md, "Animation tint and static icons (tint)"), one to one with the HarmonyOS example
      page `pages/DefaultTint.ets`: four `CYLAnimatedItemView` with NO tint property set. A file detected as one color (the camera) is
      drawn in the built-in color of its state and color mode (normal: the label color, selected: the tint color), so it stays visible in
      dark mode; a multi-color file keeps its own colors. The files are the HarmonyOS example's own (`default_tint_one_color.json`,
      `default_tint_multi_color.json`), referenced from the project, not copied. Launch arguments (screenshots): `-cylScreen default-tint`
      with `-CYLDemoSelectedTab city` opens this page from the second tab; `-cylColorMode dark|light` sets the window's color mode.
 [CN] 内置默认着色（docs/Animated-Item.md「动画着色与静态图标（tint）」），与鸿蒙示例页 `pages/DefaultTint.ets` 一一对应：四个未设置任何着色
      属性的 `CYLAnimatedItemView`。被识别为单色的文件（相机）按其状态与颜色模式使用内置颜色（常态：标签色，选中：tintColor），因此在深色
      模式下仍然可见；多色文件保持自身颜色。文件取自鸿蒙示例（`default_tint_one_color.json`、`default_tint_multi_color.json`），在工程中引用，
      不复制。启动参数（截图）：`-cylScreen default-tint` 与 `-CYLDemoSelectedTab city` 从第二个 Tab 打开本页；`-cylColorMode dark|light`
      设置窗口的颜色模式。
 */
final class CYLDefaultTintViewController: UIViewController {

    /// [EN] The launch argument that opens this page (the name of the HarmonyOS parameter). [CN] 打开本页的启动参数（与鸿蒙参数同名）。
    static let launchScreenName = "default-tint"

    /// [EN] True when the app was launched with `-cylScreen default-tint`. [CN] 以 `-cylScreen default-tint` 启动时为 true。
    static var isRequestedAtLaunch: Bool {
        UserDefaults.standard.string(forKey: "cylScreen") == launchScreenName
    }

    private static let iconSize = CGSize(width: 64, height: 64)
    private var items: [CYLAnimatedItemView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = cylDemoLocalizedString("Default tint")
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "CYLDefaultTintPage"

        let content = UIStackView(arrangedSubviews: [
            caption(cylDemoLocalizedString("One color file: the built-in tint")),
            row(file: "default_tint_one_color", idPrefix: "cyl-default-tint-one"),
            caption(cylDemoLocalizedString("Multi-color file: its own colors")),
            row(file: "default_tint_multi_color", idPrefix: "cyl-default-tint-multi"),
        ])
        content.axis = .vertical
        content.spacing = 12
        content.setCustomSpacing(32, after: content.arrangedSubviews[1])
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        items.forEach { $0.playAnimation() }
        // [EN] `-cylColorMode dark|light`, as the HarmonyOS launch parameter `cylColorMode`. [CN] `-cylColorMode dark|light`，同鸿蒙启动参数 `cylColorMode`。
        switch UserDefaults.standard.string(forKey: "cylColorMode") {
        case "dark": view.window?.overrideUserInterfaceStyle = .dark
        case "light": view.window?.overrideUserInterfaceStyle = .light
        default: break
        }
    }

    // MARK: - Views

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }

    /// [EN] One file, normal and selected, side by side. [CN] 同一个文件，常态与选中并排。
    private func row(file: String, idPrefix: String) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [
            cell(file: file, selected: false, caption: cylDemoLocalizedString("normal"), identifier: "\(idPrefix)-normal"),
            cell(file: file, selected: true, caption: cylDemoLocalizedString("selected"), identifier: "\(idPrefix)-selected"),
        ])
        row.distribution = .fillEqually
        return row
    }

    private func cell(file: String, selected: Bool, caption text: String, identifier: String) -> UIStackView {
        // [EN] No tint property is set: the defaults are what is shown. [CN] 不设置任何着色属性：显示的是默认值。
        let item = CYLAnimatedItemView()
        item.iconSize = Self.iconSize
        item.animationURL = Bundle.main.url(forResource: file, withExtension: "json")
        item.animationLoops = true
        item.isSelected = selected
        item.isUserInteractionEnabled = false
        item.accessibilityIdentifier = identifier
        item.accessibilityLabel = text
        item.widthAnchor.constraint(equalToConstant: Self.iconSize.width).isActive = true
        item.heightAnchor.constraint(equalToConstant: Self.iconSize.height).isActive = true
        items.append(item)

        let label = caption(text)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .label
        label.isAccessibilityElement = false
        let stack = UIStackView(arrangedSubviews: [item, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }
}
