//
//  AnimatedItemEngineAPIViewController.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] The cross-platform engine API of `CYLAnimatedItemView` (docs/Animated-Item.md, "Engine API across platforms"; HarmonyOS is
 *      the reference), driven by the host: every item has `drivesAnimationPlayback = false`, so the view applies none of its own
 *      speed, loop and resting-progress rules and only hands out `animationPlayer`. The page does what a HarmonyOS host does:
 *      "Play all" (`restartAnimation()`: `animationRestartToken` grows by one and each item restarts from progress 0), a tap on
 *      an item (`animationPlayer.play()`), "Stop at 50%" (a stop, then `progress = 0.5`), the speed slider (`speed` of each
 *      player, `animationSpeed` of each item) and the loop switch (`loops` of each player, `animationLoops` of each item). The
 *      label under the controls shows `onAnimationEnd` firing per engine. Engines of this example: Rive (icons.riv) and SVGA.
 * [CN] `CYLAnimatedItemView` 的跨平台引擎 API（docs/Animated-Item.md「Engine API across platforms」；以鸿蒙为准），由宿主驱动：每个条目的
 *      `drivesAnimationPlayback = false`，视图不再应用自己的速度、循环与静止进度规则，只提供 `animationPlayer`。本页做鸿蒙宿主所做的事：
 *      「全部播放」（`restartAnimation()`：`animationRestartToken` 加一，每个条目从进度 0 重新播放）、点击条目（`animationPlayer.play()`）、
 *      「停在 50%」（先停止，再 `progress = 0.5`）、倍速滑块（各播放器的 `speed`、各条目的 `animationSpeed`）与循环开关（各播放器的 `loops`、
 *      各条目的 `animationLoops`）。控件下方的标签显示各引擎的 `onAnimationEnd` 触发情况。本示例的引擎：Rive（icons.riv）与 SVGA。
 */
final class AnimatedItemEngineAPIViewController: UIViewController {

    private static let iconSize = CGSize(width: 64, height: 64)
    private static let minimumSpeed: Float = 0.25
    private static let maximumSpeed: Float = 3

    private struct EngineItem {
        let name: String
        let item: CYLAnimatedItemView
    }

    private var engineItems: [EngineItem] = []
    private var endCounts: [String: Int] = [:]

