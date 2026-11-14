//
//  CYLDemoPlaybackControlsView.swift
//  CYLTabBarController examples
//
//  Created on 2026/11/14: the playback controls AGENTS.md asks of every example page that shows tab icon animations
//  ("Animated icon examples: Play all, speed slider, loop switch").
//

import UIKit
import CYLTabBarController

/**
 * [EN] Play all, a speed slider and a loop switch for the tab icon animations of the page's tab bar controller. They
 *      combine into one playback policy, applied live: Play all restarts every icon from progress 0; the slider
 *      (0.25× to 3×) sets `tabBarItemAnimationSpeed`; the switch sets `tabBarItemAnimationLoops`.
 * [CN] 为页面所在 TabBarController 的 Tab 图标动画提供「全部播放」、倍速滑块与循环开关，三者组合成一个实时生效的播放策略：「全部播放」让每个图标
 *      从进度 0 重新播放；滑块（0.25× 至 3×）设置 `tabBarItemAnimationSpeed`；开关设置 `tabBarItemAnimationLoops`。
 */
@objc(CYLDemoPlaybackControlsView)
final class CYLDemoPlaybackControlsView: UIView {

    private static let minimumSpeed: Float = 0.25
    private static let maximumSpeed: Float = 3

    private weak var viewController: UIViewController?
    private let playAllButton = UIButton(type: .system)
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
    private let loopSwitch = UISwitch()

    /**
     * [EN] Puts the controls above the rows of `tableView`, for the tab bar controller of `viewController`.
     * [CN] 把控件放在 `tableView` 的各行之上，控制 `viewController` 所在的 TabBarController。
     */
    @objc(installOnTableView:viewController:)
    static func install(on tableView: UITableView, in viewController: UIViewController) {
        let view = CYLDemoPlaybackControlsView(viewController: viewController)
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : UIScreen.main.bounds.width
        let height = view.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel).height
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = view
    }

    private init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: .zero)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var tabBarController: CYLTabBarController? {
        viewController?.cyl_tabBarController
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // [EN] Show the current policy (the app or another page may have changed it). [CN] 显示当前策略（App 或其他页面可能已修改）。
        guard window != nil, let tabBarController else {
            return
        }
        speedSlider.value = Float(tabBarController.tabBarItemAnimationSpeed)
        loopSwitch.isOn = tabBarController.tabBarItemAnimationLoops
        updateSpeedValue()
    }

    private func setUpViews() {
        let titleLabel = UILabel()
        titleLabel.text = cylDemoLocalizedString("Playback").uppercased(with: Locale.current)
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textColor = .secondaryLabel
        titleLabel.accessibilityTraits = .header

        playAllButton.setTitle(cylDemoLocalizedString("Play all"), for: .normal)
        playAllButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        playAllButton.contentHorizontalAlignment = .leading
        playAllButton.addTarget(self, action: #selector(playAll), for: .touchUpInside)

        let speedLabel = UILabel()
        speedLabel.text = cylDemoLocalizedString("Speed")
        speedSlider.minimumValue = Self.minimumSpeed
        speedSlider.maximumValue = Self.maximumSpeed
        speedSlider.value = 1
        speedSlider.accessibilityLabel = cylDemoLocalizedString("Speed")
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.font = .monospacedDigitSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        speedValueLabel.textAlignment = .right
        speedValueLabel.isAccessibilityElement = false
        speedValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        speedValueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        let speedRow = UIStackView(arrangedSubviews: [speedLabel, speedSlider, speedValueLabel])
        speedRow.spacing = 12
        speedRow.alignment = .center
        speedLabel.setContentHuggingPriority(.required, for: .horizontal)

        let loopLabel = UILabel()
        loopLabel.text = cylDemoLocalizedString("Loop")
        loopLabel.isAccessibilityElement = false
        loopSwitch.accessibilityLabel = cylDemoLocalizedString("Loop")
        loopSwitch.addTarget(self, action: #selector(loopChanged), for: .valueChanged)
        let loopRow = UIStackView(arrangedSubviews: [loopLabel, loopSwitch])
        loopRow.alignment = .center

        let card = UIStackView(arrangedSubviews: [playAllButton, speedRow, loopRow])
        card.axis = .vertical
        card.spacing = 12
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.layer.cornerCurve = .continuous

        let stack = UIStackView(arrangedSubviews: [titleLabel, card])
        stack.axis = .vertical
        stack.spacing = 6
        stack.setCustomSpacing(6, after: titleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        // [EN] The margins of an inset grouped section, so the card lines up with the rows below.
        // [CN] 与 Inset Grouped 分组相同的边距，使卡片与下方各行对齐。
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        updateSpeedValue()
    }

    @objc private func playAll() {
        tabBarController?.cyl_playAllTabBarItemAnimations()
    }

    @objc private func speedChanged() {
        // [EN] Steps of 0.05, so the value reads well. [CN] 以 0.05 为步长，便于阅读。
        speedSlider.value = (speedSlider.value / 0.05).rounded() * 0.05
        tabBarController?.tabBarItemAnimationSpeed = CGFloat(speedSlider.value)
        updateSpeedValue()
    }

    @objc private func loopChanged() {
        tabBarController?.tabBarItemAnimationLoops = loopSwitch.isOn
    }

    private func updateSpeedValue() {
        let speed = NumberFormatter.localizedString(from: NSNumber(value: Double(speedSlider.value)), number: .decimal)
        speedValueLabel.text = "\(speed)×"
        speedSlider.accessibilityValue = String(format: cylDemoLocalizedString("%@ times"), speed)
    }
}
