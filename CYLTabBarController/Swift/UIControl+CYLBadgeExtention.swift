//
//  UIControl+CYLBadgeExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * FIX: issue #535
 * [EN] `UIControl (CYLBadgeExtention)`: a tab button's badge goes on its icon (image or Lottie view) and is mirrored to the
 *      Liquid Glass platter; any other control's badge goes on a transparent anchor above its content. This needs Core, so
 *      the file is part of Core (`CYLTabBarController/Swift/`), not of the `CYLBadgeView` subspec: without Core every
 *      `UIControl` uses the `UIView (CYLBadgeExtention)` implementation, as before. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 22); every selector is kept, and the members stay `dynamic`, because `CYLPlusButton`
 *      (Objective-C) overrides some of them and calls `super`.
 * [CN] `UIControl (CYLBadgeExtention)`：Tab 按钮的角标放在图标（图片或 Lottie 视图）上，并同步到液态玻璃 platter；其他控件的角标放在其
 *      内容之上的透明锚点视图上。这依赖 Core，因此本文件属于 Core（`CYLTabBarController/Swift/`），而不是 `CYLBadgeView` 子库：没有 Core
 *      时所有 `UIControl` 使用 `UIView (CYLBadgeExtention)` 的实现，与以前相同。已从 Objective-C 翻译（docs/Swift-Migration.md，
 *      第 22 步）；保留所有 selector，成员保持 `dynamic`，因为 `CYLPlusButton`（Objective-C）会重写其中一些并调用 `super`。
 */
enum CYLControlBadgeKeys {
    /**
     * [EN] The selector name is the key: `CYLPlusButton` reads it with `NSSelectorFromString`.
     * [CN] 以 selector 名称为 key：`CYLPlusButton` 通过 `NSSelectorFromString` 读取。
     */
    static let anchorView = CYLUtilsKeys.key("cyl_badgeAnchorViewAlignedToView:")
    static let delayIfNeededForSeconds = CYLUtilsKeys.key("cyl_delayIfNeededForSeconds")
    static let opaqueUnitRect = CYLUtilsKeys.key("cyl_badgeOpaqueUnitRect")
    /**
     * [EN] Above 0 while `-cyl_performOnBadgeLayers:` runs (UIKit, so the main thread only).
     * [CN] `-cyl_performOnBadgeLayers:` 执行期间大于 0（UIKit，只在主线程）。
     */
    static var layerPerformDepth = 0
}

/**
 * [EN] The transparent view that holds a control's badge (`-cyl_badgeAnchorViewAlignedToView:`). It places its badge again on
 *      every layout pass, from its final bounds: placed once, the badge kept the fraction of a point it got from the bounds at
 *      that moment.
 * [CN] 承载控件角标的透明视图（`-cyl_badgeAnchorViewAlignedToView:`）。每次布局都按最终的 bounds 重新放置角标：只放置一次时，角标会保留
 *      当时 bounds 带来的不到一个点的偏差。
 */
@objc(CYLBadgeAnchorView)
final class CYLBadgeAnchorView: UIView {
    weak var cyl_target: UIView?
    var cyl_unitRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    weak var cyl_leadingConstraint: NSLayoutConstraint?
    weak var cyl_topConstraint: NSLayoutConstraint?

    override func layoutSubviews() {
        super.layoutSubviews()
        // [EN] The padding before the visible part follows the target's current size.
        // [CN] 可见部分之前的边距随目标当前尺寸变化。
        let targetSize = cyl_target?.bounds.size ?? .zero
        let leading = cyl_unitRect.minX * targetSize.width
        let top = cyl_unitRect.minY * targetSize.height
        if let constraint = cyl_leadingConstraint, abs(constraint.constant - leading) > 0.01 {
            constraint.constant = leading
        }
        if let constraint = cyl_topConstraint, abs(constraint.constant - top) > 0.01 {
            constraint.constant = top
        }
        cyl_layoutBadgeAtTopRightCorner()
    }
}