    private let tokenLabel = UILabel()
    private let endLabel = UILabel()
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
    private let loopSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = cylDemoLocalizedString("Animated item engine API")
        view.backgroundColor = .systemGroupedBackground
        view.accessibilityIdentifier = "AnimatedItemEngineAPIPage"
        engineItems = makeEngineItems()
        setUpViews()
        updateLabels()
    }

    // MARK: - Items

    /// [EN] One Rive item (the BELL artboard of icons.riv, its state machine input "active") and two SVGA items, through the
    ///      same `CYLAnimatedItemView`: only the file differs. [CN] 一个 Rive 条目（icons.riv 的 BELL 画板，状态机输入 "active"）与两个
    ///      SVGA 条目，都使用同一个 `CYLAnimatedItemView`：只有文件不同。
    private func makeEngineItems() -> [EngineItem] {
        var items: [EngineItem] = []
        if let url = CYLTabBarAnimationURLWithOptions(Bundle.main.url(forResource: "icons", withExtension: "riv"), [
            .riveArtboard: "BELL",
            .riveStateMachine: "BELL_Interactivity",
            .riveInput: "active",
        ] as [CYLTabBarAnimationOption: String]) {
            items.append(makeItem(name: "Rive", url: url))
        }
        for file in ["tab_home", "tab_profile"] {
            if let url = Bundle.main.url(forResource: file, withExtension: "svga") {
                items.append(makeItem(name: "SVGA \(file.replacingOccurrences(of: "tab_", with: ""))", url: url))
            }
        }
        return items
    }

    private func makeItem(name: String, url: URL) -> EngineItem {
        let item = CYLAnimatedItemView()
        item.axis = .vertical
        item.title = name
        item.iconSize = Self.iconSize
        item.drivesAnimationPlayback = false
        item.animationURL = url
        item.accessibilityLabel = name
        item.accessibilityIdentifier = "AnimatedItem-\(name.replacingOccurrences(of: " ", with: "-"))"
        item.addTarget(self, action: #selector(playItem(_:)), for: .touchUpInside)
        item.onAnimationEnd = { [weak self, weak item] in
            guard let item else { return }
            self?.endCounts[name, default: 0] += 1
            self?.updateLabels()
            self?.keepLooping(item)
        }
        return EngineItem(name: name, item: item)
    }

    // MARK: - Host-driven playback

    /// [EN] The host's own playback policy, applied to a player before it plays: the view does not do this with
    ///      `drivesAnimationPlayback = false`. A player applies only what it supports. [CN] 宿主自己的播放策略，在播放前应用到播放器：
    ///      `drivesAnimationPlayback = false` 时视图不做这件事。播放器只应用它支持的部分。
    private func applyPolicy(to item: CYLAnimatedItemView) {
        item.animationSpeed = CGFloat(speedSlider.value)
        item.animationLoops = loopSwitch.isOn
        guard let player = item.animationPlayer as? NSObject & CYLTabBarItemAnimationPlayer else { return }
        if player.supportsSpeed == true {
            player.setValue(CGFloat(speedSlider.value), forKey: "speed")
        }
        if player.supportsLoops == true {
            player.setValue(loopSwitch.isOn, forKey: "loops")
        }
    }

    /// [EN] The HarmonyOS `stopAtProgress(p)`: stops, then shows frame `p` where the player can seek. [CN] 鸿蒙的 `stopAtProgress(p)`：
    ///      先停止，播放器能定位时再显示 `p` 处的帧。
    private func stopAtProgress(_ progress: CGFloat, item: CYLAnimatedItemView) {
        guard let player = item.animationPlayer else { return }
        player.stop()
        if let seekable = player as? NSObject & CYLTabBarItemAnimationPlayer, seekable.supportsProgress == true {
            seekable.setValue(progress, forKey: "progress")
        }
    }

    /// [EN] With `drivesAnimationPlayback = false` the view keeps no loop: a player that loops itself (`supportsLoops`) needs
    ///      nothing, any other is played again by the host when a pass ends and the loop switch is on.
    /// [CN] `drivesAnimationPlayback = false` 时视图不负责循环：自己会循环的播放器（`supportsLoops`）无需处理，其他播放器在一遍播放结束且
    ///      循环开关打开时由宿主再次播放。
    private func keepLooping(_ item: CYLAnimatedItemView) {
        guard loopSwitch.isOn, let player = item.animationPlayer else { return }
        if (player as? NSObject & CYLTabBarItemAnimationPlayer)?.supportsLoops != true {
            player.play()
        }
    }

    @objc private func playItem(_ sender: CYLAnimatedItemView) {
        applyPolicy(to: sender)
        sender.animationPlayer?.play()
    }

    @objc private func playAll() {
        for engineItem in engineItems {
            applyPolicy(to: engineItem.item)
            engineItem.item.restartAnimation()
        }
        updateLabels()
    }

    @objc private func stopAtHalf() {
        for engineItem in engineItems {
            stopAtProgress(0.5, item: engineItem.item)
        }
    }

    @objc private func speedChanged() {
        speedSlider.value = (speedSlider.value / 0.05).rounded() * 0.05
        updateSpeedValue()
        for engineItem in engineItems {
            applyPolicy(to: engineItem.item)
        }
    }

    @objc private func loopChanged() {
        for engineItem in engineItems {
            applyPolicy(to: engineItem.item)
        }
    }

    // MARK: - Labels

    private func updateLabels() {
        let token = engineItems.first?.item.animationRestartToken ?? 0
        tokenLabel.text = String(format: cylDemoLocalizedString("Restart token: %@"), String(token))
        let ended = endCounts.keys.sorted().map { "\($0) ×\(endCounts[$0] ?? 0)" }.joined(separator: ", ")
        endLabel.text = String(format: cylDemoLocalizedString("End callback: %@"), ended.isEmpty ? cylDemoLocalizedString("none yet") : ended)
    }

    private func updateSpeedValue() {
        let speed = NumberFormatter.localizedString(from: NSNumber(value: Double(speedSlider.value)), number: .decimal)
        speedValueLabel.text = "\(speed)×"
        speedSlider.accessibilityValue = String(format: cylDemoLocalizedString("%@ times"), speed)
    }

    // MARK: - Views

    private func setUpViews() {
        let intro = UILabel()
        intro.text = cylDemoLocalizedString("Host-driven playback (drivesAnimationPlayback = false)")
        intro.font = .preferredFont(forTextStyle: .footnote)
        intro.textColor = .secondaryLabel
        intro.numberOfLines = 0
        intro.accessibilityIdentifier = "AnimatedItemEngineAPIIntro"

        let icons = UIStackView(arrangedSubviews: engineItems.map(\.item))
        icons.distribution = .fillEqually
        icons.spacing = 8
        icons.heightAnchor.constraint(equalToConstant: 112).isActive = true

        let playAllButton = UIButton(type: .system)
        playAllButton.setTitle(cylDemoLocalizedString("Play all"), for: .normal)
        playAllButton.contentHorizontalAlignment = .leading
        playAllButton.accessibilityLabel = cylDemoLocalizedString("Play all")
        playAllButton.accessibilityIdentifier = "AnimatedItemEngineAPIPlayAll"
        playAllButton.addTarget(self, action: #selector(playAll), for: .touchUpInside)

        let stopButton = UIButton(type: .system)
        stopButton.setTitle(cylDemoLocalizedString("Stop at 50%"), for: .normal)
        stopButton.contentHorizontalAlignment = .leading
        stopButton.accessibilityLabel = cylDemoLocalizedString("Stop at 50%")
        stopButton.accessibilityIdentifier = "AnimatedItemEngineAPIStopAtHalf"
        stopButton.addTarget(self, action: #selector(stopAtHalf), for: .touchUpInside)

        let speedLabel = UILabel()
        speedLabel.text = cylDemoLocalizedString("Speed")
        speedLabel.isAccessibilityElement = false
        speedLabel.setContentHuggingPriority(.required, for: .horizontal)
        speedSlider.minimumValue = Self.minimumSpeed
        speedSlider.maximumValue = Self.maximumSpeed
        speedSlider.value = 1
        speedSlider.accessibilityLabel = cylDemoLocalizedString("Speed")
        speedSlider.accessibilityIdentifier = "AnimatedItemEngineAPISpeed"
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.font = .monospacedDigitSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        speedValueLabel.textAlignment = .right
        speedValueLabel.isAccessibilityElement = false
        speedValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        speedValueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        let speedRow = UIStackView(arrangedSubviews: [speedLabel, speedSlider, speedValueLabel])
        speedRow.spacing = 12
        speedRow.alignment = .center
        updateSpeedValue()

        let loopLabel = UILabel()
        loopLabel.text = cylDemoLocalizedString("Loop")
        loopLabel.isAccessibilityElement = false
        loopSwitch.accessibilityLabel = cylDemoLocalizedString("Loop")
        loopSwitch.accessibilityIdentifier = "AnimatedItemEngineAPILoop"
        loopSwitch.addTarget(self, action: #selector(loopChanged), for: .valueChanged)
        let loopRow = UIStackView(arrangedSubviews: [loopLabel, loopSwitch])
        loopRow.alignment = .center

        for label in [tokenLabel, endLabel] {
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
        }
        tokenLabel.accessibilityIdentifier = "AnimatedItemEngineAPIRestartToken"
        endLabel.accessibilityIdentifier = "AnimatedItemEngineAPIEndCallback"

        let card = UIStackView(arrangedSubviews: [playAllButton, stopButton, speedRow, loopRow, tokenLabel, endLabel])
        card.axis = .vertical
        card.spacing = 12
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.layer.cornerCurve = .continuous

        let stack = UIStackView(arrangedSubviews: [intro, icons, card])
        stack.axis = .vertical
        stack.spacing = 16
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
}
