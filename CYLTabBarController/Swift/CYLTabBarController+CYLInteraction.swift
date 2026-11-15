//
//  CYLTabBarController+CYLInteraction.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import AudioToolbox
import UIKit

/**
 * [EN] The long press of the tab buttons. Its own class: CYLTabBar treats every `UILongPressGestureRecognizer` added to it as the
 *      Liquid Glass one, and this one is added to the tab bar controller's view anyway.
 * [CN] Tab 按钮的长按手势，使用单独的类：CYLTabBar 会把添加给它的 `UILongPressGestureRecognizer` 当作液态玻璃的手势；而且本手势添加在
 *      TabBarController 的 view 上。
 */
@objc(CYLTabButtonLongPressGestureRecognizer)
final class CYLTabButtonLongPressGestureRecognizer: UILongPressGestureRecognizer {
    weak var cylPressedControl: UIControl?
}

/**
 * [EN] The pan of `cyl_swipeToSwitchTabEnabled`. [CN] `cyl_swipeToSwitchTabEnabled` 的拖动手势。
 */
@objc(CYLTabBarSwipeGestureRecognizer)
final class CYLTabBarSwipeGestureRecognizer: UIPanGestureRecognizer {}

/**
 * FIX: issue #152 / #535 — long press, Reselect and DoubleTap in Liquid Glass.
 * [EN] One press on a tab button, followed through UIKit's own Liquid Glass gestures (the continuous selection and the long press
 *      that lifts the lens), which `CYLTabBar` forwards: in Liquid Glass they receive every touch on the tab buttons, and a gesture
 *      added by the library does not. The press is one tap when it ends where it began, a long press when it is held for
 *      `cyl_tabButtonLongPressMinimumDuration`, and neither when the finger moves to switch tabs. The idea of one tracker for tap,
 *      long tap and double tap, with the item found by its position rather than by `hitTest`, follows Telegram-iOS's tab bar
 *      (`TapLongTapOrDoubleTapGestureRecognizer`); no code is taken from it.
 * [CN] 一次按在 Tab 按钮上的触摸，通过 `CYLTabBar` 转发的系统液态玻璃手势（连续选择手势与抬起 lens 的长按手势）跟踪：液态玻璃下 Tab
 *      按钮上的每次触摸都由它们接收，库自己添加的手势收不到。在按下的位置结束算一次点击，按住 `cyl_tabButtonLongPressMinimumDuration`
 *      算长按，手指移动去切换 Tab 时两者都不算。用一个跟踪器同时处理点击、长按与双击、按位置而不是 `hitTest` 找到 Tab，这一思路参考
 *      Telegram-iOS 的 TabBar（`TapLongTapOrDoubleTapGestureRecognizer`），未使用其代码。
 */
final class CYLTabBarLiquidGlassPress {
    /// [EN] The UIKit gesture this press is followed through. [CN] 跟踪这次触摸所用的系统手势。
    weak var gestureRecognizer: UIGestureRecognizer?
    weak var control: UIControl?
    weak var selectedViewControllerAtTouchDown: UIViewController?
    var windowStartPoint = CGPoint.zero
    var moved = false
    var longPressReported = false
    /// [EN] Tells a pending long press timer whether it still belongs to this press. [CN] 用于判断尚未触发的长按计时是否仍属于本次触摸。
    var generation = 0
}

/**
 * [EN] One system sound for `cyl_tabButtonTapSoundURL`, created once and disposed of with this object.
 * [CN] `cyl_tabButtonTapSoundURL` 对应的系统音效，只创建一次，随本对象释放。
 */
final class CYLTabBarTapSound {
    /// [EN] The system keyboard click. [CN] 系统键盘点击声。
    static let defaultSoundID: SystemSoundID = 1104

    let url: URL
    let soundID: SystemSoundID

    init?(url: URL) {
        var soundID: SystemSoundID = 0
        guard url.isFileURL, AudioServicesCreateSystemSoundID(url as CFURL, &soundID) == kAudioServicesNoError else { return nil }
        self.url = url
        self.soundID = soundID
    }

    deinit {
        AudioServicesDisposeSystemSoundID(soundID)
    }
}

/**
 * [EN] The state of this category, one object per tab bar controller. [CN] 本分类的状态，每个 TabBarController 一个对象。
 */
final class CYLInteractionSettings: NSObject {
    var tapAnimationType: CYLTabButtonTapAnimationType = .none
    /// [EN] One object per type, kept until the type changes. [CN] 每种类型一个对象，类型改变前一直复用。
    var tapAnimation: CYLTabButtonAnimation?
    var defaultAnimation: CYLTabButtonAnimation?
    weak var previousAnimatedControl: UIControl?
    weak var highlightedControl: UIControl?
    var tapSoundEnabled = false
    var tapSound: CYLTabBarTapSound?
    var hapticFeedbackEnabled = false
    var hapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    var hapticFeedbackGenerator: UIImpactFeedbackGenerator?
    var didLongPressControlBlock: CYLTabBarControllerDidLongPressControlBlock?
    var longPressMinimumDuration: TimeInterval = 0.5
    var swipeToSwitchTabEnabled = false
    var isSwitchingToAdjacentTab = false
    var interactionHandler: CYLTabBarInteractionHandler?
    var liquidGlassPress: CYLTabBarLiquidGlassPress?
    var liquidGlassSeen = false
}

private enum CYLInteractionKeys {
    static let settings = CYLUtilsKeys.key("cyl_interactionSettings")
    static let lastSelectAnimation = CYLUtilsKeys.key("cyl_lastSelectAnimation")
    static let tabButtonAnimation = CYLUtilsKeys.key("cyl_tabButtonAnimation")
    /// [EN] How far the finger may move and still be a tap or a long press, in points. [CN] 仍算点击或长按时手指可移动的距离（pt）。
    static let liquidGlassPressAllowableMovement: CGFloat = 10
}

/**
 * [EN] The method only `CYLTabBar.m` declares. [CN] 只在 `CYLTabBar.m` 中声明的方法。
 */
@objc protocol CYLTabBarVerticalBarPrivateAPI {
    @objc(cyl_verticalBarTabButtonAtWindowPoint:) func cylVerticalBarTabButton(atWindowPoint point: CGPoint) -> UIControl?
}

// MARK: - Views of a tab button

/**
 * [EN] The steps of a `CYLTabButtonAnimation`. [CN] `CYLTabButtonAnimation` 的各个动画步骤。
 */
private enum CYLTabButtonAnimationStep: String {
    case select = "Select", deselect = "Deselect", reselect = "Reselect", highlight = "Highlight", dehighlight = "Dehighlight"

    /// [EN] The `cylPlay…` (no underscore) selector. [CN] `cylPlay…`（无下划线）方法。
    var camelCaseSelector: Selector { NSSelectorFromString("cylPlay\(rawValue)AnimationWithTabButton:iconView:titleLabel:") }
    /// [EN] The `cyl_play…` selector. [CN] `cyl_play…` 方法。
    var underscoreSelector: Selector { NSSelectorFromString("cyl_play\(rawValue)AnimationWithTabButton:iconView:titleLabel:") }
}

private enum CYLTabButtonViews {