/**
 * [EN] The part of `image` that is not transparent, as fractions of its size (the whole image without alpha, or when it
 *      cannot be read). Measured once per image, on a copy of at most 64×64 pixels.
 * [CN] `image` 中不透明的部分，以占其尺寸的比例表示（没有 alpha 或无法读取时为整张图片）。每张图片只测量一次，使用最大 64×64 像素的副本。
 */
private func cylBadgeOpaqueUnitRect(of image: UIImage?) -> CGRect {
    var unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    guard let image, let cgImage = image.cgImage else {
        return unitRect
    }
    if let cached = objc_getAssociatedObject(image, CYLControlBadgeKeys.opaqueUnitRect) as? NSValue {
        return cached.cgRectValue
    }
    let alphaInfo = cgImage.alphaInfo
    let hasAlpha = alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
    let width = min(cgImage.width, 64)
    let height = min(cgImage.height, 64)
    if hasAlpha && width > 0 && height > 0 {
        var alpha = [UInt8](repeating: 0, count: width * height)
        let drawn: Bool = alpha.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else {
                return false
            }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        if drawn {
            // [EN] Row 0 of the buffer is the top of the image. [CN] 缓冲区第 0 行是图片顶部。
            var minX = width, minY = height, maxX = 0, maxY = 0
            for y in 0..<height {
                for x in 0..<width where alpha[y * width + x] > 25 {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
            if minX <= maxX && minY <= maxY {
                unitRect = CGRect(x: CGFloat(minX) / CGFloat(width), y: CGFloat(minY) / CGFloat(height),
                                  width: CGFloat(maxX - minX + 1) / CGFloat(width),
                                  height: CGFloat(maxY - minY + 1) / CGFloat(height))
            }
        }
    }
    objc_setAssociatedObject(image, CYLControlBadgeKeys.opaqueUnitRect, NSValue(cgRect: unitRect), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return unitRect
}

/**
 * [EN] The picture that fills `view`: an image view's image, or the background image of a button without an image.
 * [CN] 填满 `view` 的图片：图片视图的图片，或没有图片的按钮的背景图片。
 */
private func cylBadgeImageFilling(_ view: UIView) -> UIImage? {
    if let imageView = view as? UIImageView {
        return imageView.image
    }
    if let button = view as? UIButton, button.currentImage == nil {
        return button.currentBackgroundImage
    }
    return nil
}

extension UIControl {

    /**
     * [EN] The view that holds this control's badge (`CYL_ACTUAL_BARBUTTON` in Objective-C).
     * [CN] 承载本控件角标的视图（Objective-C 中的 `CYL_ACTUAL_BARBUTTON`）。
     */
    /**
     * [EN] This control typed as `UIView`: a call on a `UIControl` is ambiguous between these overrides and the
     *      `CYLBadgeProtocol` requirement `UIControl` inherits; through `UIView` it resolves, and the call still reaches the
     *      override (dynamic dispatch).
     * [CN] 以 `UIView` 类型引用本控件：在 `UIControl` 上调用时，这些重写与 `UIControl` 继承的 `CYLBadgeProtocol` 要求之间存在歧义；通过
     *      `UIView` 调用可消除歧义，且仍会执行重写的实现（动态派发）。
     */
    private var cyl_asView: UIView {
        self
    }

    private var cyl_actualBadgeView: UIView? {
        cyl_asView.cyl_getActualBadgeSuperView() as? UIView
    }

    @objc(cyl_setBadgeValue:)
    dynamic func cyl_setBadgeValue(_ badgeValue: String) {
        // [EN] No longer required (the deprecated system badge point), kept for apps that still add one.
        // [CN] 已不再必需（废弃的系统角标点），为仍在添加它的 App 保留。
        let removeSelector = NSSelectorFromString("cyl_removeTabBadgePoint")
        if responds(to: removeSelector) {
            _ = perform(removeSelector)
        }
        cyl_asView.cyl_clearBadge()
        // [EN] FIX: this used to call itself and never return. [CN] 之前这里调用自身，导致无限递归。
        cyl_asView.cyl_showBadgeValue(badgeValue, animationType: .none)
    }

    override var cyl_badgeAnimationTypeValue: NSNumber {
        get { NSNumber(value: cyl_asView.cyl_badgeAnimationType.rawValue) }
        set { cyl_asView.cyl_badgeAnimationType = CYLBadgeAnimationType(rawValue: newValue.uintValue) ?? .none }
    }

    override var cyl_badgeCenterOffsetValue: NSValue {
        get { NSValue(cgPoint: cyl_asView.cyl_badgeCenterOffset) }
        set { cyl_asView.cyl_badgeCenterOffset = newValue.cgPointValue }
    }

    override var cyl_badgeCornerRadiusValue: NSNumber {
        get { NSNumber(value: Double(cyl_asView.cyl_badgeCornerRadius)) }
        set { cyl_asView.cyl_badgeCornerRadius = CGFloat(newValue.doubleValue) }
    }

    override var cyl_badgeFrameValue: NSValue {
        get { NSValue(cgRect: cyl_asView.cyl_badgeFrame) }
        set { cyl_asView.cyl_badgeFrame = newValue.cgRectValue }
    }

    override var cyl_badgeMarginValue: NSNumber {
        get { NSNumber(value: Double(cyl_asView.cyl_badgeMargin)) }
        set { cyl_asView.cyl_badgeMargin = CGFloat(newValue.doubleValue) }
    }

    override var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        get { NSNumber(value: cyl_asView.cyl_badgeMaximumBadgeNumber) }
        set { cyl_asView.cyl_badgeMaximumBadgeNumber = newValue.intValue }
    }

    override var cyl_badgeRadiusValue: NSNumber {
        get { NSNumber(value: Double(cyl_asView.cyl_badgeRadius)) }
        set { cyl_asView.cyl_badgeRadius = CGFloat(newValue.doubleValue) }
    }

    /**
     * [EN] 0 by default for a control (a view: 0.5 s). [CN] 控件默认为 0（视图为 0.5 秒）。
     */
    override var cyl_delayIfNeededForSeconds: CGFloat {
        get {
            (objc_getAssociatedObject(self, CYLControlBadgeKeys.delayIfNeededForSeconds) as? NSNumber).map { CGFloat($0.doubleValue) } ?? 0
        }
        set {
            objc_setAssociatedObject(self, CYLControlBadgeKeys.delayIfNeededForSeconds, NSNumber(value: Double(newValue)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    override var cyl_delayIfNeededForSecondsValue: NSNumber {
        get { NSNumber(value: Double(cyl_asView.cyl_delayIfNeededForSeconds)) }
        set { cyl_asView.cyl_delayIfNeededForSeconds = CGFloat(newValue.doubleValue) }
    }

    // MARK: Public methods

    override func cyl_showBadge() {
        cyl_showBadgeValue("", animationTypeValue: NSNumber(value: CYLBadgeAnimationType.none.rawValue))
    }

    override func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType) {
        cyl_showBadgeValue(value, animationTypeValue: NSNumber(value: animationType.rawValue))
    }

    public override func cyl_showBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        if CYLControlBadgeKeys.layerPerformDepth == 0 {
            cyl_asView.cyl_perform(#selector(UIView.cyl_showBadgeValue(_:animationTypeValue:)), with: value, with: animationTypeValue)
            return
        }
        cyl_showBadgeValueInThisLayer(value, animationTypeValue: animationTypeValue)
    }

    /**
     * [EN] Shows the badge on this control only (one Liquid Glass layer). Called by `CYLPlusButton`.
     * [CN] 只在本控件（液态玻璃的一个图层）上显示角标。由 `CYLPlusButton` 调用。
     */
    @objc(cyl_showBadgeValueInThisLayer:animationTypeValue:)
    dynamic func cyl_showBadgeValueInThisLayer(_ value: String, animationTypeValue: NSNumber) {
        cyl_actualBadgeView?.cyl_showBadgeValue(value, animationType: CYLBadgeAnimationType(rawValue: animationTypeValue.uintValue) ?? .none)
    }

    override func cyl_isShowBadge() -> Bool {
        cyl_actualBadgeView?.cyl_isShowBadge() ?? false
    }

    override func cyl_isPauseBadge() -> Bool {
        cyl_actualBadgeView?.cyl_isPauseBadge() ?? false
    }

    override func cyl_clearBadge() {
        if CYLControlBadgeKeys.layerPerformDepth == 0 {
            cyl_asView.cyl_perform(#selector(UIView.cyl_clearBadge))
            return
        }
        cyl_actualBadgeView?.cyl_clearBadge()
    }

    override func cyl_resumeBadge() {
        if CYLControlBadgeKeys.layerPerformDepth == 0 {
            cyl_asView.cyl_perform(#selector(UIView.cyl_resumeBadge))
            return
        }
        cyl_actualBadgeView?.cyl_resumeBadge()
    }

    public override func cyl_refreshBadge() {
        if CYLControlBadgeKeys.layerPerformDepth == 0 {
            cyl_asView.cyl_perform(#selector(UIView.cyl_refreshBadge))
            return
        }
        cyl_actualBadgeView?.cyl_refreshBadge()
    }

    // MARK: Private methods

    @objc(cyl_getActualBadgeSuperViewFromControl:)
    dynamic func cyl_getActualBadgeSuperView(fromControl tabButton: UIControl) -> UIView? {
        (tabButton as UIView).cyl_getActualBadgeSuperView() as? UIView
    }

    /**
     * [EN] The view the badge goes on: for a tab button, its Lottie view or image view (an icon hidden for the view shown in
     *      its place, #601, still takes it); for any other control (a plus button, a UIButton), a transparent anchor above its
     *      content, aligned to its icon (`-cyl_badgeAnchorViewAlignedToView:`), so the control's own content never covers or
     *      clips the badge.
     * [CN] 角标所在的视图：Tab 按钮为其 Lottie 视图或图片视图（被替换显示而隐藏的图标仍承载角标，#601）；其他控件（PlusButton、UIButton）
     *      为其内容之上、与图标对齐的透明锚点视图（`-cyl_badgeAnchorViewAlignedToView:`），控件自身的内容不会遮挡或裁剪角标。
     */
    override func cyl_getActualBadgeSuperView() -> Any? {
        let tabImageView = cyl_tabImageView()
        let animationView = cyl_tabBarItemAnimationView()
        var actualBadgeSuperView: UIView?
        if let animationView, !animationView.cyl_isInvisiable() || animationView.cyl_badgeHostReplacedByIconView {
            actualBadgeSuperView = animationView
        } else if let tabImageView, !tabImageView.cyl_isInvisiable() || tabImageView.cyl_badgeHostReplacedByIconView {
            actualBadgeSuperView = tabImageView
        }
        // [EN] By class name: `-cyl_isTabButton` is YES for every UIControl before iOS 26.
        // [CN] 按类名判断：iOS 26 以前 `-cyl_isTabButton` 对所有 UIControl 都返回 YES。
        let className = NSStringFromClass(type(of: self))
        let isTabBarButton = className.contains("TabButton") || className.contains("TabBarButton")
        if !isTabBarButton {
            return cyl_badgeAnchorViewAligned(to: actualBadgeSuperView)
        }
        if let actualBadgeSuperView {
            actualBadgeSuperView.clipsToBounds = false
            // [EN] Auto Layout cells need `-layoutIfNeeded` for the frame to have a value. [CN] 自动布局需要先 `-layoutIfNeeded`。
            actualBadgeSuperView.layoutIfNeeded()
        }
        return actualBadgeSuperView
    }

    /**
     * [EN] The transparent view that holds the badge of a control that is not a tab button, aligned to `referenceView` (the
     *      icon) or to the whole control, and within it to the visible part of its picture. When the control clips, the
     *      anchor goes right above the control in its superview.
     * [CN] 承载非 Tab 按钮控件角标的透明视图，与 `referenceView`（图标）或整个控件对齐，并进一步对齐到其图片的可见部分。控件会裁剪时，锚点
     *      放在父视图中、紧贴控件之上。
     */
    @objc(cyl_badgeAnchorViewAlignedToView:)
    dynamic func cyl_badgeAnchorViewAligned(to referenceView: UIView?) -> UIView {
        let anchorView: UIView
        if let existing = objc_getAssociatedObject(self, CYLControlBadgeKeys.anchorView) as? UIView {
            anchorView = existing
        } else {
            anchorView = CYLBadgeAnchorView(frame: bounds)
            anchorView.backgroundColor = .clear
            anchorView.isUserInteractionEnabled = false
            anchorView.clipsToBounds = false
            anchorView.isAccessibilityElement = false
            anchorView.translatesAutoresizingMaskIntoConstraints = false
            objc_setAssociatedObject(self, CYLControlBadgeKeys.anchorView, anchorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        let controlClips = clipsToBounds || layer.masksToBounds || layer.mask != nil
        let container: UIView = controlClips ? (superview ?? self) : self
        if container === self {
            if anchorView.superview !== self {
                anchorView.removeFromSuperview()
                addSubview(anchorView)
            }
            bringSubviewToFront(anchorView)
            anchorView.layer.zPosition = .cyl_topZPosition
        } else {
            if anchorView.superview !== container {
                anchorView.removeFromSuperview()
            }
            container.insertSubview(anchorView, aboveSubview: self)
            anchorView.layer.zPosition = layer.zPosition
            anchorView.isHidden = isHidden
            anchorView.alpha = alpha
        }
        var target: UIView = referenceView.flatMap { $0 !== anchorView ? $0 : nil } ?? self
        // [EN] An image view without an image shows nothing: the badge goes on the whole control.
        // [CN] 没有图片的图片视图不显示任何内容：角标对齐整个控件。
        if let imageView = target as? UIImageView {
            let imageSize = imageView.image?.size ?? .zero
            if imageSize.width <= 0 || imageSize.height <= 0 {
                target = self
            }
        }
        let unitRect = cylBadgeOpaqueUnitRect(of: cylBadgeImageFilling(target))
        let targetSize = target.bounds.size
        var constraints = objc_getAssociatedObject(anchorView, CYLControlBadgeKeys.anchorView) as? [NSLayoutConstraint] ?? []
        var isPinnedToTarget = constraints.count == 4 && constraints[0].isActive && constraints[0].secondItem === target
            && constraints[2].multiplier == unitRect.width && constraints[3].multiplier == unitRect.height
        if !isPinnedToTarget {
            NSLayoutConstraint.deactivate(constraints)
            // [EN] Constraints keep the anchor on the icon as the control lays out again. [CN] 约束让锚点在重新布局后仍与图标对齐。
            constraints = [
                anchorView.leadingAnchor.constraint(equalTo: target.leadingAnchor),
                anchorView.topAnchor.constraint(equalTo: target.topAnchor),
                anchorView.widthAnchor.constraint(equalTo: target.widthAnchor, multiplier: unitRect.width),
                anchorView.heightAnchor.constraint(equalTo: target.heightAnchor, multiplier: unitRect.height),
            ]
            NSLayoutConstraint.activate(constraints)
            objc_setAssociatedObject(anchorView, CYLControlBadgeKeys.anchorView, constraints, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            isPinnedToTarget = false
        }
        // [EN] Only real changes: this runs during the plus button's layout, and any change lays it out again.
        // [CN] 只在确有变化时修改：本方法在 PlusButton 布局期间执行，任何修改都会让它再次布局。
        let leading = unitRect.minX * targetSize.width
        let top = unitRect.minY * targetSize.height
        if let badgeAnchorView = anchorView as? CYLBadgeAnchorView {
            badgeAnchorView.cyl_target = target
            badgeAnchorView.cyl_unitRect = unitRect
            badgeAnchorView.cyl_leadingConstraint = constraints[0]
            badgeAnchorView.cyl_topConstraint = constraints[1]
        }
        if abs(constraints[0].constant - leading) >= 0.5 {
            constraints[0].constant = leading
        }
        if abs(constraints[1].constant - top) >= 0.5 {
            constraints[1].constant = top
        }
        if !isPinnedToTarget {
            // [EN] Once, right after pinning; setting it on every call fought Auto Layout's pixel rounding and laid the plus
            //      button out forever.
            // [CN] 只在刚建立约束时设置一次；每次调用都设置会与 Auto Layout 的像素取整冲突，导致 PlusButton 无限布局。
            let visibleRect = CGRect(x: leading, y: top, width: unitRect.width * targetSize.width,
                                     height: unitRect.height * targetSize.height)
            anchorView.frame = target.convert(visibleRect, to: container)
        }
        return anchorView
    }

    override func cyl_perform(_ aSelector: Selector) {
        cyl_asView.cyl_perform(aSelector, with: nil, with: nil)
    }

    override func cyl_perform(_ aSelector: Selector, with object: Any?) {
        cyl_asView.cyl_perform(aSelector, with: object, with: nil)
    }

    override func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?) {
        cyl_performOnBadgeLayers { control in
            _ = control.perform(aSelector, with: object1, with: object2)
        }
    }

    /**
     * FIX: issue #779
     * [EN] The controls that draw this tab, one per layer: on Liquid Glass, the control in the normal layer and the one in
     *      the selected layer, which is seen through the glass. `CYLPlusButton` overrides it.
     * [CN] 绘制该 Tab 的控件，每个图层一个：液态玻璃下是普通图层与选中图层（透过玻璃看到）中的控件。`CYLPlusButton` 会重写它。
     */
    @objc(cyl_badgeLayerControls)
    dynamic func cyl_badgeLayerControls() -> [UIControl] {
        if !CYLUtils.isLiquidGlassActive() {
            return [self]
        }
        let counterpart = cyl_isPlatterSelectedControl() ? cyl_platterNormal() : cyl_platterSelected()
        if let counterpart, counterpart !== self {
            return [self, counterpart]
        }
        return [self]
    }

    /**
     * FIX: issue #779
     * [EN] Runs `block` once per layer. Inside it, a badge method called on a control acts on that control only, so a call
     *      through a view controller, a tab bar item, a tab button or a plus button reaches both layers exactly once.
     * [CN] 每个图层执行一次 `block`。在其中对控件调用角标方法时只作用于该控件，因此通过视图控制器、TabBarItem、Tab 按钮或 PlusButton
     *      调用，都恰好作用于两个图层各一次。
     */
    @objc(cyl_performOnBadgeLayers:)
    dynamic func cyl_performOnBadgeLayers(_ block: (UIControl) -> Void) {
        if CYLControlBadgeKeys.layerPerformDepth > 0 {
            block(self)
            return
        }
        CYLControlBadgeKeys.layerPerformDepth += 1
        defer { CYLControlBadgeKeys.layerPerformDepth -= 1 }
        cyl_badgeLayerControls().forEach(block)
    }

    /**
     * [EN] On Liquid Glass, the selected layer renders after the normal one: the badge waits until the tab image view (or
     *      label) and, with animated icons, the animation are laid out. Elsewhere, always ready.
     * [CN] 液态玻璃下选中图层比普通图层渲染得晚：角标要等到 Tab 图片视图（或标题）以及动画图标布局完成。其他情况总是就绪。
     */
    override func cyl_isReady() -> Bool {
        if !CYLUtils.isLiquidGlassActive() {
            return true
        }
        if cyl_platterSelected()?.cyl_tabImageView() == nil {
            return false
        }
        let isTabImageViewReady = (cyl_tabImageView()?.frame.size.width ?? 0) > 10 || (cyl_tabLabel()?.frame.size.width ?? 0) > 10
        var isAnimationReady = true
        if let tabBarController = cyl_tabBarController, tabBarController.tabBarItemAnimationURLs.count > 0 {
            isAnimationReady = cyl_isTabBarItemAnimationReady()
        }
        return isTabImageViewReady && isAnimationReady
    }

    // MARK: Setters and getters: read from the badge view, written to every layer

    public override var cyl_badge: (UIView & CYLBadgeTextDisplaying)? {
        get { cyl_actualBadgeView?.cyl_badge }
        // [EN] One view cannot be in two layers. [CN] 一个视图不能同时位于两个图层。
        set { cyl_actualBadgeView?.cyl_badge = newValue }
    }

    override var cyl_badgeFont: UIFont! {
        get { cyl_actualBadgeView?.cyl_badgeFont ?? CYLBadgeAppearance.global.font }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeFont = newValue } }
    }

    override var cyl_badgeBackgroundColor: UIColor! {
        get { cyl_actualBadgeView?.cyl_badgeBackgroundColor ?? CYLBadgeAppearance.global.backgroundColor }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeBackgroundColor = newValue } }
    }

    override var cyl_badgeTextColor: UIColor! {
        get { cyl_actualBadgeView?.cyl_badgeTextColor ?? CYLBadgeAppearance.global.textColor }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeTextColor = newValue } }
    }

    override var cyl_badgeAnimationType: CYLBadgeAnimationType {
        get { cyl_actualBadgeView?.cyl_badgeAnimationType ?? .none }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeAnimationType = newValue } }
    }

    public override var cyl_badgeBorderColor: UIColor? {
        get { cyl_actualBadgeView?.cyl_badgeBorderColor }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeBorderColor = newValue } }
    }

    public override var cyl_badgeBorderWidth: CGFloat {
        get { cyl_actualBadgeView?.cyl_badgeBorderWidth ?? 0 }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeBorderWidth = newValue } }
    }

    public override var cyl_badgeRespectsReduceMotion: Bool {
        get { cyl_actualBadgeView?.cyl_badgeRespectsReduceMotion ?? false }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeRespectsReduceMotion = newValue } }
    }

    override var cyl_badgeFrame: CGRect {
        get { cyl_actualBadgeView?.cyl_badgeFrame ?? .zero }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeFrame = newValue } }
    }

    override var cyl_badgeCenterOffset: CGPoint {
        get { cyl_actualBadgeView?.cyl_badgeCenterOffset ?? .zero }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeCenterOffset = newValue } }
    }

    override var cyl_badgeMaximumBadgeNumber: Int {
        get { cyl_actualBadgeView?.cyl_badgeMaximumBadgeNumber ?? 0 }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeMaximumBadgeNumber = newValue } }
    }

    override var cyl_badgeMargin: CGFloat {
        get { cyl_actualBadgeView?.cyl_badgeMargin ?? 0 }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeMargin = newValue } }
    }

    override var cyl_badgeRadius: CGFloat {
        get { cyl_actualBadgeView?.cyl_badgeRadius ?? 0 }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeRadius = newValue } }
    }

    override var cyl_badgeCornerRadius: CGFloat {
        get { cyl_actualBadgeView?.cyl_badgeCornerRadius ?? 0 }
        set { cyl_performOnBadgeLayers { (($0 as UIView).cyl_getActualBadgeSuperView() as? UIView)?.cyl_badgeCornerRadius = newValue } }
    }
}
