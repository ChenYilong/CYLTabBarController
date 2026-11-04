//
//  GalleryIrregularPlusButton.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] The large round center button of the irregular scenes: a teal circle with a light border, raised above the tab
//      bar, that only responds inside its circle. A tap plays a ripple and shows an action sheet instead of a page.
// [CN] 不规则场景中的大号圆形中间按钮：带浅色描边的青色圆形，凸出于 TabBar 之上，只在圆形内响应点击。点击时播放波纹并弹出操作表，
//      而不是展示某个页面。
final class GalleryIrregularPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    private static let diameter: CGFloat = 70

    private let circleView = UIView()
    private let iconView = UIImageView()

    static func plusButton() -> Any {
        let button = GalleryIrregularPlusButton(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        button.setUpCircle()
        button.accessibilityLabel = "Camera"
        button.addTarget(button, action: #selector(galleryDidTap), for: .touchUpInside)
        return button
    }

    static func tabBarContext() -> String {
        return Gallery.irregularContext
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        return 2
    }

    static func multiplier(ofTabBarHeight _: CGFloat) -> CGFloat {
        return 0.25
    }

    static func tabBarItemIdentifier() -> String {
        return "camera"
    }

    private func setUpCircle() {
        circleView.frame = bounds
        circleView.isUserInteractionEnabled = false
        circleView.backgroundColor = Gallery.teal
        circleView.layer.cornerRadius = Self.diameter / 2
        circleView.layer.borderWidth = 3
        circleView.layer.borderColor = Gallery.gray(235).cgColor
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        iconView.image = UIImage(systemName: "camera.fill", withConfiguration: configuration)
        iconView.tintColor = .white
        iconView.sizeToFit()
        iconView.center = CGPoint(x: Self.diameter / 2, y: Self.diameter / 2)
        circleView.addSubview(iconView)
        addSubview(circleView)
    }

    /// [EN] Only the circle responds. [CN] 只有圆形区域响应。
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let radius = bounds.width / 2
        let dx = point.x - bounds.midX
        let dy = point.y - bounds.midY
        return (dx * dx + dy * dy).squareRoot() <= radius
    }

    override var isHighlighted: Bool {
        didSet {
            let highlighted = isHighlighted
            UIView.animate(withDuration: 0.2) {
                self.circleView.transform = highlighted ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
            }
        }
    }

    @objc private func galleryDidTap() {
        playRipple()
        let presenter = cyl_owningTabBarController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(UIAlertAction(title: "Take a photo", style: .default))
            sheet.addAction(UIAlertAction(title: "Select from album", style: .default))
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            sheet.popoverPresentationController?.sourceView = self
            sheet.popoverPresentationController?.sourceRect = self?.bounds ?? .zero
            presenter?.present(sheet, animated: true)
        }
    }

    /// [EN] A dot that grows over the circle and fades out. [CN] 一个小圆点放大覆盖圆形后淡出。
    private func playRipple() {
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
        dot.layer.cornerRadius = 1
        dot.backgroundColor = Gallery.darkTeal
        dot.alpha = 0.5
        dot.center = CGPoint(x: circleView.bounds.midX, y: circleView.bounds.midY)
        circleView.insertSubview(dot, belowSubview: iconView)
        let scale = circleView.bounds.width / 2
        UIView.animate(withDuration: 0.4, animations: {
            dot.transform = CGAffineTransform(scaleX: scale, y: scale)
            dot.alpha = 0
        }, completion: { _ in
            dot.removeFromSuperview()
        })
    }
}