    /// [EN] FlatDesign tab buttons have their own `imageView` and `titleLabel`. [CN] 扁平样式的 Tab 按钮有自己的 `imageView` 与 `titleLabel`。
    static func flatDesignSubview(of control: UIControl, key: String) -> UIView? {
        guard let buttonClass = NSClassFromString("CYLFlatDesignTabBarButton"), control.isKind(of: buttonClass) else { return nil }
        return control.value(forKey: key) as? UIView
    }

    static func isFlatDesignButton(_ control: UIControl) -> Bool {
        guard let buttonClass = NSClassFromString("CYLFlatDesignTabBarButton") else { return false }
        return control.isKind(of: buttonClass)
    }

    /// [EN] The view to animate as the icon: the Lottie view, else the image view. [CN] 作为图标播放动画的视图：Lottie 视图，否则为图片视图。
    static func iconView(_ control: UIControl) -> UIView {
        // [EN] FIX: issue #601 — a view shown in place of the icon: the tap animation plays on that view.
        // [CN] FIX: issue #601 — 替换图标显示的视图：点击动画在该视图上播放。
        if let iconView = control.subviews.first(where: { $0.cyl_tabBarItemIconView && !$0.isHidden }) {
            return iconView
        }
        // [EN] FIX: issue #604 — a tab with an animated icon animates its animation view. [CN] 有动画图标的 Tab 对其动画视图播放动画。
        if let animationView = control.cyl_tabBarItemAnimationView() {
            return animationView
        }
        if let button = control as? UIButton {
            return button.imageView ?? control
        }
        if isFlatDesignButton(control) {
            return flatDesignSubview(of: control, key: "imageView") ?? control
        }
        return control.cyl_tabImageView() ?? control
    }

    static func titleLabel(_ control: UIControl) -> UILabel? {
        if let button = control as? UIButton {
            return button.titleLabel
        }
        if isFlatDesignButton(control) {
            return flatDesignSubview(of: control, key: "titleLabel") as? UILabel
        }
        return control.cyl_tabLabel()
    }

    /**
     * [EN] The buttons that show `control`: itself, plus its copy in the Liquid Glass selected layer (a tab's selected button, or the
     *      plus button's `selectedContentView`).
     * [CN] 显示 `control` 的按钮：它自己，以及液态玻璃选中图层中的副本（Tab 的选中按钮，或 PlusButton 的 `selectedContentView`）。
     */
    static func layers(_ control: UIControl) -> [UIControl] {
        var selectedLayerControl: UIControl?
        if let plusButton = control as? CYLPlusButton {
            selectedLayerControl = ((plusButton as? CYLPlusButtonSubclassing)?.selectedContentView ?? nil) as UIControl?
        } else if CYLConstants.isLiquidGlassActive() {
            selectedLayerControl = control.cyl_platterSelected()
        }
        if let selectedLayerControl, selectedLayerControl !== control, selectedLayerControl.window != nil {
            return [control, selectedLayerControl]
        }
        return [control]
    }
}

// MARK: - Animations

private enum CYLTabButtonAnimationPlayer {

    /// [EN] Whether `animation` implements `step` in either spelling. [CN] `animation` 是否以任一写法实现了 `step`。
    static func implements(_ animation: CYLTabButtonAnimation?, _ step: CYLTabButtonAnimationStep) -> Bool {
        guard let animation else { return false }
        return animation.responds(to: step.camelCaseSelector) || animation.responds(to: step.underscoreSelector)
    }

    /**
     * [EN] Plays `step` of `animation` on every layer of `control`: the `cylPlay…` method when implemented, otherwise the `cyl_play…`
     *      one; both spellings run through here, so they behave the same.
     * [CN] 在 `control` 的每个图层上播放 `animation` 的 `step`：实现了 `cylPlay…` 时调用它，否则调用 `cyl_play…`；两种写法都经过这里，行为相同。
     */
    static func play(_ animation: CYLTabButtonAnimation, _ step: CYLTabButtonAnimationStep, on control: UIControl) {
        guard implements(animation, step) else {
            #if DEBUG
            // [EN] The select method is optional, so a missing or misspelled one is only logged. [CN] 选中方法是可选的，缺失或拼错时只打印日志。
            if step == .select {
                NSLog("[CYLTabBarController] %@ implements neither -cylPlaySelectAnimationWithTabButton:iconView:titleLabel: nor -cyl_playSelectAnimationWithTabButton:iconView:titleLabel:; no select animation plays.",
                      NSStringFromClass(type(of: animation as AnyObject)))
            }
            #endif
            return
        }
        let selector = animation.responds(to: step.camelCaseSelector) ? step.camelCaseSelector : step.underscoreSelector
        guard let implementation = (animation as AnyObject).method(for: selector) else { return }
        typealias Play = @convention(c) (AnyObject, Selector, UIControl, UIView, UILabel?) -> Void
        let play = unsafeBitCast(implementation, to: Play.self)
        for layer in CYLTabButtonViews.layers(control) {
            play(animation, selector, layer, CYLTabButtonViews.iconView(layer), CYLTabButtonViews.titleLabel(layer))
        }
    }

    /// [EN] Whether `animation` implements the badge-changed animation in either spelling. [CN] `animation` 是否以任一写法实现了角标变化动画。
    static func implementsBadgeChanged(_ animation: CYLTabButtonAnimation?) -> Bool {
        guard let animation else { return false }
        return animation.responds(to: NSSelectorFromString("cylPlayBadgeChangedAnimationWithTabButton:iconView:badgeView:")) ||
            animation.responds(to: NSSelectorFromString("cyl_playBadgeChangedAnimationWithTabButton:iconView:badgeView:"))
    }

    /// [EN] Plays the badge-changed animation: `cylPlay…` first, then `cyl_play…`. [CN] 播放角标变化动画：优先 `cylPlay…`，其次 `cyl_play…`。
    static func playBadgeChanged(_ animation: CYLTabButtonAnimation, on control: UIControl) {
        for layer in CYLTabButtonViews.layers(control) {
            let iconView = CYLTabButtonViews.iconView(layer)
            let badgeView = layer.cyl_tabBadgeView()
            if animation.responds(to: NSSelectorFromString("cylPlayBadgeChangedAnimationWithTabButton:iconView:badgeView:")) {
                animation.cylPlayBadgeChangedAnimation?(withTabButton: layer, iconView: iconView, badgeView: badgeView)
            } else {
                animation.cyl_playBadgeChangedAnimation?(withTabButton: layer, iconView: iconView, badgeView: badgeView)
            }
        }
    }

    /// [EN] Sets an optional BOOL property of the protocol (`cyl_setFromLeft:`, `cyl_setToRight:`). [CN] 设置协议中可选的 BOOL 属性。
    static func setBool(_ value: Bool, on animation: CYLTabButtonAnimation, setter name: String) {
        let selector = NSSelectorFromString(name)
        guard animation.responds(to: selector), let implementation = (animation as AnyObject).method(for: selector) else { return }
        typealias Setter = @convention(c) (AnyObject, Selector, Bool) -> Void
        unsafeBitCast(implementation, to: Setter.self)(animation, selector, value)
    }

