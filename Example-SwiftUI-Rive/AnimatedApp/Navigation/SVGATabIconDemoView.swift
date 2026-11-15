//
//  SVGATabIconDemoView.swift
//  AnimatedApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 * FIX: issue #415
 * [EN] SVGA animations in plain UIKit, on the Bell page of Example-SwiftUI-Rive and, after the Rive demo
 *      (`RiveMenuButtonDemoView`), of Example-Rive: the SVGA subspec
 *      (`pod 'CYLTabBarController/SVGA'`) registers a view provider for ".svga" files, so `CYLTabBarItemAnimationFactory`
 *      makes their views exactly as it does for Rive, and the player plays (once, keeping the last frame) and stops them. The
 *      same files work as tab icons with `CYLTabBarSVGAURL` (docs/SVGA-Animation.md). Samples: SVGAAssets/NOTICE.md (Apache 2.0).
 * [CN] 纯 UIKit 中的 SVGA 动画，显示在 Example-SwiftUI-Rive 的 Bell 页面，以及 Example-Rive 的 Bell 页面 Rive 演示（`RiveMenuButtonDemoView`）之后：SVGA 子库（`pod 'CYLTabBarController/SVGA'`）为 ".svga" 文件
 *      注册了视图 provider，因此 `CYLTabBarItemAnimationFactory` 创建其视图的方式与 Rive 完全相同，播放器负责播放（一次，停在最后一帧）与停止。
 *      同样的文件通过 `CYLTabBarSVGAURL` 即可作为 Tab 图标（docs/SVGA-Animation.md）。示例文件见 SVGAAssets/NOTICE.md（Apache 2.0）。
 */
final class SVGATabIconDemoView: UIView {

    private static let animationSize = CGSize(width: 64, height: 64)
    private var animationViews: [UIView] = []
    private var isOn = false
    /// [EN] The Bell tab's Rive URL while its icon is the SVGA file, put back on the next tap. [CN] Bell Tab 图标为 SVGA 文件时保存的 Rive URL，再次点击时恢复。
    private var savedRiveURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // [EN] HamburgerArrow is the SVGA twin of the Rive menu button above. [CN] HamburgerArrow 是上方 Rive 菜单按钮的 SVGA 对应版本。
        let containers = ["HamburgerArrow", "heartbeat", "Rocket"].map { name -> UIView in
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
        icons.spacing = 24

        let button = UIButton(type: .system)
        button.setTitle(cylDemoLocalizedString("播放 / 停止"), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityHint = "SVGA"
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        // [EN] The same SVGA file as the real icon of this tab (Bell), in place, in every style (issue #415).
        // [CN] 同一个 SVGA 文件作为本 Tab（Bell）真正的图标，原地替换，适用于所有样式（issue #415）。
        let tabIconButton = UIButton(type: .system)
        tabIconButton.setTitle(cylDemoLocalizedString("Tab 图标：SVGA / Rive"), for: .normal)
        tabIconButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        tabIconButton.titleLabel?.adjustsFontForContentSizeCategory = true
        tabIconButton.accessibilityIdentifier = "SVGATabIconSwitch"
        tabIconButton.addTarget(self, action: #selector(toggleTabIcon), for: .touchUpInside)

        // [EN] Issue #415: every tab icon from Rive, from the SVGA initialization keys or from an SVGA configuration file
        //      (SVGATabIcons.swift); rebuilds the tab bar.
        // [CN] Issue #415：所有 Tab 图标来自 Rive、SVGA 初始化 key 或 SVGA 配置文件（SVGATabIcons.swift）；切换时重建 TabBar。
        let sourceButton = UIButton(type: .system)
        sourceButton.setTitle(CYLDemoTabIconSource.switchTitle, for: .normal)
        sourceButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        sourceButton.titleLabel?.adjustsFontForContentSizeCategory = true
        sourceButton.titleLabel?.numberOfLines = 0
        sourceButton.titleLabel?.textAlignment = .center
        sourceButton.accessibilityIdentifier = "SVGATabIconSourceSwitch"
        sourceButton.addTarget(self, action: #selector(switchTabIconSource), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icons, button, tabIconButton, sourceButton])
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

    @objc private func switchTabIconSource() {
        CYLDemoTabIconSource.current = CYLDemoTabIconSource.current.next
        CYLDemoTabIconSource.rebuildTabBar?()
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

    /**
     * [EN] Swaps the Bell tab's icon between heartbeat.svga and its Rive artboard with `-updateTabBarItemForViewController:attributes:`.
     *      The generic `CYLTabBarAnimationURL` wins over the library keys (`CYLTabBarRiveURL`) already in the tab's
     *      attributes, and the file extension picks the SVGA animator; a new app would simply give `CYLTabBarSVGAURL`.
     * [CN] 通过 `-updateTabBarItemForViewController:attributes:` 在 heartbeat.svga 与 Rive 画板之间切换 Bell Tab 的图标。通用的
     *      `CYLTabBarAnimationURL` 优先于 Tab 属性中已有的动画库 key（`CYLTabBarRiveURL`），文件扩展名选择 SVGA animator；新 App 直接使用
     *      `CYLTabBarSVGAURL` 即可。
     */
    @objc private func toggleTabIcon() {
        var responder: UIResponder? = self
        while let next = responder?.next, !(next is UIViewController) {
            responder = next
        }
        guard let viewController = responder?.next as? UIViewController,
              // [EN] UIKit's own property: `cyl_tabBarController` finds only system styles, not FlatDesign.
              // [CN] 使用 UIKit 自带的属性：`cyl_tabBarController` 只查找系统样式，不包括扁平样式。
              let tabBarController = viewController.tabBarController as? CYLTabBarController,
              let index = tabBarController.viewControllers?.firstIndex(where: { $0 === viewController || $0.children.first === viewController }) else {
            return
        }
        let url: URL?
        if let savedRiveURL {
            url = savedRiveURL
            self.savedRiveURL = nil
        } else {
            let attributes = tabBarController.tabBarItemAttributes(at: UInt(index))
            savedRiveURL = (attributes?[CYLTabBarAnimationURL] ?? attributes?[CYLTabBarRiveURL]) as? URL
            url = Bundle.main.url(forResource: "heartbeat", withExtension: "svga")
        }
        guard let url else { return }
        tabBarController.updateTabBarItem(for: viewController, attributes: [
            CYLTabBarAnimationURL: url,
            CYLTabBarAnimationSize: NSValue(cgSize: CGSize(width: 32, height: 32)),
        ])
    }
}
