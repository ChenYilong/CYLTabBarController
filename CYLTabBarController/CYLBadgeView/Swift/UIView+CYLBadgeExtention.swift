//
//  UIView+CYLBadgeExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
// [EN] The lifecycle library is linked by CYLUtils only (D8): events are posted through `CYLUtils.postLifecycleEvent`.
// [CN] 生命周期库只由 CYLUtils 链接（D8）：事件通过 `CYLUtils.postLifecycleEvent` 发出。

/**
 * [EN] Badges on any view (`UIView (CYLBadgeExtention)`, `CYLBadgeProtocol`), the default badge view, the overlay used when
 *      a host clips, and the badge animation factory. Translated from Objective-C (docs/Swift-Migration.md, step 21); every
 *      selector is kept. Members are `dynamic`: Objective-C categories of subclasses (`UIControl`, `UIBarButtonItem`'s
 *      views, `CYLPlusButton`) override some of them and call `super`.
 * [CN] 任意视图上的角标（`UIView (CYLBadgeExtention)`、`CYLBadgeProtocol`）、默认角标视图、宿主会裁剪时使用的浮层，以及角标动画工厂。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 21 步），保留所有 selector。成员为 `dynamic`：子类的 Objective-C 分类
 *      （`UIControl`、`CYLPlusButton` 等）会重写其中一些并调用 `super`。
 */
enum CYLBadgeViewKeys {
    static let badge = CYLUtilsKeys.key("cyl_badge")
    static let font = CYLUtilsKeys.key("cyl_badgeFont")
    static let backgroundColor = CYLUtilsKeys.key("cyl_badgeBackgroundColor")
    static let textColor = CYLUtilsKeys.key("cyl_badgeTextColor")
    static let animationType = CYLUtilsKeys.key("cyl_badgeAnimationType")
    static let frame = CYLUtilsKeys.key("cyl_badgeFrame")
    static let cornerRadius = CYLUtilsKeys.key("cyl_badgeCornerRadius")
    static let centerOffset = CYLUtilsKeys.key("cyl_badgeCenterOffset")
    static let radius = CYLUtilsKeys.key("cyl_badgeRadius")
    static let margin = CYLUtilsKeys.key("cyl_badgeMargin")
    static let maximumBadgeNumber = CYLUtilsKeys.key("cyl_badgeMaximumBadgeNumber")
    static let borderColor = CYLUtilsKeys.key("cyl_badgeBorderColor")
    static let borderWidth = CYLUtilsKeys.key("cyl_badgeBorderWidth")
    static let respectsReduceMotion = CYLUtilsKeys.key("cyl_badgeRespectsReduceMotion")
    static let delayIfNeededForSeconds = CYLUtilsKeys.key("cyl_delayIfNeededForSeconds")
    static let keepShowingPlusButtonLabel = CYLUtilsKeys.key("cyl_keepShowingPlusButtonLabel")
    static let hostReplacedByIconView = CYLUtilsKeys.key("cyl_isBadgeHostReplacedByIconView")
    static let pendingGeneration = CYLUtilsKeys.key("cyl_pendingBadgeGeneration")
    static let originalAccessibilityValue = CYLUtilsKeys.key("cyl_badgeOriginalAccessibilityValue")
    static let overlayToken = CYLUtilsKeys.key("cyl_badgeHostOverlayToken")

    static let defaultRedDotRadius: CGFloat = 4
    static let defaultDelayIfNeededForSeconds: CGFloat = 0.5
    static let maximumLayoutRetryCount = 3
}

/**
 * [EN] The default badge view. A `UILabel` in every way; it only tells its host when it enters a window or its traits change
 *      (e.g. Dark Mode), so the host can re-resolve the border color and restore a repeating animation that UIKit stripped.
 *      `CYLTabBarBadgeView` (the Liquid Glass badge on iOS 27) does the same.
 * [CN] 默认的角标视图。完全等同于 `UILabel`，只是在进入 window 或 trait 改变（如深色模式）时通知宿主，以便宿主重新解析边框颜色，并恢复被
 *      UIKit 移除的循环动画。`CYLTabBarBadgeView`（iOS 27 液态玻璃角标）也会这样做。
 */
@objc(CYLBadgeLabel)
final class CYLBadgeLabel: UILabel {

    override func didMoveToWindow() {
        super.didMoveToWindow()
        cylNotifyBadgeHostOfEnvironmentChange()
    }

    @available(iOS, deprecated: 17.0)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cylNotifyBadgeHostOfEnvironmentChange()
    }
}

// MARK: - The badge animation factory and the accessibility description (C functions)

/**
 * [EN] The animation a badge plays for `animationType` (nil for none). The repeating animations keep running after the app
 *      returns from the background. Declared in CYLBadgeViewDefines.h; internal, so the generated header does not need
 *      `CYLBadgeAnimationType` (the Objective-C callers are in this module).
 * [CN] 角标为 `animationType` 播放的动画（无动画时为 nil）。循环动画在 App 从后台返回后继续播放。声明在 CYLBadgeViewDefines.h。
 */
@_cdecl("CYLBadgeAnimationForType")
public func cylBadgeAnimationForTypeEntryPoint(_ animationType: CYLBadgeAnimationType, _ badgeSize: CGSize) -> CAAnimation? {
    let moveDistance = badgeSize.width * 1.5
    switch animationType {
    case .breathe:
        return CAAnimation.cylOpacityForeverAnimation(withDuration: 1.4)
    case .shake:
        // [EN] Relative (`transform.translation.x`), so an anchored badge can still move with its host while shaking.
        // [CN] 相对位移（`transform.translation.x`），因此固定位置的角标抖动时仍可随宿主移动。
        let animation = CAAnimation.cylShakeAnimationRepeatTimes(.infinity, duration: 1, offset: badgeSize.width / 4)
        animation.isRemovedOnCompletion = false
        return animation
    case .scale:
        return CAAnimation.cylScale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatTimes: .greatestFiniteMagnitude)
    case .bounce:
        // [EN] Relative (`transform.translation.y`), see Shake. [CN] 相对位移，见 Shake。
        let animation = CAAnimation.cylBounceRepeatTimes(.infinity, duration: 1, offset: badgeSize.height / 4)
        animation.isRemovedOnCompletion = false
        return animation
    case .leftRightOnce:
        return CAAnimation.cylBadgeOnceLeftRightAnimationMoveDistance(moveDistance, repeatTimes: 1, duration: 0.5)
    case .rightLeftOnce:
        return CAAnimation.cylBadgeOnceRightLeftAnimationMoveDistance(moveDistance, repeatTimes: 1, duration: 0.5)
    case .fadeInOnce:
        return CAAnimation.cylBadgeOnceFade(inAnimationRepeatTimes: 1, duration: 1.5)
    case .rollingOnce:
        return CAAnimation.cylBadgeOnceRollingAnimationRepeatTimes(1, duration: 0.5)
    case .scaleOnce:
        return CAAnimation.cylBadgeOnceScaleAnimationRepeatTimes(1, duration: 0.5)
    default:
        return nil
    }
}

/**
 * [EN] What VoiceOver reads for a badge value: "New content" for a red dot, "3 new messages" for a number, the localized
 *      text otherwise; nil for no badge. Declared in UIView+CYLBadgeExtention.h.
 * [CN] VoiceOver 为角标值朗读的内容：红点为“有新内容”，数字为“3 条新消息”，其他为本地化文本；没有角标时为 nil。声明在
 *      UIView+CYLBadgeExtention.h。
 */
@_cdecl("CYLBadgeAccessibilityDescription")
public func cylBadgeAccessibilityDescriptionEntryPoint(_ value: NSString?) -> NSString? {
    guard let value = value as String? else {
        return nil
    }
    if value.isEmpty {
        return cylLocalizedString("有新内容") as NSString
    }
    if value.range(of: "^[0-9]+\\+?$", options: .regularExpression) != nil {
        let number = (value as NSString).integerValue
        return number > 0 ? String(format: cylLocalizedString("%@ 条新消息"), value) as NSString : nil
    }
    return cylLocalizedString(value) as NSString
}

// MARK: - The overlay above a host that clips

