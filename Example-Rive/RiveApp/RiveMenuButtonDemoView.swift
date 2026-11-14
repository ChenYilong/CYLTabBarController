//
//  RiveMenuButtonDemoView.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] A Rive animation in plain UIKit, outside the tab bar: `CYLTabBarItemAnimationFactory` makes the view from a
 *      `CYLTabBarAnimationURLWithOptions()` URL, and its player plays and stops it. The course's menu_button.riv has no view
 *      model, so the state machine input "isOpen" is used, held until it is stopped ("duration" 0). The Bell tab shows it
 *      above the demo's test list (`CYLSettingsDemoTableViewController.headerView`).
 * [CN] 在 TabBar 之外、纯 UIKit 中使用 Rive 动画：`CYLTabBarItemAnimationFactory` 根据 `CYLTabBarAnimationURLWithOptions()` 生成的 URL 创建视图，
 *      再通过其播放器播放与停止。课程的 menu_button.riv 没有 view model，因此使用状态机输入 "isOpen"，保持到停止（"duration" 为 0）。
 *      Bell Tab 把它显示在 Demo 测试列表上方（`CYLSettingsDemoTableViewController.headerView`）。
 */
final class RiveMenuButtonDemoView: UIView {

    private static let animationSize = CGSize(width: 88, height: 88)
    private var animationView: UIView?
    private var isOn = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        // [EN] Starts at its final size: the animation view resizes with it (autoresizing), so a zero-sized container
        //      would make it grow by the container's size when laid out.
        // [CN] 初始即为最终大小：动画视图随其缩放（autoresizing），容器若从零尺寸开始，布局后动画视图会额外增大容器的尺寸。
        let container = UIView(frame: CGRect(origin: .zero, size: Self.animationSize))
        container.translatesAutoresizingMaskIntoConstraints = false
        let fileURL = Bundle.main.url(forResource: "menu_button", withExtension: "riv")
        if let url = CYLTabBarAnimationURLWithOptions(fileURL, [
            .riveStateMachine: "State Machine",
            .riveInput: "isOpen",
            .riveActiveDuration: "0",
        ]), let animationView = CYLTabBarItemAnimationFactory.animationView(url: url, size: Self.animationSize, contentMode: .scaleAspectFit) {
            animationView.frame = container.bounds
            animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(animationView)
            self.animationView = animationView
        }

        let button = UIButton(type: .system)
        button.setTitle(cylDemoLocalizedString("播放 / 停止"), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [container, button])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Self.animationSize.width),
            container.heightAnchor.constraint(equalToConstant: Self.animationSize.height),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func toggle() {
        isOn.toggle()
        let player = CYLTabBarItemAnimationFactory.player(for: animationView)
        if isOn {
            player?.play()
        } else {
            player?.stop()
        }
    }
}
