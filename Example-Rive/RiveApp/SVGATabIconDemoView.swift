//
//  SVGATabIconDemoView.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 * FIX: issue #415
 * [EN] SVGA animations in plain UIKit, shown after the Rive demo (`RiveMenuButtonDemoView`): the SVGA subspec
 *      (`pod 'CYLTabBarController/SVGA'`) registers a view provider for ".svga" files, so `CYLTabBarItemAnimationFactory`
 *      makes their views exactly as it does for Rive, and the player plays (once, keeping the last frame) and stops them. The
 *      same files work as tab icons with `CYLTabBarSVGAURL` (docs/SVGA-Animation.md). Samples: SVGAPlayer-iOS (Apache 2.0).
 * [CN] 纯 UIKit 中的 SVGA 动画，显示在 Rive 演示（`RiveMenuButtonDemoView`）之后：SVGA 子库（`pod 'CYLTabBarController/SVGA'`）为 ".svga" 文件
 *      注册了视图 provider，因此 `CYLTabBarItemAnimationFactory` 创建其视图的方式与 Rive 完全相同，播放器负责播放（一次，停在最后一帧）与停止。
 *      同样的文件通过 `CYLTabBarSVGAURL` 即可作为 Tab 图标（docs/SVGA-Animation.md）。示例文件来自 SVGAPlayer-iOS（Apache 2.0）。
 */
final class SVGATabIconDemoView: UIView {

    private static let animationSize = CGSize(width: 72, height: 72)
    private var animationViews: [UIView] = []
    private var isOn = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        let containers = ["heartbeat", "Rocket"].map { name -> UIView in
            // [EN] Starts at its final size, as in the Rive demo (the animation view follows it through autoresizing).
            // [CN] 与 Rive 演示相同，初始即为最终大小（动画视图通过 autoresizing 跟随它）。
            let container = UIView(frame: CGRect(origin: .zero, size: Self.animationSize))
            container.translatesAutoresizingMaskIntoConstraints = false
            container.isAccessibilityElement = true
            container.accessibilityLabel = "SVGA \(name)"
            container.accessibilityTraits = .image
            if let url = Bundle.main.url(forResource: name, withExtension: "svga"),
               let animationView = CYLTabBarItemAnimationFactory.animationView(url: url, size: Self.animationSize, contentMode: .scaleAspectFit) {
                animationView.frame = container.bounds
                animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.addSubview(animationView)
                animationViews.append(animationView)
            }
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: Self.animationSize.width),
                container.heightAnchor.constraint(equalToConstant: Self.animationSize.height),
            ])
            return container
        }
        let icons = UIStackView(arrangedSubviews: containers)
        icons.axis = .horizontal
        icons.spacing = 32

        let button = UIButton(type: .system)
        button.setTitle(cylDemoLocalizedString("播放 / 停止"), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityHint = "SVGA"
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icons, button])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func toggle() {
        isOn.toggle()
        for animationView in animationViews {
            let player = CYLTabBarItemAnimationFactory.player(for: animationView)
            if isOn {
                player?.play()
            } else {
                player?.stop()
            }
        }
    }
}