/**
 * FIX: badges cut by a host view that clips
 * [EN] A badge is a subview of its host and sits half outside the host's top-right corner, so a host that clips
 *      (`clipsToBounds`, `layer.masksToBounds` or a `layer.mask`, e.g. a round avatar) cut it. For such a host the badge goes
 *      on this transparent view instead: it is inserted right above the host in the host's superview and pinned to the
 *      host's frame with constraints, so the badge is drawn above the host at the same place and is not clipped, while the
 *      host keeps its own clipping. It follows the host's `hidden` and `alpha` (KVO on the host's layer) and goes away with
 *      the host. A host that does not clip keeps the badge inside it, as before.
 * [CN] 角标是宿主视图的子视图，且有一半位于宿主右上角之外，因此会裁剪的宿主（`clipsToBounds`、`layer.masksToBounds` 或 `layer.mask`，
 *      例如圆形头像）会把角标裁掉。对这类宿主，角标改为放在这个透明视图上：它插入在宿主父视图中、紧贴宿主之上，并用约束与宿主的 frame
 *      对齐，因此角标仍在原位置、绘制在宿主之上且不被裁剪，宿主自身的裁剪不受影响。它跟随宿主的 `hidden`、`alpha`（KVO 宿主的
 *      layer），并随宿主一起销毁。不裁剪的宿主仍把角标放在自身内部，与以前相同。
 */
@objc(CYLBadgeHostOverlayView)
final class CYLBadgeHostOverlayView: UIView {

    private(set) weak var host: UIView?
    /**
     * [EN] Strong, so the observers are always removed from a live layer. [CN] 强引用，保证总是从存活的 layer 上移除观察者。
     */
    private var observedLayer: CALayer?
    private var hostConstraints: [NSLayoutConstraint] = []
    private static var kvoContext = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = false
        isAccessibilityElement = false
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func cylAttach(toHost host: UIView) {
        guard let container = host.superview else {
            return
        }
        if self.host !== host || superview !== container || !(hostConstraints.first?.isActive ?? false) {
            cylDetach()
            self.host = host
            container.insertSubview(self, aboveSubview: host)
            hostConstraints = [
                leadingAnchor.constraint(equalTo: host.leadingAnchor),
                topAnchor.constraint(equalTo: host.topAnchor),
                widthAnchor.constraint(equalTo: host.widthAnchor),
                heightAnchor.constraint(equalTo: host.heightAnchor),
            ]
            NSLayoutConstraint.activate(hostConstraints)
            observedLayer = host.layer
            host.layer.addObserver(self, forKeyPath: "hidden", options: [], context: &CYLBadgeHostOverlayView.kvoContext)
            host.layer.addObserver(self, forKeyPath: "opacity", options: [], context: &CYLBadgeHostOverlayView.kvoContext)
        } else {
            container.insertSubview(self, aboveSubview: host)
        }
        frame = host.frame
        followHostVisibility()
    }

    private func followHostVisibility() {
        let hostLayer = observedLayer
        // [EN] FIX: issue #601 — a host hidden for the view shown in its place keeps its badge visible, above that view too,
        //      which is added to the tab button later.
        // [CN] 被替换显示而隐藏的宿主，角标仍可见，并位于之后添加到 Tab 按钮中的替换视图之上。
        if host?.cyl_badgeHostReplacedByIconView ?? false {
            layer.zPosition = (hostLayer?.zPosition ?? 0) + 1
            isHidden = false
            alpha = 1
            return
        }
        layer.zPosition = hostLayer?.zPosition ?? 0
        isHidden = hostLayer?.isHidden ?? false
        alpha = CGFloat(hostLayer?.opacity ?? 1)
    }

    func cylDetach() {
        if let observedLayer {
            observedLayer.removeObserver(self, forKeyPath: "hidden", context: &CYLBadgeHostOverlayView.kvoContext)
            observedLayer.removeObserver(self, forKeyPath: "opacity", context: &CYLBadgeHostOverlayView.kvoContext)
            self.observedLayer = nil
        }
        NSLayoutConstraint.deactivate(hostConstraints)
        hostConstraints = []
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard context == &CYLBadgeHostOverlayView.kvoContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        followHostVisibility()
    }

    deinit {
        if let observedLayer {
            observedLayer.removeObserver(self, forKeyPath: "hidden", context: &CYLBadgeHostOverlayView.kvoContext)
            observedLayer.removeObserver(self, forKeyPath: "opacity", context: &CYLBadgeHostOverlayView.kvoContext)
        }
    }
}

/**
 * [EN] Removes the overlay when its host is deallocated (an associated object of the host).
 * [CN] 宿主销毁时移除浮层（宿主的关联对象）。
 */
private final class CYLBadgeHostOverlayToken: NSObject {
    weak var overlay: CYLBadgeHostOverlayView?

    deinit {
        overlay?.cylDetach()
        overlay?.removeFromSuperview()
    }
}

/**
 * FIX: issue #481
 * [EN] Whether `host` draws its image as a template: an image view whose image is `AlwaysTemplate`, or `Automatic` in a tab
 *      button, where it is drawn as a template (e.g. an SF Symbol). Liquid Glass draws such an icon, subviews included, as
 *      a mask filled with the tab's tint, so a badge inside it showed as a black shape without its text.
 * [CN] `host` 是否把图片当作模板绘制：图片为 `AlwaysTemplate` 的图片视图，或位于 Tab 按钮中、图片为 `Automatic`（如 SF Symbol，按模板
 *      绘制）的图片视图。液态玻璃把这类图标（包括其子视图）绘制为用 Tab 着色填充的蒙版，所以放在其中的角标显示为没有文字的黑色形状。
 */
private func cylBadgeHostDrawsAsTemplate(_ host: UIView) -> Bool {
    guard let image = (host as? UIImageView)?.image, image.renderingMode != .alwaysOriginal else {
        return false
    }
    if image.renderingMode == .alwaysTemplate {
        return true
    }
    var view = host.superview
    while let current = view, !(current is UIWindow) {
        let className = NSStringFromClass(type(of: current))
        if className.contains("TabButton") || className.contains("TabBarButton") {
            return true
        }
        view = current.superview
    }
    return false
}

/**
 * [EN] The view the badge of `host` is added to: `host` itself, or an overlay above it when `host` clips, draws its image as
 *      a template (#481), or is hidden for the view shown in its place (#601).
 * [CN] 承载 `host` 角标的视图：`host` 本身，或在 `host` 会裁剪、按模板绘制图片（#481）、或被替换显示而隐藏时（#601）位于其上方的浮层。
 */
