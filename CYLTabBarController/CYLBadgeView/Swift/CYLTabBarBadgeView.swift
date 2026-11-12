//
//  CYLTabBarBadgeView.swift
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] What a badge's text view offers (a `UILabel` or a `CYLTabBarBadgeView`). Translated from Objective-C
 *      (docs/Swift-Migration.md).
 * [CN] 角标文字视图提供的属性（`UILabel` 或 `CYLTabBarBadgeView`）。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
@objc(CYLBadgeTextDisplaying)
public protocol CYLBadgeTextDisplaying: NSObjectProtocol {
    /**
     * [EN] The badge text.
     * [CN] 角标文字。
     */
    var text: String? { get set }
    /**
     * [EN] The text font (nil resets it).
     * [CN] 文字字体（设为 nil 即重置）。
     */
    var font: UIFont! { get set }
    /**
     * [EN] The text color (nil resets it).
     * [CN] 文字颜色（设为 nil 即重置）。
     */
    var textColor: UIColor! { get set }
    /**
     * [EN] The text alignment.
     * [CN] 文字对齐方式。
     */
    var textAlignment: NSTextAlignment { get set }
}

extension UILabel: CYLBadgeTextDisplaying {}

/**
 * [EN] The badge view: a label filling the view, sized to its text with `badgeContentInset` (at least 18 pt high and as
 *      wide as high). Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers get this class from
 *      `CYLSwiftInterface.h`.
 * [CN] 角标视图：一个填满视图的标签，按文字与 `badgeContentInset` 计算尺寸（高度至少 18pt，宽度不小于高度）。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md）；Objective-C 调用方通过 `CYLSwiftInterface.h` 使用本类。
 */
@objc(CYLTabBarBadgeView)
open class CYLTabBarBadgeView: UIView, CYLBadgeTextDisplaying {

    /**
     * [EN] The label that draws the text.
     * [CN] 绘制文字的标签。
     */
    @objc public let badgeLabel: UILabel

    /**
     * [EN] The padding around the text, used by `sizeThatFits(_:)`.
     * [CN] 文字周围的内边距，供 `sizeThatFits(_:)` 使用。
     */
    @objc public var badgeContentInset: UIEdgeInsets = .zero

    override public init(frame: CGRect) {
        badgeLabel = UILabel(frame: frame)
        super.init(frame: frame)
        layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = .clear
        badgeLabel.translatesAutoresizingMaskIntoConstraints = true
        badgeLabel.textColor = .white
        addSubview(badgeLabel)
        bringSubviewToFront(badgeLabel)
        badgeLabel.layer.zPosition = .greatestFiniteMagnitude
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("CYLTabBarBadgeView is not loaded from a storyboard")
    }

    // MARK: - CYLBadgeTextDisplaying

    /**
     * [EN] The text alignment of the label (`.left`, zero, leaves the label unchanged, as before).
     * [CN] 标签的文字对齐方式（`.left` 即 0 时不修改标签，与原来相同）。
     */
    @objc public var textAlignment: NSTextAlignment = .left {
        didSet {
            if textAlignment != .left {
                badgeLabel.textAlignment = textAlignment
            }
        }
    }

    /**
     * [EN] The text color of the label.
     * [CN] 标签的文字颜色。
     */
    @objc public var textColor: UIColor! {
        didSet {
            if let textColor {
                badgeLabel.textColor = textColor
            }
        }
    }

    /**
     * [EN] The font of the label.
     * [CN] 标签的字体。
     */
    @objc public var font: UIFont! {
        didSet {
            if let font {
                badgeLabel.font = font
            }
        }
    }

    /**
     * [EN] The badge text.
     * [CN] 角标文字。
     */
    @objc public var text: String? {
        didSet {
            if oldValue != text {
                badgeLabel.text = text
            }
        }
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        if bounds != .zero, badgeLabel.frame != bounds {
            badgeLabel.frame = bounds
        }
    }

    override open var frame: CGRect {
        didSet { syncBadgeLabelWithBounds() }
    }

    override open var bounds: CGRect {
        didSet { syncBadgeLabelWithBounds() }
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text, !text.isEmpty else {
            return .zero
        }
        let textSize = (text as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                   height: CGFloat.greatestFiniteMagnitude),
                                                       options: [], attributes: [.font: badgeLabel.font as Any],
                                                       context: nil).size
        let height = max(textSize.height + badgeContentInset.top + badgeContentInset.bottom, 18)
        let width = max(textSize.width + badgeContentInset.left + badgeContentInset.right, height)
        return CGSize(width: width, height: height)
    }

    // MARK: - Environment

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        notifyBadgeHostOfEnvironmentChange()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        notifyBadgeHostOfEnvironmentChange()
    }

    private func syncBadgeLabelWithBounds() {
        if !bounds.isEmpty {
            badgeLabel.frame = bounds
        }
    }

    /**
     * [EN] Tells the badge host (`UIView (CYLBadgeExtention)`, still Objective-C) that the window or traits changed;
     *      called by selector until that category is Swift too.
     * [CN] 通知角标宿主（`UIView (CYLBadgeExtention)`，仍为 Objective-C）窗口或特征已变化；在该类别翻译为 Swift 之前通过 selector 调用。
     */
    private func notifyBadgeHostOfEnvironmentChange() {
        let selector = NSSelectorFromString("cyl_notifyBadgeHostOfEnvironmentChange")
        if responds(to: selector) {
            perform(selector)
        }
    }
}
