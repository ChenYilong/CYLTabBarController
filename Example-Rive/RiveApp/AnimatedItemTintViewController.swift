//
//  AnimatedItemTintViewController.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] The tint API of `CYLAnimatedItemView` (docs/Animated-Item.md, "Animation tint and static icons (tint)"): `animationTint`
 *      ("title", or "#RRGGBB" / "#RRGGBBAA") and `animationDarkTint` (the Dark Mode color of a fixed tint), on the course's
 *      menu_button.riv (a Rive item) and a one-color-capable Lottie file, each normal and selected. The rows are: nothing set (the
 *      built-in default), "title", "Title" (case-sensitive: invalid, counts as unset), a fixed "#RRGGBB" with a dark color, and an 8-digit
 *      "#RRGGBBAA" with a dark color. Below them, the Liquid Glass inset: `itemContentHorizontalInset` unset (14 pt on glass) and 0, normal
 *      and selected. Launch arguments (screenshots): `-cylScreen tint` opens the page from the second tab (the next tab in turn after the
 *      User tab's Engine API button, AGENTS.md "Demo table rows"); `-cylColorMode dark|light` sets the window's color mode, as the
 *      HarmonyOS launch parameter of the same name.
 * [CN] `CYLAnimatedItemView` 的着色 API（docs/Animated-Item.md「动画着色与静态图标（tint）」）：`animationTint`（"title"，或 "#RRGGBB" / "#RRGGBBAA"）
 *      与 `animationDarkTint`（固定着色在深色模式下的颜色），用于课程的 menu_button.riv（Rive 条目）与一个 Lottie 文件，各有常态与选中。
 *      各行：均未设置（内置默认）、"title"、"Title"（区分大小写：无效，等同未设置）、带深色的固定 "#RRGGBB"、带深色的 8 位 "#RRGGBBAA"。
 *      其下是液态玻璃的内缩：`itemContentHorizontalInset` 未设置（玻璃上为 14 pt）与 0，各有常态与选中。启动参数（截图）：`-cylScreen tint` 从第二个
 *      Tab 打开本页（轮到 User Tab 的 Engine API 按钮之后的下一个 Tab，AGENTS.md「Demo table rows」）；`-cylColorMode dark|light` 设置窗口的
 *      颜色模式，与鸿蒙同名启动参数相同。
 */
final class AnimatedItemTintViewController: UIViewController {

    private struct TintCase {
        let name: String
        let tint: String?
        let darkTint: String?
    }

    private static let iconSize = CGSize(width: 64, height: 64)
    private static let launchScreenName = "tint"
    private static var didOpenLaunchScreen = false

    private static let riveCases: [TintCase] = [
        TintCase(name: "unset", tint: nil, darkTint: nil),
        TintCase(name: "title", tint: "title", darkTint: nil),
        TintCase(name: "Title (invalid)", tint: "Title", darkTint: nil),
        TintCase(name: "#FF3B30 / dark #34C759", tint: "#FF3B30", darkTint: "#34C759"),
        TintCase(name: "#0A84FF80 / dark #FFD60AFF", tint: "#0A84FF80", darkTint: "#FFD60AFF"),
    ]

    private var items: [CYLAnimatedItemView] = []

    /**
     * [EN] `-cylScreen tint`: selects the second tab and opens this page, once (screenshots).
     * [CN] `-cylScreen tint`：选中第二个 Tab 并打开本页，仅一次（用于截图）。
     */
    static func openAtLaunchIfRequested(in tabBarController: UITabBarController) {
        guard !didOpenLaunchScreen, UserDefaults.standard.string(forKey: "cylScreen") == launchScreenName,
              let navigationController = tabBarController.viewControllers?[1] as? UINavigationController else { return }
        didOpenLaunchScreen = true
        tabBarController.selectedIndex = 1
        navigationController.pushViewController(AnimatedItemTintViewController(), animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = cylDemoLocalizedString("Animation tint")
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "AnimatedItemTintPage"

        var rows: [UIView] = [heading(cylDemoLocalizedString("Rive: menu_button.riv, normal and selected"))]
        for tintCase in Self.riveCases {
            rows.append(tintRow(tintCase, makeAnimationURL: Self.riveURL))
        }
        rows.append(heading(cylDemoLocalizedString("Lottie: a fixed tint wins on every engine")))
        rows.append(tintRow(TintCase(name: "#FF3B30FF / dark #34C759FF", tint: "#FF3B30FF", darkTint: "#34C759FF"), makeAnimationURL: Self.lottieURL))
        rows.append(heading(cylDemoLocalizedString("Liquid Glass: itemContentHorizontalInset")))
        rows.append(glassRow(name: "unset (14 pt on glass)", inset: nil))
        rows.append(glassRow(name: "0", inset: 0))

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
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

    // MARK: - Files

    /// [EN] The state machine input "isOpen" is held until it is stopped ("duration" 0), as `RiveMenuButtonDemoView`. [CN] 状态机输入 "isOpen" 保持到停止（"duration" 为 0），同 `RiveMenuButtonDemoView`。
    private static func riveURL() -> URL? {
        CYLTabBarAnimationURLWithOptions(Bundle.main.url(forResource: "menu_button", withExtension: "riv"), [
            .riveStateMachine: "State Machine",
            .riveInput: "isOpen",
            .riveActiveDuration: "0",
        ] as [CYLTabBarAnimationOption: String])
    }

    private static func lottieURL() -> URL? {
        Bundle.main.url(forResource: "green_lottie_tab_home", withExtension: "json")
    }

    // MARK: - Rows

    private func heading(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    /// [EN] One tint setting: its text, then the item normal and selected. [CN] 一种着色设置：其文字，然后是常态与选中的条目。
    private func tintRow(_ tintCase: TintCase, makeAnimationURL: () -> URL?) -> UIView {
        let name = UILabel()
        name.text = "animationTint: \(tintCase.tint.map { "\"\($0)\"" } ?? "nil")" + (tintCase.darkTint.map { "\nanimationDarkTint: \"\($0)\"" } ?? "")
        name.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        name.numberOfLines = 0
        name.isAccessibilityElement = false
        let slug = tintCase.name.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "")
        let normal = tintItem(tintCase, selected: false, makeAnimationURL: makeAnimationURL, identifier: "AnimatedItemTint-\(slug)-normal")
        let selected = tintItem(tintCase, selected: true, makeAnimationURL: makeAnimationURL, identifier: "AnimatedItemTint-\(slug)-selected")
        let row = UIStackView(arrangedSubviews: [name, normal, selected])
        row.alignment = .center
        row.spacing = 16
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        row.backgroundColor = .secondarySystemGroupedBackground
        row.layer.cornerRadius = 10
        row.layer.cornerCurve = .continuous
        return row
    }

    private func tintItem(_ tintCase: TintCase, selected: Bool, makeAnimationURL: () -> URL?, identifier: String) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView()
        item.iconSize = Self.iconSize
        item.animationURL = makeAnimationURL()
        item.animationLoops = true
        item.animationTint = tintCase.tint
        item.animationDarkTint = tintCase.darkTint
        item.isSelected = selected
        item.isUserInteractionEnabled = false
        item.accessibilityIdentifier = identifier
        item.accessibilityLabel = "\(tintCase.name), \(selected ? "selected" : "normal")"
        item.widthAnchor.constraint(equalToConstant: Self.iconSize.width).isActive = true
        item.heightAnchor.constraint(equalToConstant: Self.iconSize.height).isActive = true
        items.append(item)
        return item
    }

    /// [EN] Two glass tags with a title (normal and selected) over a colorful strip, so the glass shows. [CN] 两个带标题的玻璃标签（常态与选中），位于彩色条带上，便于看出玻璃效果。
    private func glassRow(name: String, inset: CGFloat?) -> UIView {
        let label = UILabel()
        label.text = "itemContentHorizontalInset: \(name)"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        let tags = [false, true].map { selected -> CYLAnimatedItemView in
            let item = CYLAnimatedItemView()
            item.axis = .horizontal
            item.title = selected ? "Selected" : "Normal"
            item.iconSize = CGSize(width: 24, height: 24)
            item.image = UIImage(systemName: "star")
            item.selectedImage = UIImage(systemName: "star.fill")
            item.itemBackgroundStyle = .liquidGlass
            item.itemContentHorizontalInset = inset
            item.isSelected = selected
            item.isUserInteractionEnabled = false
            item.accessibilityIdentifier = "AnimatedItemGlass-\(inset.map { String(Int($0)) } ?? "unset")-\(selected ? "selected" : "normal")"
            return item
        }
        let strip = GradientStripView()
        let tagStack = UIStackView(arrangedSubviews: tags + [UIView()])
        tagStack.spacing = 12
        tagStack.alignment = .center
        tagStack.translatesAutoresizingMaskIntoConstraints = false
        strip.addSubview(tagStack)
        NSLayoutConstraint.activate([
            tagStack.topAnchor.constraint(equalTo: strip.topAnchor, constant: 16),
            tagStack.bottomAnchor.constraint(equalTo: strip.bottomAnchor, constant: -16),
            tagStack.leadingAnchor.constraint(equalTo: strip.leadingAnchor, constant: 16),
            tagStack.trailingAnchor.constraint(equalTo: strip.trailingAnchor, constant: -16),
        ])
        let row = UIStackView(arrangedSubviews: [label, strip])
        row.axis = .vertical
        row.spacing = 6
        return row
    }
}

/// [EN] A colorful gradient behind the glass tags. [CN] 玻璃标签后面的彩色渐变。
private final class GradientStripView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let gradient = layer as? CAGradientLayer
        gradient?.colors = [UIColor.systemOrange.cgColor, UIColor.systemPink.cgColor, UIColor.systemPurple.cgColor]
        gradient?.startPoint = CGPoint(x: 0, y: 0.5)
        gradient?.endPoint = CGPoint(x: 1, y: 0.5)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