private func cylBadgeContainer(forHost host: UIView) -> UIView {
    var token = objc_getAssociatedObject(host, CYLBadgeViewKeys.overlayToken) as? CYLBadgeHostOverlayToken
    let hostClips = host.clipsToBounds || host.layer.masksToBounds || host.layer.mask != nil
    let needsOverlay = hostClips || host.cyl_badgeHostReplacedByIconView || cylBadgeHostDrawsAsTemplate(host)
    if !needsOverlay || host.superview == nil {
        if let overlay = token?.overlay {
            overlay.cylDetach()
            overlay.removeFromSuperview()
            token?.overlay = nil
        }
        return host
    }
    if token == nil {
        token = CYLBadgeHostOverlayToken()
        objc_setAssociatedObject(host, CYLBadgeViewKeys.overlayToken, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    let overlay = token?.overlay ?? CYLBadgeHostOverlayView(frame: host.frame)
    token?.overlay = overlay
    overlay.cylAttach(toHost: host)
    return overlay.superview != nil ? overlay : host
}

// MARK: - UIView (CYLBadgeExtention)

/**
 * [EN] The members of `CYLBadgeProtocol` are public and the conformance is declared at the end of this file: since step 115
 *      the protocol and its enums are Swift (CYLBadgeProtocol.swift), so the generated header declares them itself and no
 *      longer imports the umbrella header (the import cycle that kept the members internal while the protocol was Objective-C).
 * [CN] `CYLBadgeProtocol` 的成员为 public，遵循关系在本文件末尾声明：自第 115 步起协议与其枚举为 Swift（CYLBadgeProtocol.swift），
 *      生成的头文件自行声明它们，不再导入伞头文件（协议为 Objective-C 时成员只能为 internal，以避免该循环导入）。
 */
extension UIView {

    // MARK: Public methods

    @objc(cyl_isReady)
    open dynamic func cyl_isReady() -> Bool {
        if cylBadgeClass() == nil {
            return false
        }
        // [EN] No root view controller check: a bar button is not ready then, and its red dot could never be added.
        // [CN] 不检查根控制器：此时导航栏按钮尚未就绪，否则永远无法添加红点。
        guard let view = cyl_getActualBadgeSuperView() as? UIView else {
            return false
        }
        return view.frame.size.width > 10
    }

    /**
     * [EN] Shows a red dot badge, with no animation. [CN] 显示红点角标，无动画。
     */
    @objc(cyl_showBadge)
    open dynamic func cyl_showBadge() {
        cyl_showBadgeValue("", animationType: .none)
    }

    @objc(cyl_showBadgeValue:animationTypeValue:)
    open dynamic func cyl_showBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        if cylForwardBadgeToAnimatedItemIcon(#selector(UIView.cyl_showBadgeValue(_:animationTypeValue:)), value, animationTypeValue) {
            return
        }
        let generation = cylInvalidatePendingBadgeValue()
        if cylShouldWaitForLayoutBeforeShowingBadgeValue(value) {
            cylShowBadgeValue(value, animationTypeValue: animationTypeValue, afterLayoutWithGeneration: generation, attempt: 0)
            return
        }
        cylShowBadgeValueNow(value, animationTypeValue: animationTypeValue)
    }

    /**
     * FIX: badge position with Auto Layout (xib / storyboard / constraints, e.g. a label with a relative width in a cell)
     * [EN] The badge was placed once, from the host view's frame at the moment it was shown. With Auto Layout that frame is
     *      often still zero or changes later. Now: (1) a host that is not laid out yet shows the badge on the next run loop,
     *      then after `cyl_delayIfNeededForSeconds`, at most three times; only the latest value is shown. (2) The badge is
     *      anchored to the host's top-right corner, so it follows later size changes. Scope: every badge, in every tab bar
     *      style, and any other view.
     * [CN] 角标只在显示时按宿主视图当时的 frame 定位一次。使用自动布局时，这个 frame 往往还是 0，或者之后才改变。现在：（1）宿主尚未布局时，
     *      先在下一个 run loop、再按 `cyl_delayIfNeededForSeconds` 延迟重试，最多三次，只显示最新的值；（2）角标固定在宿主右上角，宿主尺寸
     *      之后改变时跟随。范围：所有 TabBar 样式中的角标，以及其他任意视图。
     */
    private func cylShouldWaitForLayoutBeforeShowingBadgeValue(_ value: String?) -> Bool {
        guard let value, cylBadgeClass() != nil else {
            return false
        }
        // [EN] A number <= 0 hides the badge, which needs no layout. [CN] 小于等于 0 的数字隐藏角标，无需布局。
        if !value.isEmpty && value.trimmingCharacters(in: .decimalDigits).isEmpty && (value as NSString).integerValue <= 0 {
            return false
        }
        return !cyl_isReady()
    }

    private func cylShowBadgeValue(_ value: String, animationTypeValue: NSNumber, afterLayoutWithGeneration generation: UInt,
                                    attempt: Int) {
        let delay = attempt == 0 ? 0 : max(Double(cyl_delayIfNeededForSeconds), 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.cylPendingBadgeGeneration() == generation else {
                return
            }
            if attempt + 1 < CYLBadgeViewKeys.maximumLayoutRetryCount && self.cylShouldWaitForLayoutBeforeShowingBadgeValue(value) {
                self.cylShowBadgeValue(value, animationTypeValue: animationTypeValue, afterLayoutWithGeneration: generation,
                                        attempt: attempt + 1)
                return
            }
            // [EN] The host is laid out now: the badge becomes ready (CYLDeallocBlockExecutor event `cyl.badge.didBecomeReady`).
            // [CN] 宿主已布局：角标就绪（CYLDeallocBlockExecutor 事件 `cyl.badge.didBecomeReady`）。
            self.cylPostBadgeEvent("cyl.badge.didBecomeReady")
            self.cylShowBadgeValueNow(value, animationTypeValue: animationTypeValue)
        }
    }

    /**
     * [EN] Posts a badge moment through CYLDeallocBlockExecutor (`cylAddLifecycleCallback(forCustomEvent:)` on this view, on the
     *      tab button's `UITabBarItem` through the forward, or `CYLLifecycleCenter.addCallback(forCustomEvent:)` for every badge):
     *      `cyl.badge.didShow`, `cyl.badge.didClear`, `cyl.badge.didBecomeReady`, `cyl.badge.animationDidStart`,
     *      `cyl.badge.animationDidStop`. `userInfo` holds `value`, `animationType` (raw value) or `finished`.
     * [CN] 通过 CYLDeallocBlockExecutor 发出角标时机事件（可在本视图、经转发在 Tab 按钮对应的 `UITabBarItem` 上监听，或用
     *      `CYLLifecycleCenter.addCallback(forCustomEvent:)` 监听所有角标）。
     */
    func cylPostBadgeEvent(_ name: String, _ userInfo: [String: Any]? = nil) {
        CYLUtils.postLifecycleEvent(name, userInfo: userInfo, on: self)
    }

    private func cylPendingBadgeGeneration() -> UInt {
        (objc_getAssociatedObject(self, CYLBadgeViewKeys.pendingGeneration) as? NSNumber)?.uintValue ?? 0
    }

    /**
     * [EN] Cancels a badge value waiting for layout; returns the new generation. [CN] 取消等待布局的角标值；返回新的代数。
     */
    @discardableResult
    private func cylInvalidatePendingBadgeValue() -> UInt {
        let generation = cylPendingBadgeGeneration() + 1
        objc_setAssociatedObject(self, CYLBadgeViewKeys.pendingGeneration, NSNumber(value: generation),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return generation
    }

    private func cylShowBadgeValueNow(_ value: String, animationTypeValue: NSNumber) {
        cyl_badge?.subviews.forEach { $0.removeFromSuperview() }
        if cylShouldUpdateBadgeSubviews() {
            cyl_badge?.removeFromSuperview()
            cyl_badge = nil
        }
        let animationType = CYLBadgeAnimationType(rawValue: animationTypeValue.uintValue) ?? .none
        cyl_badgeAnimationTypeValue = NSNumber(value: animationType.rawValue)
        cylShowBadge(withValue: value)
        cylPostBadgeEvent("cyl.badge.didShow", ["value": value, "animationType": animationType.rawValue])
        if animationType != .none {
            cylBeginAnimation()
        }
    }

    @objc(cyl_showBadgeValue:animationType:)
    open dynamic func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType) {
        cyl_showBadgeValue(value, animationTypeValue: NSNumber(value: animationType.rawValue))
    }

    @objc(cyl_showBadgeValue:)
    public dynamic func cylShowBadgeValue(_ value: String) {
        cyl_showBadgeValue(value, animationType: .none)
    }

    /**
     * [EN] YES keeps the plus button's title visible while a badge is shown on it. [CN] 为 YES 时，PlusButton 显示角标时仍保留标题。
     */
    @objc(cyl_keepShowingPlusButtonLabel)
    public dynamic var cyl_keepShowingPlusButtonLabel: Bool {
        @objc(cyl_keepShowingPlusButtonLabel) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.keepShowingPlusButtonLabel) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setKeepShowingPlusButtonLabel:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.keepShowingPlusButtonLabel, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: Private methods

    /**
     * [EN] Swizzled with `-willMoveToSuperview:` (UIBarButtonItem+CYLBadgeExtention.m): moves the badge on top of its siblings
     *      every time its superview appears.
     * [CN] 与 `-willMoveToSuperview:` 交换（UIBarButtonItem+CYLBadgeExtention.m）：每次父视图出现时把角标移到兄弟视图之上。
     */
    @objc(cyl_willMoveToSuperview:)
    dynamic func cylWillMove(toSuperview newSuperview: UIView?) {
        cylWillMove(toSuperview: newSuperview)
        if newSuperview != nil, let badge = cyl_badge {
            cylBringBadge(toFront: badge)
        }
    }

    @objc(cyl_showBadgeWithValue:)
    public dynamic func cylShowBadge(withValue value: String?) {
        guard let value else {
            return
        }
        if !value.isEmpty && value.trimmingCharacters(in: .decimalDigits).isEmpty {
            cylShowNumberBadge(withValue: (value as NSString).integerValue)
            return
        }
        if value.isEmpty {
            cylShowRedDotBadge()
            return
        }
        // [EN] Only spaces or line breaks: nothing to read, so hide instead of showing an empty pill.
        // [CN] 只有空格或换行：没有内容可读，因此隐藏，而不是显示空的胶囊。
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            cyl_badge?.cylSetHidden(true)
            return
        }
        if value == "new" || value == "NEW" {
            cylShowNewBadge(value)
            return
        }
        cylShowTextBadge(value)
    }

    /**
     * [EN] Clears the badge. [CN] 清除角标。
     */
    @objc(cyl_clearBadge)
    open dynamic func cyl_clearBadge() {
        if cylForwardBadgeToAnimatedItemIcon(#selector(UIView.cyl_clearBadge)) {
            return
        }
        cylInvalidatePendingBadgeValue()
        cyl_badge?.cylSetHidden(true)
        cylUpdateBadgeAccessibility()
        cylPostBadgeEvent("cyl.badge.didClear")
    }

    @objc(cyl_isShowBadge)
    open dynamic func cyl_isShowBadge() -> Bool {
        // [EN] An animated item's badge is on its icon subview. [CN] 动效 item 的角标在其图标子视图上。
        if let icon = cylAnimatedItemBadgeHost(), icon !== self {
            return icon.cyl_isShowBadge()
        }
        guard let badge = cyl_badge else {
            return false
        }
        return !badge.cylIsHidden()
    }

    /**
     * [EN] Shows the badge again if it exists and is hidden. [CN] 角标存在且被隐藏时重新显示。
     */
    @objc(cyl_resumeBadge)
    open dynamic func cyl_resumeBadge() {
        if cylForwardBadgeToAnimatedItemIcon(#selector(UIView.cyl_resumeBadge)) {
            return
        }
        if cyl_isPauseBadge() {
            cyl_badge?.cylSetHidden(false)
            cylBadgeEnvironmentDidChange()
        }
    }

    @objc(cyl_isPauseBadge)
    open dynamic func cyl_isPauseBadge() -> Bool {
        if let icon = cylAnimatedItemBadgeHost(), icon !== self {
            return icon.cyl_isPauseBadge()
        }
        guard let badge = cyl_badge else {
            return false
        }
        return badge.cylIsHidden()
    }

    @objc(cyl_getActualBadgeSuperView)
    open dynamic func cyl_getActualBadgeSuperView() -> Any? {
        // [EN] Auto Layout cells must call `-layoutIfNeeded` for the frame to have a value, so the badge can find its
        //      position; make sure a view's badge is shown after that.
        // [CN] 自动布局的 cell 需要调用 `-layoutIfNeeded` frame 才有值，角标才能找到对应位置；请确保在此之后显示角标。
        layoutIfNeeded()
        // [EN] Unchanged: a plain view hosts its own badge. An animated item is a UIControl, whose lookup (Core) asks
        //      `-cyl_animatedItemBadgeHost` and then sends the badge messages to that icon through `-cyl_performSelector:…`.
        // [CN] 保持不变：普通视图承载自己的角标。动效 item 是 UIControl，其查找（Core）会调用 `-cyl_animatedItemBadgeHost`，再通过
        //      `-cyl_performSelector:…` 把角标消息发给该图标。
        return self
    }

    /**
     * [EN] The icon of an animated item (`CYLAnimatedItemView`, the component every animation format plays in, a FlatDesign
     *      tab button included): its `animationView` while it shows (any engine: GIF, Lottie, PAG, Rive, SVGA), else its
     *      `imageView` (the static image or the placeholder). Nil for any other view. The component is found by class name,
     *      so the badge subspec does not depend on it.
     * [CN] 动效 item（`CYLAnimatedItemView`，所有动效格式播放所在的组件，包括扁平样式 Tab 按钮）的图标：其 `animationView` 显示时为它（任何引擎：
     *      GIF、Lottie、PAG、Rive、SVGA），否则为其 `imageView`（静态图片或占位图）。其他视图返回 nil。按类名查找组件，因此角标子库不依赖它。
     */
    /**
     * [EN] A badge message sent to an animated item itself (e.g. the badge subspec without Core, where `UIControl` does not
     *      forward): sent on to its icon subview through the usual `-cyl_performSelector:withObject:withObject:`, so the badge
     *      is added there. True when forwarded; false for any other view, and for the icon itself.
     * [CN] 直接发给动效 item 的角标消息（例如没有 Core 的角标子库，此时 `UIControl` 不会转发）：通过常规的 `-cyl_performSelector:withObject:withObject:`
     *      转发给其图标子视图，角标添加在那里。已转发时返回 true；其他视图及图标本身返回 false。
     */
    private func cylForwardBadgeToAnimatedItemIcon(_ selector: Selector, _ object1: Any? = nil, _ object2: Any? = nil) -> Bool {
        guard let icon = cylAnimatedItemBadgeHost(), icon !== self else {
            return false
        }
        icon.clipsToBounds = false
        icon.cyl_perform(selector, with: object1, with: object2)
        return true
    }

    /**
     * [EN] Moves this view's shown badge to `newHost`: its settings (font, colors, border, frame, offset, maximum, radius,
     *      margin, corner radius, Reduce Motion) are copied, the badge is cleared here and shown on `newHost` with the same
     *      value and animation, through `-cyl_performSelector:withObject:withObject:`. Nothing when no badge is shown. Used
     *      when a tab's animation view is replaced by a new one (another file, the dark file, a skin), whose old view held the
     *      badge.
     * [CN] 把本视图显示中的角标移到 `newHost`：复制其设置（字体、颜色、边框、frame、偏移、最大值、半径、边距、圆角、减弱动态效果），在这里清除角标，
     *      并通过 `-cyl_performSelector:withObject:withObject:` 在 `newHost` 上以相同的值与动画显示。没有显示角标时不做任何事。用于 Tab 的动画视图被
     *      新视图替换时（另一个文件、深色文件、皮肤），旧视图承载着角标。
     */
    @objc(cyl_moveBadgeToView:)
    public func cylMoveBadge(to newHost: UIView) {
        guard newHost !== self, let badge = cyl_badge, cyl_isShowBadge() else {
            return
        }
        newHost.cyl_badgeFont = cyl_badgeFont
        newHost.cyl_badgeBackgroundColor = cyl_badgeBackgroundColor
        newHost.cyl_badgeTextColor = cyl_badgeTextColor
        newHost.cyl_badgeBorderColor = cyl_badgeBorderColor
        newHost.cyl_badgeBorderWidth = cyl_badgeBorderWidth
        newHost.cyl_badgeRespectsReduceMotion = cyl_badgeRespectsReduceMotion
        newHost.cyl_badgeFrameValue = cyl_badgeFrameValue
        newHost.cyl_badgeCenterOffsetValue = cyl_badgeCenterOffsetValue
        newHost.cyl_badgeMaximumBadgeNumberValue = cyl_badgeMaximumBadgeNumberValue
        newHost.cyl_badgeRadiusValue = cyl_badgeRadiusValue
        newHost.cyl_badgeMarginValue = cyl_badgeMarginValue
        newHost.cyl_badgeCornerRadiusValue = cyl_badgeCornerRadiusValue
        let value = badge.text ?? ""
        let animationTypeValue = cyl_badgeAnimationTypeValue
        cyl_clearBadge()
        newHost.clipsToBounds = false
        newHost.cyl_perform(#selector(UIView.cyl_showBadgeValue(_:animationTypeValue:)), with: value, with: animationTypeValue)
    }

    @objc(cyl_animatedItemBadgeHost)
    public func cylAnimatedItemBadgeHost() -> UIView? {
        // [EN] A view that adopts `CYLBadgeHosting` names its badge view itself (step 11, docs/Animated-Item-Badge.md); the class-name
        //      lookup below stays for older component versions. [CN] 遵守 `CYLBadgeHosting` 的视图自己给出角标视图（第 11 步）；下面按类名
        //      查找的做法保留给旧版本组件。
        if let host = self as? CYLBadgeHosting { return host.cylBadgeAnchorView }
        guard let componentClass = NSClassFromString("CYLAnimatedItemView"), isKind(of: componentClass) else {
            return nil
        }
        let animationView = responds(to: NSSelectorFromString("animationView")) ? value(forKey: "animationView") as? UIView : nil
        let imageView = responds(to: NSSelectorFromString("imageView")) ? value(forKey: "imageView") as? UIView : nil
        if let animationView, animationView.superview != nil, !animationView.isHidden, animationView.alpha > 0.01 {
            return animationView
        }
        return imageView ?? animationView
    }

    @objc(cyl_performSelector:)
    open dynamic func cyl_perform(_ aSelector: Selector) {
        cyl_perform(aSelector, with: nil, with: nil)
    }

    @objc(cyl_performSelector:withObject:)
    open dynamic func cyl_perform(_ aSelector: Selector, with object: Any?) {
        cyl_perform(aSelector, with: object, with: nil)
    }

    @objc(cyl_performSelector:withObject:withObject:)
    open dynamic func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?) {
        _ = perform(aSelector, with: object1, with: object2)
    }

    private func cylAddMargin() {
        guard let badge = cyl_badge else {
            return
        }
        var frame = badge.frame
        frame.size.width += cyl_badgeMargin
        frame.size.height += cyl_badgeMargin
        if frame.width < frame.height {
            frame.size.width = frame.height
        }
        badge.frame = frame
    }

    private func cylShowRedDotBadge() {
        if !cyl_isReady() {
            return
        }
        cylBadgeInit()
        // [EN] A badge already shown in another style must be updated. [CN] 已经以其他样式显示的角标需要更新。
        if let badge = cyl_badge, badge.tag != Int(CYLBadgeStyle.redDot.rawValue) {
            badge.text = ""
            badge.tag = Int(CYLBadgeStyle.redDot.rawValue)
            cylResetRedDotBadgeFrame()
            badge.layer.cornerRadius = badge.frame.width / 2
        }
        cylApplyBadgeBorder()
        cyl_badge?.cylSetHidden(false)
        cylUpdateBadgeAccessibility()
    }

    private func cylShowNewBadge(_ value: String) {
        if cylBadgeClass() == nil {
            return
        }
        // [EN] "new" / "NEW" are tokens; show them in the app's language. [CN] "new" / "NEW" 是标记，按 App 的语言显示。
        let localized = cylLocalizedString(value)
        let size = (localized as NSString).size(withAttributes: [.font: cyl_badgeFont as UIFont])
        let labelHeight = ceil(size.height) + cyl_badgeMargin
        cyl_badgeCornerRadius = labelHeight / 3
        cylShowTextBadge(localized)
    }

    private func cylShowTextBadge(_ value: String?) {
        if !cyl_isReady() {
            return
        }
        guard let value, !value.isEmpty else {
            cyl_badge?.cylSetHidden(true)
            cylUpdateBadgeAccessibility()
            return
        }
        cylBadgeInit()
        guard let badge = cyl_badge else {
            return
        }
        badge.tag = Int(CYLBadgeStyle.other.rawValue)
        badge.text = value
        badge.font = cyl_badgeFont
        cylAdjustLabelWidth(badge)
        cylAddMargin()
        cylLayoutBadgeAtTopRightCorner()
        badge.layer.cornerRadius = cylTextBadgeCornerRadius()
        cylApplyBadgeBorder()
        badge.cylSetHidden(false)
        cylUpdateBadgeAccessibility()
    }

    /**
     * [EN] VoiceOver. When an ancestor is an accessibility element (a tab button, a cell, a bar button), VoiceOver never reads
     *      its subviews, so the badge was silent. Its meaning ("3 new messages", "New content") becomes the
     *      `accessibilityValue` of the nearest accessible ancestor; that element's own value comes back when the badge is
     *      cleared. With no such ancestor, the badge label itself is the element.
     * [CN] VoiceOver：当祖先视图是无障碍元素（Tab 按钮、cell、导航栏按钮）时，VoiceOver 不读取其子视图，角标无法被读到。现在把角标含义
     *      （“3 条新消息”“有新内容”）设为最近的无障碍祖先的 `accessibilityValue`；清除角标时恢复该元素原有的值。没有这样的祖先时，角标
     *      label 自身作为元素。
     */
    @objc(cyl_updateBadgeAccessibility)
    dynamic func cylUpdateBadgeAccessibility() {
        let badge = cyl_badge
        var description: String?
        if let badge, !badge.cylIsHidden() {
            let text = badge.tag == Int(CYLBadgeStyle.redDot.rawValue) ? "" : (badge.text ?? "")
            description = cylBadgeAccessibilityDescriptionEntryPoint(text as NSString) as String?
        }
        var element: UIView? = isAccessibilityElement ? self : nil
        var view = superview
        while element == nil, let current = view, !(current is UIWindow) {
            if current.isAccessibilityElement {
                element = current
            }
            view = current.superview
        }
        badge?.isAccessibilityElement = element == nil && description != nil
        badge?.accessibilityLabel = description
        guard let element else {
            return
        }
        let saved = objc_getAssociatedObject(element, CYLBadgeViewKeys.originalAccessibilityValue)
        if let description {
            if saved == nil {
                // [EN] NSNull marks "had no value", so the original nil can be restored too.
                // [CN] NSNull 表示“原本没有值”，以便也能恢复原来的 nil。
                objc_setAssociatedObject(element, CYLBadgeViewKeys.originalAccessibilityValue,
                                         element.accessibilityValue ?? NSNull(), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            element.accessibilityValue = description
        } else if saved != nil {
            element.accessibilityValue = saved as? String
            objc_setAssociatedObject(element, CYLBadgeViewKeys.originalAccessibilityValue, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func cylShowNumberBadge(withValue value: Int) {
        if cylBadgeClass() == nil {
            return
        }
        if value <= 0 {
            cyl_badge?.cylSetHidden(true)
            return
        }
        cylBadgeInit()
        cyl_badge?.cylSetHidden(value == 0)
        cyl_badge?.tag = Int(CYLBadgeStyle.number.rawValue)
        // [EN] A maximum below 1 would turn every number into "0+". [CN] 小于 1 的上限会把所有数字变成 "0+"。
        let maximumBadgeNumber = max(1, cyl_badgeMaximumBadgeNumber)
        cylShowTextBadge(value > maximumBadgeNumber ? "\(maximumBadgeNumber)+" : "\(value)")
    }

    /**
     * [EN] Creates the badge view lazily. The colors are not written back: unset, they resolve to `CYLBadgeAppearance` (#425)
     *      every time; an existing badge picks up a global color changed since it was created.
     * [CN] 延迟创建角标视图。颜色不写回对象：未设置时每次都从 `CYLBadgeAppearance` 取值（#425）；已存在的角标同步之后修改过的全局颜色。
     */
    @objc(cyl_badgeInit)
    dynamic func cylBadgeInit() {
        if !cyl_isReady() {
            return
        }
        if let badge = cyl_badge {
            badge.backgroundColor = cyl_badgeBackgroundColor
            badge.textColor = cyl_badgeTextColor
            return
        }
        guard let badgeClass = cylBadgeClass(),
              let badge = badgeClass.init(frame: frame) as? UIView & CYLBadgeTextDisplaying else {
            return
        }
        cyl_badge = badge
        cylResetRedDotBadgeFrame()
        badge.textAlignment = .center
        badge.textColor = cyl_badgeTextColor
        badge.text = ""
        badge.layer.cornerRadius = badge.frame.width / 2
        badge.layer.masksToBounds = true
        badge.cylSetHidden(true)
        badge.isAccessibilityElement = false
        badge.backgroundColor = cyl_badgeBackgroundColor
        cylApplyBadgeBorder()
        cylBringBadge(toFront: badge)
    }

    /**
     * [EN] Above everything in the host, or in an overlay above the host when the host clips (`CYLBadgeHostOverlayView`).
     * [CN] 位于宿主所有内容之上；宿主会裁剪时放在宿主之上的浮层中（`CYLBadgeHostOverlayView`）。
     */
    private func cylBringBadge(toFront view: UIView) {
        if !cyl_isReady() {
            return
        }
        let container = cylBadgeContainer(forHost: self)
        if view.superview !== container {
            container.addSubview(view)
        }
        container.bringSubviewToFront(view)
        view.layer.zPosition = .cylTopZPosition
    }

    private func cylResetRedDotBadgeFrame() {
        var redDotWidth = CYLBadgeViewKeys.defaultRedDotRadius * 2
        let badgeRadius = cyl_badgeRadius
        if badgeRadius > 0 && badgeRadius.isFinite {
            redDotWidth = badgeRadius * 2
        }
        guard let badge = cyl_badge else {
            return
        }
        badge.frame = CGRect(x: bounds.width, y: -redDotWidth, width: redDotWidth, height: redDotWidth)
        badge.layoutIfNeeded()
        cylLayoutBadgeAtTopRightCorner()
        badge.layer.masksToBounds = true
    }

    /**
     * [EN] Centers the badge on the host's top-right corner (plus `cyl_badgeCenterOffset`) and keeps it there: the flexible
     *      left and bottom margins move it with the right edge when the host is resized later. `bounds`, not `frame`: a
     *      transform on the host (e.g. a tab image animation) must not move the badge.
     * [CN] 将角标中心放在宿主右上角（加上 `cyl_badgeCenterOffset`）并保持：左边距和下边距可变，宿主之后尺寸改变时角标随右边缘移动。使用
     *      `bounds` 而不是 `frame`：宿主上的 transform（如 Tab 图片动画）不应移动角标。
     */
    @objc(cyl_layoutBadgeAtTopRightCorner)
    public dynamic func cylLayoutBadgeAtTopRightCorner() {
        guard let badge = cyl_badge else {
            return
        }
        badge.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        let offset = cyl_badgeCenterOffset
        let offsetX = offset.x.isFinite ? offset.x : 0
        let offsetY = offset.y.isFinite ? offset.y : 0
        badge.center = CGPoint(x: bounds.width + 2 + offsetX, y: offsetY)
    }

    /**
     * [EN] A custom `cyl_badgeCornerRadius` is kept within half the badge's shorter side; 0, negative or non-finite means
     *      automatic: half the height.
     * [CN] 自定义的 `cyl_badgeCornerRadius` 不超过角标短边的一半；0、负数或非有限值表示自动：高度的一半。
     */
    private func cylTextBadgeCornerRadius() -> CGFloat {
        let size = cyl_badge?.bounds.size ?? .zero
        let maximumRadius = max(0, min(size.width, size.height) / 2)
        let customRadius = cyl_badgeCornerRadius
        if customRadius > 0 && customRadius.isFinite {
            return min(customRadius, maximumRadius)
        }
        return max(0, size.height / 2)
    }

    // MARK: Border, environment, refresh

    /**
     * [EN] Applies `cyl_badgeBorderWidth` / `cyl_badgeBorderColor`. `CALayer.borderColor` does not follow Dark Mode by itself,
     *      so a dynamic color is resolved against the badge's traits here, and again whenever they change.
     * [CN] 应用 `cyl_badgeBorderWidth` / `cyl_badgeBorderColor`。`CALayer.borderColor` 不会自动跟随深色模式，因此在这里按角标的 trait
     *      解析动态颜色，并在 trait 改变时重新解析。
     */
    private func cylApplyBadgeBorder() {
        guard let badge = cyl_badge else {
            return
        }
        let borderWidth = cyl_badgeBorderWidth
        badge.layer.borderWidth = borderWidth
        guard borderWidth > 0, let borderColor = cyl_badgeBorderColor else {
            return
        }
        badge.layer.borderColor = borderColor.resolvedColor(with: badge.traitCollection).cgColor
    }

    /**
     * [EN] Called by the badge view itself (`CYLBadgeLabel`, `CYLTabBarBadgeView`) when it enters a window or its traits change.
     * [CN] 由角标视图自身（`CYLBadgeLabel`、`CYLTabBarBadgeView`）在进入 window 或 trait 改变时调用。
     */
    @objc(cyl_notifyBadgeHostOfEnvironmentChange)
    dynamic func cylNotifyBadgeHostOfEnvironmentChange() {
        var host = superview
        if let overlay = host as? CYLBadgeHostOverlayView {
            host = overlay.host
        }
        if let host, host.cyl_badge === self {
            host.cylBadgeEnvironmentDidChange()
        }
    }

    /**
     * [EN] Re-resolves the border color, and keeps the repeating animation in step with the environment: restores it if
     *      UIKit stripped it, removes it while Reduce Motion is on. One-shot animations are never replayed here.
     * [CN] 重新解析边框颜色，并使循环动画与环境保持一致：被 UIKit 移除时恢复，开启“减弱动态效果”时移除。一次性动画不会在这里重播。
     */
    @objc(cyl_badgeEnvironmentDidChange)
    dynamic func cylBadgeEnvironmentDidChange() {
        guard let badge = cyl_badge else {
            return
        }
        cylApplyBadgeBorder()
        let animationType = cyl_badgeAnimationType
        guard cylBadgeAnimationTypeRepeats(animationType), let key = cylBadgeAnimationKeyForType(animationType),
              badge.window != nil, !badge.isHidden, badge.alpha > 0.01 else {
            return
        }
        if cylShouldReduceBadgeMotion() {
            cylRemoveBadgeAnimations()
            return
        }
        if badge.layer.animation(forKey: key) == nil {
            cylBeginAnimation()
        }
    }

    /**
     * [EN] Puts the badge back on top of its host and lays it out again. [CN] 把角标重新放到宿主最上层并重新布局。
     */
    @objc(cyl_refreshBadge)
    open dynamic func cylRefreshBadge() {
        if cylForwardBadgeToAnimatedItemIcon(#selector(UIView.cylRefreshBadge)) {
            return
        }
        guard let badge = cyl_badge else {
            return
        }
        let isInOverlay = (badge.superview as? CYLBadgeHostOverlayView)?.host === self
        if badge.superview !== self && !isInOverlay {
            return
        }
        let container = cylBadgeContainer(forHost: self)
        if badge.superview !== container {
            container.addSubview(badge)
        }
        container.bringSubviewToFront(badge)
        cylLayoutBadgeAtTopRightCorner()
        cylBadgeEnvironmentDidChange()
    }

    /**
     * [EN] YES while this view is hidden for a view shown in its place (#601); its badge then shows on an overlay above it.
     * [CN] 本视图因被替换显示而隐藏时为 YES（#601）；此时其角标显示在它上方的浮层上。
     */
    @objc(cyl_badgeHostReplacedByIconView)
    public dynamic var cyl_badgeHostReplacedByIconView: Bool {
        @objc(cyl_isBadgeHostReplacedByIconView) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.hostReplacedByIconView) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setBadgeHostReplacedByIconView:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.hostReplacedByIconView, newValue ? NSNumber(value: true) : nil,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Removes every appearance set on this view, so it follows `CYLBadgeAppearance` again.
     * [CN] 移除本视图上设置的所有外观，使其重新跟随 `CYLBadgeAppearance`。
     */
    @objc(cyl_resetBadgeAppearance)
    public dynamic func cylResetBadgeAppearance() {
        for key in [CYLBadgeViewKeys.font, CYLBadgeViewKeys.backgroundColor, CYLBadgeViewKeys.textColor,
                    CYLBadgeViewKeys.centerOffset, CYLBadgeViewKeys.radius, CYLBadgeViewKeys.margin,
                    CYLBadgeViewKeys.cornerRadius, CYLBadgeViewKeys.maximumBadgeNumber, CYLBadgeViewKeys.borderColor,
                    CYLBadgeViewKeys.borderWidth] {
            objc_setAssociatedObject(self, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        guard let badge = cyl_badge else {
            return
        }
        badge.backgroundColor = cyl_badgeBackgroundColor
        badge.textColor = cyl_badgeTextColor
        badge.font = cyl_badgeFont
        cylApplyBadgeBorder()
    }

    private func cylShouldReduceBadgeMotion() -> Bool {
        cyl_badgeRespectsReduceMotion && UIAccessibility.isReduceMotionEnabled
    }

    private func cylRemoveBadgeAnimations() {
        guard let layer = cyl_badge?.layer else {
            return
        }
        let wasAnimating = !(layer.animationKeys() ?? []).isEmpty
        cylBadgeAllAnimationKeys().forEach { layer.removeAnimation(forKey: $0) }
        if wasAnimating {
            cylPostBadgeEvent("cyl.badge.animationDidStop", ["finished": false])
        }
    }

    // MARK: Other private methods

    /**
     * [EN] Sizes the badge to its text (the label of a `CYLTabBarBadgeView`, or the badge itself when it is a label).
     * [CN] 按文本确定角标尺寸（`CYLTabBarBadgeView` 的 label，或角标本身为 label 时）。
     */
    private func cylAdjustLabelWidth(_ badge: UIView & CYLBadgeTextDisplaying) {
        let label: UILabel?
        if let badgeLabel = badge as? UILabel {
            label = badgeLabel
        } else {
            label = (badge as? CYLTabBarBadgeView)?.badgeLabel
        }
        guard let label, let text = label.text, !text.isEmpty else {
            return
        }
        let size = cylGetLabelSize(label)
        if size == .zero {
            return
        }
        var frame = label.frame
        frame.size = CGSize(width: ceil(size.width), height: ceil(size.height))
        // [EN] Changing only the label does not stretch the badge; its own frame changes too.
        // [CN] 只修改 label 无法拉伸角标，角标自身的 frame 也要修改。
        label.frame = frame
        badge.frame = frame
    }

    /**
     * [EN] A badge is one line: the text is measured as one line and the label keeps one line (`numberOfLines` 1), so a
     *      shortfall never wraps it into a clipped second line. A text with a line break shows only its first line.
     * [CN] 角标只有一行：按单行测量文本并让 label 保持单行（`numberOfLines` 为 1），宽度稍有不足也不会换出被裁掉的第二行。含换行符的文本
     *      只显示第一行。
     */
    private func cylGetLabelSize(_ label: UILabel) -> CGSize {
        label.numberOfLines = 1
        guard let text = label.text, !text.isEmpty, let font = label.font else {
            return .zero
        }
        let size = (text as NSString).size(withAttributes: [.font: font])
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    // MARK: Animation

    /**
     * [EN] Plays the animation of `cyl_badgeAnimationType`, replacing (not stacking on) the previous one. To add a type: add
     *      it to `CYLBadgeAnimationType` with its key (CYLBadgeProtocol.h), its animation to `CAAnimation+CYLBadgeExtention`,
     *      and a case to `CYLBadgeAnimationForType()`.
     * [CN] 播放 `cyl_badgeAnimationType` 的动画，替换（而不是叠加）之前的动画。新增类型：在 `CYLBadgeAnimationType` 中添加类型与 key
     *      （CYLBadgeProtocol.h），在 `CAAnimation+CYLBadgeExtention` 中添加动画，并在 `CYLBadgeAnimationForType()` 中添加分支。
     */
    @objc(cyl_beginAnimation)
    dynamic func cylBeginAnimation() {
        guard let badge = cyl_badge else {
            return
        }
        cylRemoveBadgeAnimations()
        if cylShouldReduceBadgeMotion() {
            return
        }
        #if CYL_BADGE_ANIMATION_DISABLED
        // [EN] Badge debugging build option (docs/Badge-Debugging.md): no badge animation, so a screenshot shows the badge at
        //      its laid-out place. Never ship a release with it.
        // [CN] 角标调试编译选项（docs/Badge-Debugging.md）：不播放角标动画，截图中的角标就在布局位置。不要在发布版本中开启。
        return
        #endif
        let animationType = cyl_badgeAnimationType
        if let animation = cylBadgeAnimationForTypeEntryPoint(animationType, badge.bounds.size),
           let key = cylBadgeAnimationKeyForType(animationType) {
            // [EN] A finite animation reports its end through the transaction's completion block; a repeating one ends when it is removed.
            // [CN] 有限次动画通过 transaction 的完成回调报告结束；循环动画在被移除时结束。
            CATransaction.begin()
            if !cylBadgeAnimationTypeRepeats(animationType) {
                CATransaction.setCompletionBlock { [weak self] in
                    self?.cylPostBadgeEvent("cyl.badge.animationDidStop", ["finished": true])
                }
            }
            badge.layer.add(animation, forKey: key)
            CATransaction.commit()
            cylPostBadgeEvent("cyl.badge.animationDidStart", ["animationType": animationType.rawValue])
        }
    }

    @objc(cyl_removeAnimation)
    dynamic func cylRemoveAnimation() {
        let wasAnimating = !(cyl_badge?.layer.animationKeys() ?? []).isEmpty
        cyl_badge?.layer.removeAllAnimations()
        if wasAnimating {
            cylPostBadgeEvent("cyl.badge.animationDidStop", ["finished": false])
        }
    }

    // MARK: Setters and getters

    /**
     * [EN] The badge view (a `CYLBadgeLabel`, or a `CYLTabBarBadgeView` on iOS 27 Liquid Glass). [CN] 角标视图。
     */
    @objc(cyl_badge)
    open dynamic var cyl_badge: (UIView & CYLBadgeTextDisplaying)? {
        @objc(cyl_badge) get {
            objc_getAssociatedObject(self, CYLBadgeViewKeys.badge) as? UIView & CYLBadgeTextDisplaying
        }
        @objc(cyl_setBadge:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.badge, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc(cyl_badgeFont) open dynamic var cyl_badgeFont: UIFont! {
        @objc(cyl_badgeFont) get {
            objc_getAssociatedObject(self, CYLBadgeViewKeys.font) as? UIFont ?? CYLBadgeAppearance.global.font
        }
        @objc(cyl_setBadgeFont:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.font, newValue, .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
            // [EN] nil restores the global font. [CN] nil 恢复全局字体。
            cyl_badge?.font = cyl_badgeFont
        }
    }

    @objc(cyl_badgeBackgroundColor) open dynamic var cyl_badgeBackgroundColor: UIColor! {
        @objc(cyl_badgeBackgroundColor) get {
            objc_getAssociatedObject(self, CYLBadgeViewKeys.backgroundColor) as? UIColor ?? CYLBadgeAppearance.global.backgroundColor
        }
        @objc(cyl_setBadgeBackgroundColor:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.backgroundColor, newValue, .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
            cyl_badge?.backgroundColor = cyl_badgeBackgroundColor
        }
    }

    @objc(cyl_badgeTextColor) open dynamic var cyl_badgeTextColor: UIColor! {
        @objc(cyl_badgeTextColor) get {
            objc_getAssociatedObject(self, CYLBadgeViewKeys.textColor) as? UIColor ?? CYLBadgeAppearance.global.textColor
        }
        @objc(cyl_setBadgeTextColor:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.textColor, newValue, .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
            cyl_badge?.textColor = cyl_badgeTextColor
        }
    }

    @objc(cyl_badgeAnimationType) open dynamic var cyl_badgeAnimationType: CYLBadgeAnimationType {
        @objc(cyl_badgeAnimationType) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.animationType) as? NSNumber)
                .flatMap { CYLBadgeAnimationType(rawValue: $0.uintValue) } ?? .none
        }
        @objc(cyl_setBadgeAnimationType:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.animationType, NSNumber(value: newValue.rawValue), .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
            cylRemoveAnimation()
            cylBeginAnimation()
        }
    }

    @objc(cyl_badgeAnimationTypeValue) open dynamic var cyl_badgeAnimationTypeValue: NSNumber {
        @objc(cyl_badgeAnimationTypeValue) get {
            NSNumber(value: cyl_badgeAnimationType.rawValue)
        }
        @objc(cyl_setBadgeAnimationTypeValue:) set {
            cyl_badgeAnimationType = CYLBadgeAnimationType(rawValue: newValue.uintValue) ?? .none
        }
    }

    @objc(cyl_badgeFrame) open dynamic var cyl_badgeFrame: CGRect {
        @objc(cyl_badgeFrame) get {
            guard let info = objc_getAssociatedObject(self, CYLBadgeViewKeys.frame) as? [String: NSNumber], info.count == 4 else {
                return .zero
            }
            return CGRect(x: info["x"]?.doubleValue ?? 0, y: info["y"]?.doubleValue ?? 0,
                          width: info["width"]?.doubleValue ?? 0, height: info["height"]?.doubleValue ?? 0)
        }
        @objc(cyl_setBadgeFrame:) set {
            // [EN] Ignore a frame UIKit cannot draw (NaN / infinite, or an empty size).
            // [CN] 忽略 UIKit 无法绘制的 frame（NaN / 无穷大，或尺寸为空）。
            let isFinite = newValue.origin.x.isFinite && newValue.origin.y.isFinite && newValue.width.isFinite
                && newValue.height.isFinite
            if !isFinite || newValue.width <= 0 || newValue.height <= 0 {
                return
            }
            let info: [String: NSNumber] = ["x": NSNumber(value: Double(newValue.origin.x)),
                                            "y": NSNumber(value: Double(newValue.origin.y)),
                                            "width": NSNumber(value: Double(newValue.width)),
                                            "height": NSNumber(value: Double(newValue.height))]
            objc_setAssociatedObject(self, CYLBadgeViewKeys.frame, info, .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
            cyl_badge?.frame = newValue
        }
    }

    @objc(cyl_badgeFrameValue) open dynamic var cyl_badgeFrameValue: NSValue {
        @objc(cyl_badgeFrameValue) get {
            NSValue(cgRect: cyl_badgeFrame)
        }
        @objc(cyl_setBadgeFrameValue:) set {
            cyl_badgeFrame = newValue.cgRectValue
        }
    }

    @objc(cyl_badgeCornerRadius) open dynamic var cyl_badgeCornerRadius: CGFloat {
        @objc(cyl_badgeCornerRadius) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.cornerRadius) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLBadgeAppearance.global.cornerRadius
        }
        @objc(cyl_setBadgeCornerRadius:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.cornerRadius, NSNumber(value: Double(newValue)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc(cyl_badgeCornerRadiusValue) open dynamic var cyl_badgeCornerRadiusValue: NSNumber {
        @objc(cyl_badgeCornerRadiusValue) get {
            NSNumber(value: Double(cyl_badgeCornerRadius))
        }
        @objc(cyl_setBadgeCornerRadiusValue:) set {
            cyl_badgeCornerRadius = CGFloat(newValue.doubleValue)
        }
    }

    @objc(cyl_badgeCenterOffset) open dynamic var cyl_badgeCenterOffset: CGPoint {
        @objc(cyl_badgeCenterOffset) get {
            guard let info = objc_getAssociatedObject(self, CYLBadgeViewKeys.centerOffset) as? [String: NSNumber], info.count == 2 else {
                return CYLBadgeAppearance.global.centerOffset
            }
            return CGPoint(x: info["x"]?.doubleValue ?? 0, y: info["y"]?.doubleValue ?? 0)
        }
        @objc(cyl_setBadgeCenterOffset:) set {
            let info: [String: NSNumber] = ["x": NSNumber(value: Double(newValue.x)), "y": NSNumber(value: Double(newValue.y))]
            objc_setAssociatedObject(self, CYLBadgeViewKeys.centerOffset, info, .OBJC_ASSOCIATION_RETAIN)
            if cylShouldUpdateBadgeSubviews() {
                return
            }
            if cyl_badge == nil {
                cylBadgeInit()
            }
            cylLayoutBadgeAtTopRightCorner()
        }
    }

    @objc(cyl_badgeCenterOffsetValue) open dynamic var cyl_badgeCenterOffsetValue: NSValue {
        @objc(cyl_badgeCenterOffsetValue) get {
            NSValue(cgPoint: cyl_badgeCenterOffset)
        }
        @objc(cyl_setBadgeCenterOffsetValue:) set {
            cyl_badgeCenterOffset = newValue.cgPointValue
        }
    }

    @objc(cyl_badgeRadius) open dynamic var cyl_badgeRadius: CGFloat {
        @objc(cyl_badgeRadius) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.radius) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLBadgeAppearance.global.radius
        }
        @objc(cyl_setBadgeRadius:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.radius, NSNumber(value: Double(newValue)), .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
        }
    }

    @objc(cyl_badgeRadiusValue) open dynamic var cyl_badgeRadiusValue: NSNumber {
        @objc(cyl_badgeRadiusValue) get {
            NSNumber(value: Double(cyl_badgeRadius))
        }
        @objc(cyl_setBadgeRadiusValue:) set {
            cyl_badgeRadius = CGFloat(newValue.doubleValue)
        }
    }

    @objc(cyl_badgeMargin) open dynamic var cyl_badgeMargin: CGFloat {
        @objc(cyl_badgeMargin) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.margin) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLBadgeAppearance.global.margin
        }
        @objc(cyl_setBadgeMargin:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.margin, NSNumber(value: Double(newValue)), .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
        }
    }

    @objc(cyl_badgeMarginValue) open dynamic var cyl_badgeMarginValue: NSNumber {
        @objc(cyl_badgeMarginValue) get {
            NSNumber(value: Double(cyl_badgeMargin))
        }
        @objc(cyl_setBadgeMarginValue:) set {
            cyl_badgeMargin = CGFloat(newValue.doubleValue)
        }
    }

    @objc(cyl_badgeMaximumBadgeNumber) open dynamic var cyl_badgeMaximumBadgeNumber: Int {
        @objc(cyl_badgeMaximumBadgeNumber) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.maximumBadgeNumber) as? NSNumber)?.intValue
                ?? CYLBadgeAppearance.global.maximumBadgeNumber
        }
        @objc(cyl_setBadgeMaximumBadgeNumber:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.maximumBadgeNumber, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN)
            if cyl_badge == nil {
                cylBadgeInit()
            }
        }
    }

    @objc(cyl_badgeMaximumBadgeNumberValue) open dynamic var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        @objc(cyl_badgeMaximumBadgeNumberValue) get {
            NSNumber(value: cyl_badgeMaximumBadgeNumber)
        }
        @objc(cyl_setBadgeMaximumBadgeNumberValue:) set {
            cyl_badgeMaximumBadgeNumber = newValue.intValue
        }
    }

    /**
     * [EN] The border color of the badge (nil: `CYLBadgeAppearance`). [CN] 角标的边框颜色（nil：`CYLBadgeAppearance`）。
     */
    @objc(cyl_badgeBorderColor)
    open dynamic var cyl_badgeBorderColor: UIColor? {
        @objc(cyl_badgeBorderColor) get {
            objc_getAssociatedObject(self, CYLBadgeViewKeys.borderColor) as? UIColor ?? CYLBadgeAppearance.global.borderColor
        }
        @objc(cyl_setBadgeBorderColor:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.borderColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cylApplyBadgeBorder()
        }
    }

    /**
     * [EN] The border width of the badge (negative or non-finite: 0). [CN] 角标的边框宽度（负数或非有限值：0）。
     */
    @objc(cyl_badgeBorderWidth)
    open dynamic var cyl_badgeBorderWidth: CGFloat {
        @objc(cyl_badgeBorderWidth) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.borderWidth) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLBadgeAppearance.global.borderWidth
        }
        @objc(cyl_setBadgeBorderWidth:) set {
            let borderWidth = newValue.isFinite ? max(0, newValue) : 0
            objc_setAssociatedObject(self, CYLBadgeViewKeys.borderWidth, NSNumber(value: Double(borderWidth)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cylApplyBadgeBorder()
        }
    }

    /**
     * [EN] YES (the default) removes repeating badge animations while Reduce Motion is on. [CN] 为 YES（默认）时，开启“减弱动态效果”
     *      时移除循环角标动画。
     */
    @objc(cyl_badgeRespectsReduceMotion)
    open dynamic var cyl_badgeRespectsReduceMotion: Bool {
        @objc(cyl_badgeRespectsReduceMotion) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.respectsReduceMotion) as? NSNumber)?.boolValue ?? true
        }
        @objc(cyl_setBadgeRespectsReduceMotion:) set {
            objc_setAssociatedObject(self, CYLBadgeViewKeys.respectsReduceMotion, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc(cyl_delayIfNeededForSeconds) open dynamic var cyl_delayIfNeededForSeconds: CGFloat {
        @objc(cyl_delayIfNeededForSeconds) get {
            (objc_getAssociatedObject(self, CYLBadgeViewKeys.delayIfNeededForSeconds) as? NSNumber).map { CGFloat($0.doubleValue) }
                ?? CYLBadgeViewKeys.defaultDelayIfNeededForSeconds
        }
        @objc(cyl_setDelayIfNeededForSeconds:) set {
            // [EN] A negative or non-finite delay is meaningless; treat it as no delay. [CN] 负数或非有限的延迟没有意义，视为不延迟。
            let delay = newValue.isFinite ? max(0, newValue) : 0
            objc_setAssociatedObject(self, CYLBadgeViewKeys.delayIfNeededForSeconds, NSNumber(value: Double(delay)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc(cyl_delayIfNeededForSecondsValue) open dynamic var cyl_delayIfNeededForSecondsValue: NSNumber {
        @objc(cyl_delayIfNeededForSecondsValue) get {
            NSNumber(value: Double(cyl_delayIfNeededForSeconds))
        }
        @objc(cyl_setDelayIfNeededForSecondsValue:) set {
            cyl_delayIfNeededForSeconds = CGFloat(newValue.doubleValue)
        }
    }

    @objc(cyl_isHidden)
    public dynamic func cylIsHidden() -> Bool {
        cylIsInvisiable()
    }

    /**
     * [EN] The view a badge of a bar or tab button is placed on: the image view of a tab button, the button inside a bar
     *      button, else this view.
     * [CN] 导航栏或 Tab 按钮的角标所在的视图：Tab 按钮的图片视图、导航栏按钮内部的按钮，否则为本视图。
     */
    @objc(cyl_findBarButtonContentView)
    public dynamic func cylFindBarButtonContentView() -> UIView {
        let className = NSStringFromClass(type(of: self))
        if className == "UITabBarButton" || className == "_UITabButton" {
            // [EN] With Core, the tab image view it tracks (`-cyl_tabImageView`, called by selector: CYLBadgeView builds without
            //      Core too); without it, the first image view.
            // [CN] 有 Core 时使用其跟踪的 Tab 图片视图（`-cyl_tabImageView`，通过 selector 调用：CYLBadgeView 也可脱离 Core 编译）；
            //      否则使用第一个图片视图。
            let tabImageViewSelector = NSSelectorFromString("cyl_tabImageView")
            if responds(to: tabImageViewSelector) {
                return perform(tabImageViewSelector)?.takeUnretainedValue() as? UIView ?? self
            }
            return subviews.first { $0 is UIImageView } ?? self
        }
        if className == "_UIButtonBarButton", let button = subviews.first(where: { $0 is UIButton }) {
            return button
        }
        return self
    }

    /**
     * [EN] The class of new badge views: `CYLBadgeLabel` before iOS 27; on iOS 27, `CYLTabBarBadgeView` with Liquid Glass,
     *      else `CYLBadgeLabel` when FlatDesign is part of the build (nil otherwise, as before).
     * [CN] 新角标视图的类：iOS 27 之前为 `CYLBadgeLabel`；iOS 27 上液态玻璃为 `CYLTabBarBadgeView`，否则在包含扁平样式时为
     *      `CYLBadgeLabel`（否则为 nil，与以前相同）。
     */
    @objc(cyl_badgeClass)
    dynamic func cylBadgeClass() -> UIView.Type? {
        // [EN] `CYL_IS_IOS_27` in Objective-C. [CN] Objective-C 中的 `CYL_IS_IOS_27`。
        if (UIDevice.current.systemVersion as NSString).floatValue < 27 {
            return CYLBadgeLabel.self
        }
        if cylIsCYLTabBarStyleTypeLiquidGlass() {
            return CYLTabBarBadgeView.self
        }
        // [EN] `CYL_FLATDESIGN_AVAILABLE` in Objective-C: FlatDesign is part of the build.
        // [CN] Objective-C 中的 `CYL_FLATDESIGN_AVAILABLE`：扁平样式参与编译。
        return NSClassFromString("CYLFlatDesignTabBar") != nil ? CYLBadgeLabel.self : nil
    }

    private func cylIsCYLTabBarStyleTypeLiquidGlass() -> Bool {
        CYLUtils.isLiquidGlassActive()
    }

    @objc(cyl_shouldUpdateBadgeSubviews)
    dynamic func cylShouldUpdateBadgeSubviews() -> Bool {
        CYLUtils.isLiquidGlassActive()
    }
}

/**
 [EN] The `CYLBadgeProtocol` conformance, declared in Swift since step 115 (it was in the Objective-C category header).
 [CN] `CYLBadgeProtocol` 遵循关系，自第 115 步起在 Swift 中声明（原在 Objective-C 类别头文件中）。
 */
extension UIView: CYLBadgeProtocol {}