    /**
     * [EN] When `control`'s last select animation is not `animation`, lets it undo what it left on the button (all layers in Liquid
     *      Glass), then forgets it.
     * [CN] 若 `control` 上一次的选中动画不是 `animation`，让它撤销留在按钮上的状态（液态玻璃下包括所有图层），然后不再记录。
     */
    static func resetIfReplaced(_ control: UIControl, by animation: CYLTabButtonAnimation?) {
        guard let lastAnimation = objc_getAssociatedObject(control, CYLInteractionKeys.lastSelectAnimation) as? CYLTabButtonAnimation,
              lastAnimation !== animation else { return }
        for layer in CYLTabButtonViews.layers(control) {
            lastAnimation.cyl_resetTabButton?(layer, iconView: CYLTabButtonViews.iconView(layer), titleLabel: CYLTabButtonViews.titleLabel(layer))
        }
        objc_setAssociatedObject(control, CYLInteractionKeys.lastSelectAnimation, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func animation(for type: CYLTabButtonTapAnimationType) -> CYLTabButtonAnimation? {
        switch type {
        case .scale: return CYLTabButtonScaleAnimation()
        case .zoomIn: return CYLTabButtonZoomInAnimation()
        case .bounce: return CYLTabButtonBounceAnimation()
        case .bounceWithFireworks:
            let animation = CYLTabButtonBounceAnimation()
            animation.playsFireworks = true
            return animation
        case .rotation: return CYLTabButtonRotationAnimation()
        case .flip: return CYLTabButtonFlipAnimation()
        case .fume: return CYLTabButtonFumeAnimation()
        default: return nil
        }
    }
}

extension CYLTabBarController {

    var cylInteraction: CYLInteractionSettings {
        if let settings = objc_getAssociatedObject(self, CYLInteractionKeys.settings) as? CYLInteractionSettings {
            return settings
        }
        let settings = CYLInteractionSettings()
        objc_setAssociatedObject(self, CYLInteractionKeys.settings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    private var cylTabBarView: UIView? { cyl_tabBar ?? tabBar }

    // MARK: - Tap animation

    @objc(cyl_tabButtonTapAnimationType)
    var cylTabButtonTapAnimationType: CYLTabButtonTapAnimationType {
        get { cylInteraction.tapAnimationType }
        @objc(cyl_setTabButtonTapAnimationType:) set {
            cylInteraction.tapAnimationType = newValue
            cylInteraction.tapAnimation = CYLTabButtonAnimationPlayer.animation(for: newValue)
        }
    }

    @objc(cyl_defaultTabButtonAnimation)
    var cylDefaultTabButtonAnimation: CYLTabButtonAnimation? {
        get { cylInteraction.defaultAnimation }
        @objc(cyl_setDefaultTabButtonAnimation:) set { cylInteraction.defaultAnimation = newValue }
    }

    /**
     * [EN] The index of `control`'s view controller in `viewControllers`, or nil (e.g. a plus button without a child view controller).
     * [CN] `control` 对应的控制器在 `viewControllers` 中的位置，没有时为 nil（例如没有子控制器的 PlusButton）。
     */
    private func cylViewControllerIndex(forTabControl control: UIControl?) -> Int? {
        guard let control else { return nil }
        let viewControllers = self.viewControllers ?? []
        if control is CYLPlusButton {
            guard hasPlusChildViewController() else { return nil }
            let index = control.cyl_tabBarChildViewControllerIndex
            return (index >= 0 && index < viewControllers.count) ? index : nil
        }
        if let index = viewControllers.firstIndex(where: { viewController in
            guard let tabButton = viewController.cyl_tabButton else { return false }
            return tabButton === control || tabButton.cyl_platterSelected() === control
        }) {
            return index
        }
        // [EN] FlatDesign only: the position among the bar's buttons. [CN] 仅扁平样式：在栏中按钮里的位置。
        if tabBarStyleType == .flatDesign, let tabBarClass = NSClassFromString("CYLFlatDesignTabBar"),
           let flatTabBar = cyl_tabBar, flatTabBar.isKind(of: tabBarClass),
           let buttons = flatTabBar.value(forKey: "tabBarButtons") as? [UIControl],
           let buttonIndex = buttons.firstIndex(where: { $0 === control }), buttonIndex < viewControllers.count {
            return buttonIndex
        }
        return nil
    }

    private func cylAnimation(forTabControl control: UIControl?) -> CYLTabButtonAnimation? {
        if let index = cylViewControllerIndex(forTabControl: control), let viewController = viewControllers?[index],
           let animation = viewController.cyl_tabButtonAnimation ?? viewController.cyl_getViewControllerInsteadOfNavigation().cyl_tabButtonAnimation {
            return animation
        }
        return cylInteraction.defaultAnimation ?? cylInteraction.tapAnimation
    }

    @objc(cyl_playTabButtonAnimationForControl:)
    func cylPlayTabButtonAnimation(for control: UIControl?) {
        guard let control else { return }
        let settings = cylInteraction
        // [EN] Held weakly: a tab button can be replaced by UIKit. [CN] 弱引用：Tab 按钮可能被 UIKit 替换。
        let previousControl = settings.previousAnimatedControl
        let index = cylViewControllerIndex(forTabControl: control)
        let previousIndex = cylViewControllerIndex(forTabControl: previousControl)
        // [EN] A button keeps the state its last select animation left; when another animation takes over, that one resets it first.
        //      The button selected before then plays its deselect animation, when its animation has one.
        // [CN] 按钮保留其上一次选中动画留下的状态；当其他动画接管时，先由上一次的动画撤销该状态。之前选中的按钮随后播放取消选中动画（其动画实现了该方法时）。
        if let previousControl, previousControl !== control {
            let previousAnimation = cylAnimation(forTabControl: previousControl)
            CYLTabButtonAnimationPlayer.resetIfReplaced(previousControl, by: previousAnimation)
            if let previousAnimation, CYLTabButtonAnimationPlayer.implements(previousAnimation, .deselect) {
                if let index, let previousIndex {
                    CYLTabButtonAnimationPlayer.setBool(previousIndex < index, on: previousAnimation, setter: "cyl_setToRight:")
                }
                CYLTabButtonAnimationPlayer.play(previousAnimation, .deselect, on: previousControl)
            }
        }
        // [EN] A plus button without a child view controller selects nothing: it is not recorded as the selected button.
        // [CN] 没有子控制器的 PlusButton 不会选中任何页面：不记录为已选中的按钮。
        if !(control is CYLPlusButton && index == nil) {
            settings.previousAnimatedControl = control
        }
        let animation = cylAnimation(forTabControl: control)
        CYLTabButtonAnimationPlayer.resetIfReplaced(control, by: animation)
        guard let animation else { return }
        objc_setAssociatedObject(control, CYLInteractionKeys.lastSelectAnimation, animation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        // [EN] A tap on the button animated last whose tab is still selected plays the reselect animation when there is one.
        // [CN] 点击上一次播放动画、且其 Tab 仍处于选中状态的按钮时，若动画实现了重复点击动画，则播放它。
        let isReselect = previousControl === control && index != nil && index == selectedIndex
        if isReselect && CYLTabButtonAnimationPlayer.implements(animation, .reselect) {
            CYLTabButtonAnimationPlayer.play(animation, .reselect, on: control)
            return
        }
        if let index, let previousIndex {
            CYLTabButtonAnimationPlayer.setBool(previousIndex < index, on: animation, setter: "cyl_setFromLeft:")
        }
        CYLTabButtonAnimationPlayer.play(animation, .select, on: control)
    }

    // MARK: - Highlight (pressed) animation

    /**
     * [EN] Plays the highlight (finger down) or dehighlight (finger up or cancelled) animation of `control`, when its animation
     *      implements it. Only one button is highlighted at a time; a new press dehighlights the previous one.
     * [CN] 播放 `control` 的按下或抬起 / 取消动画（其动画实现了对应方法时）。同一时间只有一个按钮处于按下状态；新的按压会先让之前的按钮恢复。
     */
    private func cylSetTabButtonHighlighted(_ highlighted: Bool, for control: UIControl?) {
        let settings = cylInteraction
        let highlightedControl = settings.highlightedControl
        var control = control
        if highlighted {
            guard let pressed = control, pressed !== highlightedControl else { return }
            if highlightedControl != nil {
                cylSetTabButtonHighlighted(false, for: highlightedControl)
            }
        } else {
            control = control ?? highlightedControl
            guard control != nil, control === highlightedControl else { return }
        }
        guard let control else { return }
        settings.highlightedControl = highlighted ? control : nil
        let step: CYLTabButtonAnimationStep = highlighted ? .highlight : .dehighlight
        guard let animation = cylAnimation(forTabControl: control), CYLTabButtonAnimationPlayer.implements(animation, step) else { return }
        CYLTabButtonAnimationPlayer.play(animation, step, on: control)
    }

    /// [EN] Touch targets of the classic and FlatDesign tab buttons and of the plus button. [CN] 经典、扁平样式 Tab 按钮与 PlusButton 的触摸事件。
    @objc(cyl_tabButtonTouchDown:)
    func cylTabButtonTouchDown(_ control: UIControl) {
        cylSetTabButtonHighlighted(true, for: control)
    }

    @objc(cyl_tabButtonTouchUp:)
    func cylTabButtonTouchUp(_ control: UIControl) {
        cylSetTabButtonHighlighted(false, for: control)
    }

    /**
     * [EN] Liquid Glass: UIKit's gestures receive the touches, so the press follows them. [CN] 液态玻璃：触摸由系统手势接收，因此按压状态跟随它们。
     */
    private func cylUpdateTabButtonHighlight(forLiquidGlass gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            cylSetTabButtonHighlighted(true, for: cylLiquidGlassTabControl(atWindowPoint: gestureRecognizer.location(in: view.window)))
        case .ended, .cancelled, .failed:
            cylSetTabButtonHighlighted(false, for: nil)
        default:
            break
        }
    }

    // MARK: - Badge-changed animation

    /**
     * [EN] Called by `CYLTabBar` when an item's `badgeValue` gets a new value: plays the badge-changed animation of that tab on the
     *      next run loop turn, on both Liquid Glass layers.
     * [CN] 当 item 的 `badgeValue` 被设为新值时由 `CYLTabBar` 调用：在下一个 runloop 播放该 Tab 的角标变化动画，液态玻璃的两个图层都会播放。
     */
    @objc(cyl_tabBarItemBadgeValueDidChange:)
    func cylTabBarItemBadgeValueDidChange(_ item: UITabBarItem) {
        guard let control = item.cyl_tabButton, let animation = cylAnimation(forTabControl: control),
              CYLTabButtonAnimationPlayer.implementsBadgeChanged(animation) else { return }
        DispatchQueue.main.async {
            CYLTabButtonAnimationPlayer.playBadgeChanged(animation, on: control)
        }
    }

    // MARK: - Tap sound and haptic feedback

    @objc(cyl_tabButtonTapSoundEnabled)
    var cylTabButtonTapSoundEnabled: Bool {
        get { cylInteraction.tapSoundEnabled }
        @objc(cyl_setTabButtonTapSoundEnabled:) set { cylInteraction.tapSoundEnabled = newValue }
    }

    @objc(cyl_tabButtonTapSoundURL)
    var cylTabButtonTapSoundURL: URL? {
        get { cylInteraction.tapSound?.url }
        @objc(cyl_setTabButtonTapSoundURL:) set {
            // [EN] The old sound is disposed of when its object is released. nil, or a file that cannot be played: the click.
            // [CN] 旧音效随其对象释放。nil 或无法播放的文件：使用点击声。
            let sound = newValue.flatMap { CYLTabBarTapSound(url: $0) }
            #if DEBUG
            if let newValue, sound == nil {
                NSLog("🔴 %@ %@", #function, newValue.absoluteString)
            }
            #endif
            cylInteraction.tapSound = sound
        }
    }

    @objc(cyl_tabButtonHapticFeedbackEnabled)
    var cylTabButtonHapticFeedbackEnabled: Bool {
        get { cylInteraction.hapticFeedbackEnabled }
        @objc(cyl_setTabButtonHapticFeedbackEnabled:) set {
            cylInteraction.hapticFeedbackEnabled = newValue
            // [EN] A new generator for the current style, prepared so the first tap has no delay.
            // [CN] 为当前强度新建反馈器并预先准备，第一次点击没有延迟。
            cylInteraction.hapticFeedbackGenerator = nil
            if newValue {
                cylHapticFeedbackGenerator.prepare()
            }
        }
    }

    @objc(cyl_tabButtonHapticFeedbackStyle)
    var cylTabButtonHapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        get { cylInteraction.hapticFeedbackStyle }
        @objc(cyl_setTabButtonHapticFeedbackStyle:) set {
            cylInteraction.hapticFeedbackStyle = newValue
            cylInteraction.hapticFeedbackGenerator = nil
        }
    }

    private var cylHapticFeedbackGenerator: UIImpactFeedbackGenerator {
        if let generator = cylInteraction.hapticFeedbackGenerator {
            return generator
        }
        let generator = UIImpactFeedbackGenerator(style: cylInteraction.hapticFeedbackStyle)
        cylInteraction.hapticFeedbackGenerator = generator
        return generator
    }

    @objc(cyl_playTabButtonTapFeedback)
    func cylPlayTabButtonTapFeedback() {
        let settings = cylInteraction
        if settings.tapSoundEnabled {
            AudioServicesPlaySystemSound(settings.tapSound?.soundID ?? CYLTabBarTapSound.defaultSoundID)
        }
        if settings.hapticFeedbackEnabled {
            let generator = cylHapticFeedbackGenerator
            generator.impactOccurred()
            // [EN] Ready for the next tap. [CN] 为下一次点击做准备。
            generator.prepare()
        }
    }

    // MARK: - Long press

    @objc(cyl_didLongPressControlBlock)
    var cylDidLongPressControlBlock: CYLTabBarControllerDidLongPressControlBlock? {
        get { cylInteraction.didLongPressControlBlock }
        @objc(cyl_setDidLongPressControlBlock:) set {
            cylInteraction.didLongPressControlBlock = newValue
            cylInstallInteractionGestureRecognizersIfNeeded()
        }
    }

    /**
     * [EN] The one long press duration, also behind `cyl_tabBarItemLongPressDuration` (issue #152): both features share one recognizer.
     *      At least 0.1 s.
     * [CN] 唯一的长按时长，`cyl_tabBarItemLongPressDuration`（issue #152）也使用它：两个功能共用同一个手势。最短 0.1 秒。
     */
    @objc(cyl_tabButtonLongPressMinimumDuration)
    var cylTabButtonLongPressMinimumDuration: TimeInterval {
        get { cylInteraction.longPressMinimumDuration }
        @objc(cyl_setTabButtonLongPressMinimumDuration:) set {
            let duration = max(newValue, 0.1)
            cylInteraction.longPressMinimumDuration = duration
            cylInteraction.interactionHandler?.longPressGestureRecognizer?.minimumPressDuration = duration
        }
    }

    /// [EN] YES when `cyl_didLongPressControlBlock` or `-tabBarController:didLongPressControl:` listens.
    /// [CN] 设置了 `cyl_didLongPressControlBlock` 或实现了 `-tabBarController:didLongPressControl:` 时为 YES。
    func cylHandlesDidLongPressControl() -> Bool {
        cylInteraction.didLongPressControlBlock != nil ||
            (delegate?.responds(to: NSSelectorFromString("tabBarController:didLongPressControl:")) ?? false)
    }

    /**
     * [EN] YES when someone listens to long presses: the callbacks above, or the `CYLTabBarItemGestureLongPress` of issue #152.
     * [CN] 有人监听长按时为 YES：上面的回调，或 issue #152 的 `CYLTabBarItemGestureLongPress`。
     */
    func cylHandlesTabButtonLongPress() -> Bool {
        cylHandlesDidLongPressControl() || cylHasTabBarItemGestureReceiver()
    }

    /**
     * [EN] The tab button or plus button under `touchPoint` (in this controller's view), as `-tabBarController:didSelectControl:`
     *      reports it, or nil. The tab bars' own hit tests already resolve the plus button and the Liquid Glass platter.
     * [CN] `touchPoint`（本控制器 view 坐标）下的 Tab 按钮或 PlusButton（与 `-tabBarController:didSelectControl:` 上报的一致），没有时为 nil。
     *      TabBar 自己的 hitTest 已经处理了 PlusButton 和液态玻璃的 platter。
     */
    func cylTabControl(at touchPoint: CGPoint) -> UIControl? {
        guard let tabBar = cylTabBarView, !tabBar.isHidden, tabBar.window != nil,
              let hitView = tabBar.hitTest(tabBar.convert(touchPoint, from: view), with: nil),
              var control = hitView.cyl_nearestControl(below: tabBar) else { return nil }
        // [EN] FlatDesign only: its buttons are reported as they are. [CN] 仅扁平样式：其按钮按原样上报。
        if tabBarStyleType == .flatDesign {
            return control
        }
        if control.cyl_isPlatterSelectedControl() {
            control = control.cyl_platterNormal()
        }
        return cylPrivate.cylReportedControl(for: control) ?? control
    }

    /**
     * [EN] One long press, reported to both APIs: `cyl_didLongPressControlBlock` then `-tabBarController:didLongPressControl:`
     *      (issue #535), then `CYLTabBarItemGestureLongPress` (issue #152) for a tab button or the plus button.
     * [CN] 一次长按，向两套 API 上报：先 `cyl_didLongPressControlBlock`、再 `-tabBarController:didLongPressControl:`（issue #535），
     *      然后对 Tab 按钮或 PlusButton 上报 `CYLTabBarItemGestureLongPress`（issue #152）。
     */
    func cylReportLongPress(on control: UIControl) {
        cylInteraction.didLongPressControlBlock?(self, control)
        (delegate.map { $0 as AnyObject } as? CYLTabBarControllerDelegate)?.tabBarController?(self, didLongPress: control)
        guard cylHasTabBarItemGestureReceiver() else { return }
        // [EN] The pressed control may be an interactive subview of the plus button (#202): the LongPress belongs to the tab button
        //      or plus button it is in.
        // [CN] 被按住的控件可能是 PlusButton 上可交互的子控件（#202）：LongPress 属于它所在的 Tab 按钮或 PlusButton。
        let tabBar = cylTabBarView
        var candidate: UIControl? = control
        while let current = candidate {
            var viewController: UIViewController?
            if cylIsTabBarItemGestureControl(current, viewController: &viewController) {
                cylReportTabBarItemGesture(.longPress, control: current, viewController: viewController)
                return
            }
            candidate = current.superview?.cyl_nearestControl(below: tabBar)
        }
    }

    // MARK: - Liquid Glass (issue #152 / #535)

    /**
     * [EN] YES in Liquid Glass with a `CYLTabBar` whose UIKit gestures were captured: tab button touches then come through
     *      `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`, not through the library's own long press recognizer.
     * [CN] 液态玻璃下、且 `CYLTabBar` 已拿到系统手势时为 YES：此时 Tab 按钮的触摸经由 `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`。
     */
    /**
     * [EN] `tabBar` when it really is a `CYLTabBar`; nil otherwise (FlatDesign).
     * [CN] `tabBar` 确实是 `CYLTabBar` 时返回它；否则（扁平样式）返回 nil。
     */
    private var cylCheckedTabBar: CYLTabBar? {
        let systemTabBar: UITabBar = tabBar
        return systemTabBar as? CYLTabBar
    }

    func cylLiquidGlassReceivesTabTouches() -> Bool {
        // [EN] FIX: a FlatDesign controller's `tabBar` is not a `CYLTabBar` (the Objective-C property type is not checked):
        //      a real cast, or reading its recognizers crashed on the first touch in FlatDesign on iOS 26.
        // [CN] FIX：扁平样式控制器的 `tabBar` 不是 `CYLTabBar`（Objective-C 属性类型不做检查）：必须做真正的类型转换，否则在 iOS 26 扁平样式下
        //      首次触摸时读取其手势会崩溃。
        guard CYLConstants.isLiquidGlassActive(), let tabBar = cylCheckedTabBar else { return false }
        return (tabBar.liquidGlassContinuousGestureRecognizer as UIGestureRecognizer?) != nil ||
            (tabBar.liquidGlassLongGestureRecognizer as UIGestureRecognizer?) != nil
    }

    /**
     * [EN] YES once a Liquid Glass press was followed: tab taps are then counted when the press ends, which knows whether it was a tap,
     *      a long press or a drag; `-tabBarController:shouldSelectViewController:` no longer counts them.
     * [CN] 一旦跟踪过液态玻璃的触摸即为 YES：此后 Tab 的点击在触摸结束时计数，那里知道这次是点击、长按还是拖动；
     *      `-tabBarController:shouldSelectViewController:` 不再计数。
     */
    @objc(cyl_liquidGlassTakesTabTaps)
    func cylLiquidGlassTakesTabTaps() -> Bool {
        cylLiquidGlassReceivesTabTouches() && cylInteraction.liquidGlassSeen
    }

    /**
     * [EN] The tab button under `windowPoint` in Liquid Glass, found by position: the vertical bar's buttons (iOS 27.1), else a visible
     *      button whose frame holds the point, else, inside the tab bar, the one whose center is closest horizontally. Placeholders are
     *      skipped; the selected layer's copy and the tab under the plus button are reported as `-tabBarController:didSelectControl:` does.
     * [CN] 液态玻璃下 `windowPoint` 处的 Tab 按钮，按位置查找：先查竖向栏的按钮（iOS 27.1），再查 frame 包含该点的可见按钮，最后在 TabBar
     *      范围内取水平方向中心最近的按钮。跳过占位按钮；选中图层中的副本与 PlusButton 下方的 Tab 按 `-tabBarController:didSelectControl:` 的方式上报。
     */
    private func cylLiquidGlassTabControl(atWindowPoint windowPoint: CGPoint) -> UIControl? {
        guard let tabBar = cylCheckedTabBar, tabBar.window != nil, !tabBar.isHidden else { return nil }
        var control = unsafeBitCast(tabBar as AnyObject, to: CYLTabBarVerticalBarPrivateAPI.self).cylVerticalBarTabButton(atWindowPoint: windowPoint)
        if control == nil {
            var closestControl: UIControl?
            var closestDistance = CGFloat.greatestFiniteMagnitude
            for candidate in tabBar.cyl_visibleControls() ?? [] {
                if candidate.isHidden || candidate.alpha < 0.01 || candidate.window == nil || candidate.cyl_isPlaceholder {
                    continue
                }
                let frame = candidate.convert(candidate.bounds, to: nil)
                if frame.contains(windowPoint) {
                    control = candidate
                    break
                }
                let distance = abs(frame.midX - windowPoint.x)
                if distance < closestDistance {
                    closestDistance = distance
                    closestControl = candidate
                }
            }
            if control == nil && tabBar.convert(tabBar.bounds, to: nil).contains(windowPoint) {
                control = closestControl
            }
        }
        guard var found = control else { return nil }
        if found.cyl_isPlatterSelectedControl() {
            found = found.cyl_platterNormal()
        }
        return cylPrivate.cylReportedControl(for: found) ?? found
    }

    /**
     * [EN] Called by `CYLTabBar` for every update of UIKit's Liquid Glass gestures. See `CYLTabBarLiquidGlassPress`. A plus button keeps
     *      its own paths (its touch-up and the library's long press recognizer).
     * [CN] `CYLTabBar` 对系统液态玻璃手势的每次更新调用。见 `CYLTabBarLiquidGlassPress`。PlusButton 仍走自己的路径（抬起事件与库的长按手势）。
     */
    @objc(cyl_liquidGlassTabBarGestureRecognizerDidUpdate:)
    func cylLiquidGlassTabBarGestureRecognizerDidUpdate(_ gestureRecognizer: UIGestureRecognizer) {
        // [EN] The pressed animation follows every Liquid Glass press. [CN] 按压动画跟随每一次液态玻璃按压。
        if CYLConstants.isLiquidGlassActive() {
            cylUpdateTabButtonHighlight(forLiquidGlass: gestureRecognizer)
            // [EN] The plus button's lens mask is off while the lens is pressed or dragged (it cut the plus button in two).
            // [CN] 放大镜被按住或拖动期间关闭 PlusButton 的放大镜遮罩（它曾把 PlusButton 切成两半）。
            let lensIsMoving = gestureRecognizer.state == .began || gestureRecognizer.state == .changed
            if hasPlusButton(), let plusButton = cylPrivate.cylContextPlusButton() {
                plusButton.cylPrivate.cylSetLiquidGlassLensMaskSuspended(lensIsMoving)
            }
        }
        let handlesLongPress = cylHandlesTabButtonLongPress()
        let handlesTaps = cylHasTabBarItemTapReceiver()
        guard handlesLongPress || handlesTaps, cylLiquidGlassReceivesTabTouches() else { return }
        let settings = cylInteraction
        let press = settings.liquidGlassPress
        let windowPoint = gestureRecognizer.location(in: view.window)
        switch gestureRecognizer.state {
        case .began:
            // [EN] Both UIKit gestures can begin for the same touch: follow the first one.
            // [CN] 同一次触摸中两个系统手势都可能开始：只跟踪先开始的那个。
            if let followed = press?.gestureRecognizer, followed !== gestureRecognizer,
               followed.state == .began || followed.state == .changed {
                return
            }
            guard let control = cylLiquidGlassTabControl(atWindowPoint: windowPoint), !control.cyl_isPlusButton() else {
                settings.liquidGlassPress = nil
                return
            }
            settings.liquidGlassSeen = true
            let newPress = CYLTabBarLiquidGlassPress()
            newPress.gestureRecognizer = gestureRecognizer
            newPress.control = control
            newPress.selectedViewControllerAtTouchDown = selectedViewController
            newPress.windowStartPoint = windowPoint
            newPress.generation = (press?.generation ?? 0) + 1
            settings.liquidGlassPress = newPress
            if handlesLongPress {
                cylScheduleLiquidGlassLongPress(for: newPress)
            }
        case .changed:
            guard let press, press.gestureRecognizer === gestureRecognizer else { return }
            if hypot(windowPoint.x - press.windowStartPoint.x, windowPoint.y - press.windowStartPoint.y) > CYLInteractionKeys.liquidGlassPressAllowableMovement {
                // [EN] A drag across the tabs (UIKit switches the tab on lift): neither a tap nor a long press.
                // [CN] 在 Tab 间拖动（系统在抬起时切换）：既不算点击也不算长按。
                press.moved = true
            }
        case .ended:
            guard let press, press.gestureRecognizer === gestureRecognizer else { return }
            settings.liquidGlassPress = nil
            if handlesTaps, let control = press.control, !press.moved, !press.longPressReported {
                cylRecognizeLiquidGlassTap(on: control, selectedViewControllerAtTouchDown: press.selectedViewControllerAtTouchDown)
            }
        case .cancelled, .failed:
            if press?.gestureRecognizer === gestureRecognizer {
                settings.liquidGlassPress = nil
            }
        default:
            break
        }
    }

    /**
     * [EN] Reports the long press when the press is still held, and has not moved, after the long press duration. While a
     *      `didLongPressControl` listener is set, UIKit's gesture is then cancelled, so lifting the finger does not select the tab, as
     *      that API documents (#535); with only `CYLTabBarItemGestureLongPress` it still does (#152).
     * [CN] 经过长按时长后，触摸仍在按住且未移动时上报长按。设置了 `didLongPressControl` 监听时，随后取消系统手势，抬起手指时不会选中该 Tab
     *      （#535）；只使用 `CYLTabBarItemGestureLongPress` 时仍会选中（#152）。
     */
    private func cylScheduleLiquidGlassLongPress(for press: CYLTabBarLiquidGlassPress) {
        let generation = press.generation
        DispatchQueue.main.asyncAfter(deadline: .now() + cylInteraction.longPressMinimumDuration) { [weak self] in
            guard let self, let currentPress = self.cylInteraction.liquidGlassPress, currentPress.generation == generation,
                  !currentPress.moved, let control = currentPress.control, let gestureRecognizer = currentPress.gestureRecognizer,
                  gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
            currentPress.longPressReported = true
            self.cylReportLongPress(on: control)
            if self.cylHandlesDidLongPressControl() && gestureRecognizer.isEnabled {
                gestureRecognizer.isEnabled = false
                gestureRecognizer.isEnabled = true
            }
        }
    }

    // MARK: - Swipe

    @objc(cyl_swipeToSwitchTabEnabled)
    var cylSwipeToSwitchTabEnabled: Bool {
        get { cylInteraction.swipeToSwitchTabEnabled }
        @objc(cyl_setSwipeToSwitchTabEnabled:) set {
            cylInteraction.swipeToSwitchTabEnabled = newValue
            cylInstallInteractionGestureRecognizersIfNeeded()
        }
    }

    /// [EN] YES when `viewController` can be selected by a swipe. [CN] `viewController` 可以通过滑动选中时为 YES。
    private func cylCanSwipe(to viewController: UIViewController) -> Bool {
        if viewController.cyl_isPlaceholder {
            return false
        }
        guard let tabButton = viewController.cyl_tabButton else { return true }
        return !(tabButton.isHidden && tabButton.window != nil)
    }

    /**
     * [EN] Asks the delegate, as a tap does: a swipe is a tap on the tab it selects. The tab bar controller's own
     *      `-tabBarController:shouldSelectViewController:` runs the login check itself.
     * [CN] 与点击一样询问代理：滑动等同于点击它所选中的 Tab。TabBarController 自身的 `-tabBarController:shouldSelectViewController:` 会自己做登录检查。
     */
    private func cylShouldSwipeSelect(_ viewController: UIViewController) -> Bool {
        delegate?.tabBarController?(self, shouldSelect: viewController) ?? true
    }

    @objc(cyl_switchToAdjacentTabWithStep:animated:)
    func cylSwitchToAdjacentTab(withStep step: Int, animated: Bool) -> Bool {
        let viewControllers = self.viewControllers ?? []
        let selectedIndex = self.selectedIndex
        guard step != 0, selectedIndex != NSNotFound, selectedIndex < viewControllers.count else { return false }
        // FIX: issue #118
        // [EN] One switch at a time: a swipe during the slide (or during a UIKit transition) is ignored, as LxTabBarController learned
        //      (its issue #2: a tap during the transition crashed).
        // [CN] 同一时间只切换一次：滑动动画（或系统转场）进行中的滑动会被忽略，借鉴 LxTabBarController（其 issue #2：转场中点击导致崩溃）。
        guard !cylInteraction.isSwitchingToAdjacentTab, transitionCoordinator == nil else { return false }
        let direction = step > 0 ? 1 : -1
        var index = selectedIndex + direction
        var toViewController: UIViewController?
        // [EN] The next tab that can be selected. A tab the delegate refuses is skipped; a tab that needs login stops the swipe there and
        //      starts the login, as a tap does (FIX: issue #19 / #118). A plus button with a child view controller is a tab too: a swipe
        //      selects its page without asking the delegate, as a tap on the plus button does.
        // [CN] 下一个可以选中的 Tab。代理拒绝的 Tab 会被跳过；需要登录的 Tab 与点击一样，停在该处并发起登录（FIX: issue #19 / #118）。带子控制器的
        //      PlusButton 也是一个 Tab：滑动选中其页面且不询问代理，与点击 PlusButton 相同。
        while index >= 0 && index < viewControllers.count {
            let candidate = viewControllers[index]
            if cylCanSwipe(to: candidate) {
                if cylInterceptLoginIfNeeded(for: candidate) {
                    return false
                }
                let plusChild = hasPlusChildViewController() ? cylPrivate.cylContextPlusChildViewController() : nil
                let isPlusChildViewController = plusChild.map { candidate.cyl_isEqual(to: $0) } ?? false
                if isPlusChildViewController || cylShouldSwipeSelect(candidate) {
                    toViewController = candidate
                    break
                }
            }
            index += direction
        }
        guard toViewController != nil else { return false }
        let fromView = selectedViewController?.view
        let snapshotView = (animated && fromView?.window != nil) ? fromView?.snapshotView(afterScreenUpdates: false) : nil
        let fromFrame = fromView.flatMap { $0.window != nil ? $0.convert($0.bounds, to: view) : nil } ?? .zero
        self.selectedIndex = index
        guard let snapshotView, let toView = selectedViewController?.view else { return true }
        view.layoutIfNeeded()
        // [EN] Slide like `CYLTabBarSlideTransitionAnimator`: the old page (a snapshot) leaves, the new one comes in. The snapshot goes
        //      on this controller's view, below the tab bar, or below the subview of this view that holds it (Liquid Glass wraps it).
        // [CN] 与 `CYLTabBarSlideTransitionAnimator` 相同的滑动：旧页面（快照）滑出，新页面滑入。快照放在本控制器的 view 上、TabBar 下方，
        //      或包含 TabBar 的本 view 子视图下方（液态玻璃会包裹 TabBar）。
        let width = view.bounds.width
        snapshotView.frame = fromFrame
        var tabBarHost = cylTabBarView
        while let host = tabBarHost, host.superview !== view {
            tabBarHost = host.superview
        }
        if let tabBarHost {
            view.insertSubview(snapshotView, belowSubview: tabBarHost)
        } else {
            view.addSubview(snapshotView)
        }
        toView.transform = CGAffineTransform(translationX: width * CGFloat(direction), y: 0)
        cylInteraction.isSwitchingToAdjacentTab = true
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
            toView.transform = .identity
            snapshotView.transform = CGAffineTransform(translationX: -width * CGFloat(direction), y: 0)
        }, completion: { [weak self] _ in
            toView.transform = .identity
            snapshotView.removeFromSuperview()
            self?.cylInteraction.isSwitchingToAdjacentTab = false
        })
        return true
    }

    // MARK: - Gestures

    /**
     * [EN] Adds the long press and the swipe to this controller's view once, when one of them is used. Called from the setters and from
     *      `-viewDidLayoutSubviews`, never before the view is loaded. Each gesture asks first whether its feature is on.
     * [CN] 使用其中一个功能时，把长按与滑动手势添加到本控制器的 view 上（只添加一次）。由 setter 与 `-viewDidLayoutSubviews` 调用，不会在 view
     *      加载前调用。每个手势先判断对应功能是否开启。
     */
    @objc(cyl_installInteractionGestureRecognizersIfNeeded)
    func cylInstallInteractionGestureRecognizersIfNeeded() {
        let settings = cylInteraction
        guard isViewLoaded, settings.interactionHandler == nil,
              settings.swipeToSwitchTabEnabled || cylHandlesTabButtonLongPress() else { return }
        let handler = CYLTabBarInteractionHandler()
        handler.tabBarController = self

        let longPress = CYLTabButtonLongPressGestureRecognizer(target: handler, action: #selector(CYLTabBarInteractionHandler.cylLongPressDidUpdate(_:)))
        longPress.minimumPressDuration = settings.longPressMinimumDuration
        // [EN] Lifting the finger is not delayed; `cancelsTouchesInView` is decided per touch. [CN] 抬起手指不延迟；`cancelsTouchesInView` 在每次触摸时决定。
        longPress.delaysTouchesEnded = false
        longPress.delegate = handler
        view.addGestureRecognizer(longPress)
        handler.longPressGestureRecognizer = longPress

        let swipe = CYLTabBarSwipeGestureRecognizer(target: handler, action: #selector(CYLTabBarInteractionHandler.cylSwipeDidUpdate(_:)))
        swipe.delegate = handler
        swipe.cancelsTouchesInView = false
        view.addGestureRecognizer(swipe)
        handler.swipeGestureRecognizer = swipe

        settings.interactionHandler = handler
    }
}

// MARK: - CYLTabBarInteractionHandler

/**
 * [EN] The delegate and target of both gestures; it holds the tab bar controller weakly.
 * [CN] 两个手势的代理与响应者，弱引用 TabBarController。
 */
final class CYLTabBarInteractionHandler: NSObject, UIGestureRecognizerDelegate {
    weak var tabBarController: CYLTabBarController?
    var longPressGestureRecognizer: CYLTabButtonLongPressGestureRecognizer?
    var swipeGestureRecognizer: CYLTabBarSwipeGestureRecognizer?

    /// [EN] YES when the table view of `cell` offers swipe actions on its rows. [CN] `cell` 所在 tableView 的行支持侧滑操作时为 YES。
    private static func cellHasSwipeActions(_ cell: UITableViewCell) -> Bool {
        var superview = cell.superview
        while let current = superview, !(current is UITableView) {
            superview = current.superview
        }
        guard let tableView = superview as? UITableView else { return false }
        let delegate = tableView.delegate
        return delegate?.responds(to: #selector(UITableViewDelegate.tableView(_:trailingSwipeActionsConfigurationForRowAt:))) == true ||
            delegate?.responds(to: #selector(UITableViewDelegate.tableView(_:leadingSwipeActionsConfigurationForRowAt:))) == true ||
            tableView.dataSource?.responds(to: #selector(UITableViewDataSource.tableView(_:commit:forRowAt:))) == true
    }

    /// [EN] YES when `view` or one of its superviews scrolls horizontally. [CN] `view` 或其父视图可以横向滚动时为 YES。
    private static func isInHorizontalScrollView(_ view: UIView?, stopView: UIView) -> Bool {
        var current = view
        while let each = current, each !== stopView {
            if let scrollView = each as? UIScrollView {
                let insets = scrollView.adjustedContentInset
                if scrollView.isScrollEnabled && scrollView.contentSize.width + insets.left + insets.right > scrollView.bounds.width + 1 {
                    return true
                }
            }
            if each is UISlider || each is UISwitch {
                return true
            }
            // FIX: issue #118
            // [EN] A table view cell that can be swiped to show actions (e.g. Delete) keeps the horizontal swipe: a known conflict of the
            //      scroll-view based WXTabBarController (its issues #5 and #15).
            // [CN] 可以侧滑显示操作（例如删除）的 tableView cell 保留水平滑动：这是基于 scrollView 的 WXTabBarController 的已知冲突（其 issue #5 与 #15）。
            if let cell = each as? UITableViewCell, cellHasSwipeActions(cell) {
                return true
            }
            current = each.superview
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let tabBarController else { return false }
        if gestureRecognizer === longPressGestureRecognizer {
            guard tabBarController.cylHandlesTabButtonLongPress() else { return false }
            let control = tabBarController.cylTabControl(at: touch.location(in: tabBarController.view))
            // [EN] In Liquid Glass the tab buttons' long press comes from UIKit's own gestures; this recognizer keeps only the plus button.
            // [CN] 液态玻璃下 Tab 按钮的长按来自系统手势；此时本手势只处理 PlusButton。
            if let control, !control.cyl_isPlusButton(), tabBarController.cylLiquidGlassReceivesTabTouches() {
                return false
            }
            longPressGestureRecognizer?.cylPressedControl = control
            // [EN] Lifting the finger after a long press selects the tab only without `didLongPressControl` listeners (issue #535);
            //      `CYLTabBarItemGestureLongPress` keeps the selection (issue #152).
            // [CN] 仅在没有 `didLongPressControl` 监听时，长按后抬起手指才会选中该 Tab（issue #535）；`CYLTabBarItemGestureLongPress` 保留选中（issue #152）。
            longPressGestureRecognizer?.cancelsTouchesInView = tabBarController.cylHandlesDidLongPressControl()
            return control != nil
        }
        if gestureRecognizer === swipeGestureRecognizer {
            guard tabBarController.cylInteraction.swipeToSwitchTabEnabled, tabBarController.presentedViewController == nil else { return false }
            // [EN] Not on the tab bar, and not where a horizontal scroll (or a slider) needs the touch.
            // [CN] 不在 TabBar 上，也不在需要横向滚动（或滑块）的位置。
            if tabBarController.cylTabControl(at: touch.location(in: tabBarController.view)) != nil {
                return false
            }
            if let tabBar = tabBarController.cyl_tabBar ?? tabBarController.tabBar as UIView?, let touchView = touch.view, touchView.isDescendant(of: tabBar) {
                return false
            }
            return !Self.isInHorizontalScrollView(touch.view, stopView: tabBarController.view)
        }
        return true
    }

    /**
     * [EN] Both gestures work alongside the others: Liquid Glass has its own long press on the tab bar, and a vertical table view's pan
     *      also begins on a horizontal swipe.
     * [CN] 两个手势与其他手势同时识别：液态玻璃在 TabBar 上有自己的长按手势，竖向 tableView 的拖动手势在水平滑动时也会开始。
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === longPressGestureRecognizer || gestureRecognizer === swipeGestureRecognizer
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === swipeGestureRecognizer, let swipe = swipeGestureRecognizer else { return true }
        // [EN] Only at the root of a navigation stack, and only horizontally. [CN] 仅在导航栈的根控制器上，且仅水平方向。
        if let navigationController = tabBarController?.selectedViewController as? UINavigationController,
           navigationController.viewControllers.count > 1 {
            return false
        }
        let velocity = swipe.velocity(in: tabBarController?.view)
        return abs(velocity.x) > abs(velocity.y) * 1.5
    }

    @objc(cyl_longPressDidUpdate:)
    func cylLongPressDidUpdate(_ gestureRecognizer: CYLTabButtonLongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began, let tabBarController,
              let control = gestureRecognizer.cylPressedControl ?? tabBarController.cylTabControl(at: gestureRecognizer.location(in: tabBarController.view)) else { return }
        tabBarController.cylReportLongPress(on: control)
    }

    @objc(cyl_swipeDidUpdate:)
    func cylSwipeDidUpdate(_ gestureRecognizer: CYLTabBarSwipeGestureRecognizer) {
        guard gestureRecognizer.state == .ended, let tabBarController else { return }
        let translation = gestureRecognizer.translation(in: tabBarController.view)
        let velocity = gestureRecognizer.velocity(in: tabBarController.view)
        // [EN] A short fast flick counts too. [CN] 快速的短距离轻扫同样有效。
        let isSwipe = abs(translation.x) > 60 || abs(velocity.x) > 500
        guard isSwipe, abs(translation.x) >= abs(translation.y) else { return }
        // [EN] Finger to the left: the next tab. [CN] 手指向左：下一个 Tab。
        _ = tabBarController.cylSwitchToAdjacentTab(withStep: translation.x < 0 ? 1 : -1, animated: true)
    }
}

// MARK: - UIViewController (CYLTabButtonAnimation)

extension UIViewController {

    @objc(cyl_tabButtonAnimation)
    var cylTabButtonAnimation: CYLTabButtonAnimation? {
        get { objc_getAssociatedObject(self, CYLInteractionKeys.tabButtonAnimation) as? CYLTabButtonAnimation }
        @objc(cyl_setTabButtonAnimation:) set {
            objc_setAssociatedObject(self, CYLInteractionKeys.tabButtonAnimation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
