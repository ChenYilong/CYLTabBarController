//
//  MessageViewController.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLAnimatedItem

/// [EN] The animated item component on its own (docs/Animated-Item.md, TODO 6): four `CYLAnimatedItemView`s, one per
///      display state: a GIF that plays, a static image (no animation file), the placeholder (a broken file, no image),
///      and a remote GIF whose static image shows while it downloads.
/// [CN] 单独使用的动效组件（docs/Animated-Item.md，TODO 6）：四个 `CYLAnimatedItemView`，每个对应一种显示状态：播放中的 GIF、
///      静态图片（没有动效文件）、占位图（文件损坏且没有图片）、远程 GIF（下载期间显示静态图片）。
class MessageViewController: UIViewController {

    private let stackView = UIStackView()

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
        addItem(title: "静态图片", image: UIImage(systemName: "photo"), animationURL: nil,
                identifier: "CYLAnimatedItemDemoImage")
        addItem(title: "占位图（文件损坏）", image: nil, animationURL: Self.brokenFileURL(),
                identifier: "CYLAnimatedItemDemoPlaceholder")
        addItem(title: "远程 GIF（下载中显示图片）", image: UIImage(systemName: "icloud.and.arrow.down"),
                animationURL: URL(string: "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/Example-GIF/GIFApp/Resources/tab_rocket.gif"),
                identifier: "CYLAnimatedItemDemoRemote")
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
