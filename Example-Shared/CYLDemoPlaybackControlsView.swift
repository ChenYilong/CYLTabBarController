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
    private let pauseSwitch = UISwitch()
    private let pauseCountLabel = UILabel()
    private let lastEventLabel = UILabel()
    /// [EN] The switch state outlives the card: the library observes only scroll views that move to a window after the observer
    ///      exists, so a page opened after the switch was turned on is the one that pauses; its card shows the switch ON.
    /// [CN] 开关状态比卡片存活更久：库只观察在观察者存在之后才移入窗口的 scroll view，因此开关打开之后再打开的页面才会暂停；其卡片显示开关为打开。
    private static var pausesWhileScrolling = false
    private let card = UIStackView()
    private weak var hostTableView: UITableView?

    /**
     * [EN] Puts the controls above the rows of `tableView`, for the tab bar controller of `viewController`.
     * [CN] 把控件放在 `tableView` 的各行之上，控制 `viewController` 所在的 TabBarController。
     */
    @objc(installOnTableView:viewController:)
    @discardableResult
    static func install(on tableView: UITableView, in viewController: UIViewController) -> CYLDemoPlaybackControlsView {
        let view = make(in: viewController)
        view.hostTableView = tableView
        view.resizeForTableHeader()
        tableView.tableHeaderView = view
        return view
    }

    /**
     * [EN] Adds a row at the bottom of the card (the root app adds its "Release the tab bar controller" row) and sizes the
     *      table header again.
     * [CN] 在卡片底部添加一行（根 App 添加它的「释放 TabBarController」行），并重新计算表头高度。
     */
    func appendRow(_ row: UIView) {
        card.addArrangedSubview(row)
        resizeForTableHeader()
        hostTableView?.tableHeaderView = self
    }

    private func resizeForTableHeader() {
        let tableWidth = hostTableView?.bounds.width ?? 0
        let width = tableWidth > 0 ? tableWidth : UIScreen.main.bounds.width
        let height = systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                             withHorizontalFittingPriority: .required,
                                             verticalFittingPriority: .fittingSizeLevel).height
        frame = CGRect(x: 0, y: 0, width: width, height: height)
    }

    /**
     * [EN] The controls as a view for Auto Layout (a page that is not a table, such as the Rive example's engine API page).
     * [CN] 作为 Auto Layout 视图的控件（不是列表的页面，例如 Rive 示例的引擎 API 页）。
     */
    static func make(in viewController: UIViewController) -> CYLDemoPlaybackControlsView {
        CYLDemoPlaybackControlsView(viewController: viewController)
    }

    private init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: .zero)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var tabBarController: CYLTabBarController? {
        viewController?.cylTabBarController
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        pauseSwitch.isOn = Self.pausesWhileScrolling
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

        // [EN] Pause while scrolling: every playing icon pauses while the user scrolls a list and resumes afterwards
        //      (CYLAnimationEventBridge, the events cyl.animation.didPause / didResume). [CN] 滚动时暂停：用户滚动列表时所有播放中的图标暂停，滚动结束后恢复。
        let pauseLabel = UILabel()
        pauseLabel.text = cylDemoLocalizedString("Pause while scrolling")
        pauseLabel.isAccessibilityElement = false
        pauseSwitch.accessibilityLabel = cylDemoLocalizedString("Pause while scrolling")
        pauseSwitch.addTarget(self, action: #selector(pauseChanged), for: .valueChanged)
        // [EN] The counter (pauses / resumes since launch) shows the scroll pause working: digits only, so nothing to localize.
        // [CN] 计数（自启动以来的暂停 / 恢复次数）显示滚动暂停在起作用：只有数字，无需本地化。
        pauseCountLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        pauseCountLabel.textColor = .secondaryLabel
        pauseCountLabel.accessibilityLabel = cylDemoLocalizedString("Pause while scrolling")
        pauseCountLabel.accessibilityIdentifier = "CYLDemoPauseCounter"
        pauseCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        updatePauseCount()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePauseCount), name: CYLAnimationEventBridge.countsDidChangeNotification, object: nil)
        let pauseRow = UIStackView(arrangedSubviews: [pauseLabel, pauseCountLabel, pauseSwitch])
        pauseRow.spacing = 8
        pauseRow.alignment = .center

        // [EN] The name of the last animation event the bridge delivered (didStart / didStop / didPause / didResume), next to the
        //      counter, so a run shows the events without the lifecycle log. Event names are identifiers, so nothing to localize.
        // [CN] 桥接最近一次送达的动画事件名称（didStart / didStop / didPause / didResume），显示在计数旁边，使运行时无需生命周期日志就能看到事件。
        //      事件名称是标识符，无需本地化。
        lastEventLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        lastEventLabel.textColor = .secondaryLabel
        lastEventLabel.text = "last event: -"
        lastEventLabel.accessibilityIdentifier = "CYLDemoLastBridgeEvent"
        for name in ["didStart", "didStop", "didPause", "didResume"] {
            NotificationCenter.default.addObserver(self, selector: #selector(animationEventArrived(_:)),
                                                   name: Notification.Name("cyl.animation.\(name)"), object: nil)
        }

        for row in [playAllButton, speedRow, loopRow, pauseRow, lastEventLabel] {
            card.addArrangedSubview(row)
        }
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

    /// [EN] Shows "paused / resumed" counts. [CN] 显示「暂停 / 恢复」次数。
    @objc private func updatePauseCount() {
        pauseCountLabel.text = "⏸ \(CYLAnimationEventBridge.pauseCount)  ▶ \(CYLAnimationEventBridge.resumeCount)"
        pauseCountLabel.accessibilityValue = "\(CYLAnimationEventBridge.pauseCount) / \(CYLAnimationEventBridge.resumeCount)"
    }

    @objc private func animationEventArrived(_ note: Notification) {
        lastEventLabel.text = "last event: \(note.name.rawValue)"
    }

    @objc private func pauseChanged() {
        Self.pausesWhileScrolling = pauseSwitch.isOn
        CYLAnimationEventBridge.pausesAnimationsWhileUserScrolls(pauseSwitch.isOn)
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
