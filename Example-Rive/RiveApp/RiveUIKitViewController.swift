//
//  RiveUIKitViewController.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] A Rive animation in plain UIKit, outside the tab bar: `CYLTabBarItemAnimationFactory` makes the view from a
 *      `CYLTabBarAnimationURLWithOptions()` URL, and its player plays and stops it. The course's menu_button.riv has no view
 *      model, so the state machine input "isOpen" is used, held until it is stopped ("duration" 0).
 * [CN] 在 TabBar 之外、纯 UIKit 中使用 Rive 动画：`CYLTabBarItemAnimationFactory` 根据 `CYLTabBarAnimationURLWithOptions()` 生成的 URL 创建视图，
 *      再通过其播放器播放与停止。课程的 menu_button.riv 没有 view model，因此使用状态机输入 "isOpen"，保持到停止（"duration" 为 0）。
 */
final class RiveUIKitViewController: UIViewController {

    private var animationView: UIView?
    private var isOn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Background")

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let fileURL = Bundle.main.url(forResource: "menu_button", withExtension: "riv")
        if let url = CYLTabBarAnimationURLWithOptions(fileURL, [
            .riveStateMachine: "State Machine",
            .riveInput: "isOpen",
            .riveActiveDuration: "0",
        ]), let animationView = CYLTabBarItemAnimationFactory.animationView(url: url, size: CGSize(width: 88, height: 88), contentMode: .scaleAspectFit) {
            animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(animationView)
            self.animationView = animationView
        }

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Play / Stop", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [container, button])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 88),
            container.heightAnchor.constraint(equalToConstant: 88),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
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
