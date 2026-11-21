//
//  MessageViewController.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLAnimatedItem

/// [EN] The animated item component on its own (docs/Animated-Item.md, item 6): four `CYLAnimatedItemView`s, one per
///      display state: a GIF that plays, a static image (no animation file), the placeholder (a broken file, no image),
///      a remote GIF whose static image shows while it downloads, and a vertical item with an accessory icon that can be
///      dragged (it springs back), whose last event shows under it, as the Android demo's last item.
/// [CN] 单独使用的动效组件（docs/Animated-Item.md，item 6）：四个 `CYLAnimatedItemView`，每个对应一种显示状态：播放中的 GIF、
///      静态图片（没有动效文件）、占位图（文件损坏且没有图片）、远程 GIF（下载期间显示静态图片）；以及一个带附加图标、可拖拽（松手弹回）的
///      竖排组件，其最近的事件显示在下方，与 Android Demo 的最后一项相同。
class MessageViewController: UIViewController, CYLAnimatedItemViewDelegate {

    private let stackView = UIStackView()
    private let eventLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = cylDemoLocalizedString("动效 icon 组件")

        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        let gif = Bundle.main.url(forResource: "tab_star", withExtension: "gif")
        addItem(title: "播放中的 GIF", image: nil, animationURL: gif, identifier: "CYLAnimatedItemDemoPlaying")
        // [EN] Not "photo": the placeholder below is a picture icon too, and the two looked alike (docs/Animated-Item.md B18).
        // [CN] 不用 "photo"：下面的占位图也是图片图标，两者看起来一样（docs/Animated-Item.md B18）。
        addItem(title: "静态图片", image: UIImage(systemName: "house.fill"), animationURL: nil,
                identifier: "CYLAnimatedItemDemoImage")
        addItem(title: "占位图（文件损坏）", image: nil, animationURL: Self.brokenFileURL(),
                identifier: "CYLAnimatedItemDemoPlaceholder")
        addItem(title: "远程 GIF（下载中显示图片）", image: UIImage(systemName: "icloud.and.arrow.down"),
                animationURL: URL(string: "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/Example-GIF/GIFApp/Resources/tab_rocket.gif"),
                identifier: "CYLAnimatedItemDemoRemote")
        addInteractiveItem()
        addCountdownItem()
    }

    private func addInteractiveItem() {
        let item = CYLAnimatedItemView()
        item.title = cylDemoLocalizedString("竖排：附加图标，可拖拽")
        item.image = UIImage(systemName: "star.fill")
        item.axis = .vertical
        item.iconSize = CGSize(width: 48, height: 48)
        let accessory = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        accessory.tintColor = .systemRed
        accessory.accessibilityLabel = cylDemoLocalizedString("删除")
        item.accessoryView = accessory
        item.isDragEnabled = true
        item.dragMovesView = true
        item.delegate = self
        item.accessibilityIdentifier = "CYLAnimatedItemDemoInteractive"
        stackView.addArrangedSubview(item)
        item.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32).isActive = true

        eventLabel.font = .preferredFont(forTextStyle: .footnote)
        eventLabel.adjustsFontForContentSizeCategory = true
        eventLabel.textColor = .secondaryLabel
        eventLabel.numberOfLines = 0
        eventLabel.textAlignment = .center
        eventLabel.accessibilityIdentifier = "CYLAnimatedItemDemoEvent"
        eventLabel.text = cylDemoLocalizedString("点击、点击附加图标或拖拽")
        stackView.addArrangedSubview(eventLabel)
    }

    /// [EN] The countdown style (docs/Animated-Item.md, "Countdown style"): a tap starts a 10-second countdown; the titles
    ///      are the component's defaults ("Get code", "%ld s left", "Resend"), which an app replaces with its own texts.
    /// [CN] 倒计时样式（docs/Animated-Item.md「倒计时样式」）：点击开始 10 秒倒计时；标题使用组件默认值（"Get code"、
    ///      "%ld s left"、"Resend"），App 可以换成自己的文字。
    private func addCountdownItem() {
        let item = CYLAnimatedItemView()
        item.itemStyle = .countdown
        item.image = UIImage(systemName: "message")
        item.countdownDuration = 10
        item.startsCountdownOnTap = true
        item.accessibilityIdentifier = "CYLAnimatedItemDemoCountdown"
        stackView.addArrangedSubview(item)
    }

    private func show(event key: String) {
        eventLabel.text = cylDemoLocalizedString(key)
        UIAccessibility.post(notification: .announcement, argument: eventLabel.text)
    }

    // MARK: - CYLAnimatedItemViewDelegate

    func animatedItemViewDidTap(_: CYLAnimatedItemView) {
        show(event: "点击了组件")
    }

    func animatedItemViewDidTapAccessory(_: CYLAnimatedItemView) {
        show(event: "点击了附加图标")
    }

    func animatedItemViewDidBeginDrag(_: CYLAnimatedItemView) {
        show(event: "拖拽中")
    }

    func animatedItemView(_: CYLAnimatedItemView, didEndDragWithTranslation _: CGPoint, cancelled _: Bool) {
        show(event: "拖拽结束，已弹回")
    }

    private func addItem(title key: String, image: UIImage?, animationURL: URL?, identifier: String) {
        let item = CYLAnimatedItemView()
        item.title = cylDemoLocalizedString(key)
        item.image = image
        item.iconSize = CGSize(width: 48, height: 48)
        item.animationLoops = true
        item.animationURL = animationURL
        item.accessibilityIdentifier = identifier
        item.translatesAutoresizingMaskIntoConstraints = false
        item.heightAnchor.constraint(equalToConstant: 88).isActive = true
        stackView.addArrangedSubview(item)
        // [EN] After it is in the view hierarchy: a constraint to `view` needs a common ancestor. [CN] 加入视图层级之后：与 `view` 的约束需要共同祖先。
        item.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32).isActive = true
        item.playAnimation()
    }

    /// [EN] A file named .gif that is not a GIF: the component shows its placeholder. [CN] 名为 .gif 但并非 GIF 的文件：组件显示占位图。
    private static func brokenFileURL() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cyl_broken.gif")
        try? Data("not a gif".utf8).write(to: url)
        return url
    }
}
