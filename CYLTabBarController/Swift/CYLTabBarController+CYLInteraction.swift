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
final class CYLTabBarSwipeGestureRecognizer: UIPanGestureRecognizer {
    // [EN] A class of its own so the pan can be found among a view's recognizers (`as?`); it adds no behavior.
    // [CN] 单独的类，使该拖动手势能在视图的手势识别器中被找到（`as?`）；不增加任何行为。
}

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
        if let animationView = control.cylTabBarItemAnimationView() {
            return animationView
        }
        if let button = control as? UIButton {
            return button.imageView ?? control
        }
        if isFlatDesignButton(control) {
            return flatDesignSubview(of: control, key: "imageView") ?? control
        }
        return control.cylTabImageView() ?? control
    }

    static func titleLabel(_ control: UIControl) -> UILabel? {
        if let button = control as? UIButton {
            return button.titleLabel
        }
        if isFlatDesignButton(control) {
            return flatDesignSubview(of: control, key: "titleLabel") as? UILabel
        }
        return control.cylTabLabel()
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
            selectedLayerControl = control.cylPlatterSelected()
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
            let badgeView = layer.cylTabBadgeView()
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
    open var cyl_tabButtonTapAnimationType: CYLTabButtonTapAnimationType {
        get { cylInteraction.tapAnimationType }
        @objc(cyl_setTabButtonTapAnimationType:) set {
            cylInteraction.tapAnimationType = newValue
            cylInteraction.tapAnimation = CYLTabButtonAnimationPlayer.animation(for: newValue)
        }
    }

    @objc(cyl_defaultTabButtonAnimation)
    open var cyl_defaultTabButtonAnimation: CYLTabButtonAnimation? {
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
            return tabButton === control || tabButton.cylPlatterSelected() === control
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
           let animation = viewController.cyl_tabButtonAnimation ?? viewController.cylGetViewControllerInsteadOfNavigation().cyl_tabButtonAnimation {
            return animation
        }
        return cylInteraction.defaultAnimation ?? cylInteraction.tapAnimation
    }

    @objc(cyl_playTabButtonAnimationForControl:)
    open func cyl_playTabButtonAnimation(for control: UIControl) {
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
    open var cyl_tabButtonTapSoundEnabled: Bool {
        get { cylInteraction.tapSoundEnabled }
        @objc(cyl_setTabButtonTapSoundEnabled:) set { cylInteraction.tapSoundEnabled = newValue }
    }

    @objc(cyl_tabButtonTapSoundURL)
    open var cyl_tabButtonTapSoundURL: URL? {
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
    open var cyl_tabButtonHapticFeedbackEnabled: Bool {
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
    open var cyl_tabButtonHapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
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
    open func cyl_playTabButtonTapFeedback() {
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
    open var cyl_didLongPressControlBlock: CYLTabBarControllerDidLongPressControlBlock? {
        @objc(cyl_didLongPressControlBlock) get { cylInteraction.didLongPressControlBlock }
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
    open var cyl_tabButtonLongPressMinimumDuration: TimeInterval {
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
              var control = hitView.cylNearestControl(below: tabBar) else { return nil }
        // [EN] FlatDesign only: its buttons are reported as they are. [CN] 仅扁平样式：其按钮按原样上报。
        if tabBarStyleType == .flatDesign {
            return control
        }
        if control.cylIsPlatterSelectedControl() {
            control = control.cylPlatterNormal()
        }
        return cylReportedControl(for: control) ?? control
    }

    /**
     * [EN] One long press, reported to both APIs: `cyl_didLongPressControlBlock` then `-tabBarController:didLongPressControl:`
     *      (issue #535), then `CYLTabBarItemGestureLongPress` (issue #152) for a tab button or the plus button.
     * [CN] 一次长按，向两套 API 上报：先 `cyl_didLongPressControlBlock`、再 `-tabBarController:didLongPressControl:`（issue #535），
     *      然后对 Tab 按钮或 PlusButton 上报 `CYLTabBarItemGestureLongPress`（issue #152）。
     */
    func cylReportLongPress(on control: UIControl) {
        cylInteraction.didLongPressControlBlock?(self, control)
        cylDelegate?.tabBarController?(self, didLongPress: control)
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
            candidate = current.superview?.cylNearestControl(below: tabBar)
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
            for candidate in tabBar.cylVisibleControls() ?? [] {
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
        if found.cylIsPlatterSelectedControl() {
            found = found.cylPlatterNormal()
        }
        return cylReportedControl(for: found) ?? found
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
                plusButton.cylSetLiquidGlassLensMaskSuspended(lensIsMoving)
            }
        }
        // [EN] A touch delivered late by a host (Flutter's `UiKitView`, a simulator's one-event tap) ends UIKit's gesture with
        //      no location, so UIKit selects nothing: select the tab under the touch's own hit test point, as a tap.
        // [CN] 宿主延迟交付的触摸（Flutter 的 `UiKitView`、模拟器的单事件点击）结束系统手势时没有位置，系统不会选中任何 Tab：按该触摸 hitTest 的位置
        //      像点击一样选中 Tab。
        if gestureRecognizer.state == .ended, CYLConstants.isLiquidGlassActive(), let tabBar = cylCheckedTabBar,
           tabBar.cylTouchLocationWasLost(gestureRecognizer) {
            let windowPoint = tabBar.cylTouchWindowLocation(of: gestureRecognizer)
            DispatchQueue.main.async { [weak self] in
                self?.cylSelectTabAfterLostTouch(atWindowPoint: windowPoint)
            }
        }
        let handlesLongPress = cylHandlesTabButtonLongPress()
        let handlesTaps = cylHasTabBarItemTapReceiver()
        guard handlesLongPress || handlesTaps, cylLiquidGlassReceivesTabTouches() else { return }
        let settings = cylInteraction
        let press = settings.liquidGlassPress
        let windowPoint = cylCheckedTabBar?.cylTouchWindowLocation(of: gestureRecognizer) ?? gestureRecognizer.location(in: view.window)
        switch gestureRecognizer.state {
        case .began:
            // [EN] Both UIKit gestures can begin for the same touch: follow the first one.
            // [CN] 同一次触摸中两个系统手势都可能开始：只跟踪先开始的那个。
            if let followed = press?.gestureRecognizer, followed !== gestureRecognizer,
               followed.state == .began || followed.state == .changed {
                return
            }
            guard let control = cylLiquidGlassTabControl(atWindowPoint: windowPoint), !control.cylIsPlusButton() else {
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
     * [EN] Selects the tab under `windowPoint` as UIKit selects a tapped tab: the delegate (with the login check and the tap
     *      report) is asked first, then the tab is selected and the delegate told. The selected tab and the plus button are left
     *      alone (their taps are reported when the gesture begins). See `-[CYLTabBar cyl_touchWindowLocationOfGestureRecognizer:]`.
     * [CN] 像系统选中被点击的 Tab 一样选中 `windowPoint` 处的 Tab：先询问代理（含登录检查与点击上报），再选中并通知代理。已选中的 Tab 与 PlusButton
     *      不处理（它们的点击在手势开始时上报）。
     */
    private func cylSelectTabAfterLostTouch(atWindowPoint windowPoint: CGPoint) {
        guard let control = cylLiquidGlassTabControl(atWindowPoint: windowPoint), !control.cylIsPlusButton(),
              let viewControllers, let index = viewControllers.firstIndex(where: { candidate in
                  candidate.cyl_tabButton === control || cylTabButtons(of: candidate).contains { $0 === control }
              }) else { return }
        let viewController = viewControllers[index]
        guard viewController !== selectedViewController else { return }
        guard delegate?.tabBarController?(self, shouldSelect: viewController) ?? true else { return }
        selectedViewController = viewController
        delegate?.tabBarController?(self, didSelect: viewController)
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
    open var cyl_swipeToSwitchTabEnabled: Bool {
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
    @discardableResult
    open func cyl_switchToAdjacentTab(withStep step: Int, animated: Bool) -> Bool {
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
                if cyl_interceptLoginIfNeeded(for: candidate) {
                    return false
                }
                let plusChild = hasPlusChildViewController() ? cylPrivate.cylContextPlusChildViewController() : nil
                let isPlusChildViewController = plusChild.map { candidate.cylIsEqual(to: $0) } ?? false
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
            if let control, !control.cylIsPlusButton(), tabBarController.cylLiquidGlassReceivesTabTouches() {
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
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
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
        _ = tabBarController.cyl_switchToAdjacentTab(withStep: translation.x < 0 ? 1 : -1, animated: true)
    }
}

// MARK: - UIViewController (CYLTabButtonAnimation)

extension UIViewController {

    /**
     * [EN] The tap animation of this page's tab, over the controller's `cyl_tabButtonTapAnimationType`.
     * [CN] 本页面所在 Tab 的点击动画，优先于控制器的 `cyl_tabButtonTapAnimationType`。
     */
    @objc(cyl_tabButtonAnimation)
    open var cyl_tabButtonAnimation: CYLTabButtonAnimation? {
        get { objc_getAssociatedObject(self, CYLInteractionKeys.tabButtonAnimation) as? CYLTabButtonAnimation }
        @objc(cyl_setTabButtonAnimation:) set {
            objc_setAssociatedObject(self, CYLInteractionKeys.tabButtonAnimation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Reported control and the Liquid Glass lens (docs/Swift-Migration.md, step 59)

/**
 * [EN] The control reported to `tabBarController:didSelectControl:` and the start of the Liquid Glass lens. Translated
 *      from Objective-C (docs/Swift-Migration.md, step 59); `CYLTabBarController+CYLPrivate.h` declares the two private
 *      methods, as CYLTabBarController.m calls them.
 * [CN] 上报给 `tabBarController:didSelectControl:` 的控件，以及液态玻璃放大镜的显示开始。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 59 步）；`CYLTabBarController+CYLPrivate.h` 声明这两个私有方法，因为 CYLTabBarController.m 会调用。
 */
extension CYLTabBarController {

    /**
     * [EN] The control to report for `control`: the plus button for the system tab button of its child view controller
     *      (the layer under the plus button), `control` otherwise.
     * [CN] 上报给代理的控件：PlusButton 子控制器的系统 Tab 按钮（PlusButton 下方的图层）换成 PlusButton 本身，其他控件不变。
     */
    @objc(cyl_reportedControlForControl:)
    func cylReportedControl(for control: UIControl?) -> UIControl? {
        // [EN] Guards: only with a plus button, and only when it has a child view controller (the second layer).
        // [CN] 仅在有 PlusButton，且其有子控制器（第二个图层）时处理。
        guard let control, hasPlusButton(), hasPlusChildViewController(), let plusButton = cylPrivate.cylContextPlusButton(),
              control !== plusButton, !control.cylIsPlusButton() else {
            return control
        }
        let plusChildViewController = cylPrivate.cylContextPlusChildViewController()
        let isPlusChildTabButton = control === plusChildViewController?.cyl_tabButton ||
            control === plusChildViewController?.cylGetViewControllerInsteadOfNavigation().cyl_tabButton
        return isPlusChildTabButton ? plusButton : control
    }

    /**
     * [EN] Remembers `control` until the end of the current run loop turn (one report per tap).
     * [CN] 记住 `control`，直到当前 runloop 结束（每次点击只上报一次）。
     */
    @objc(cyl_markControlReportedInCurrentRunLoop:)
    func cylMarkControlReportedInCurrentRunLoop(_ control: UIControl) {
        cylPrivate.cylSetControlReportedInCurrentRunLoop(control)
        DispatchQueue.main.async { [weak self] in
            self?.cylPrivate.cylSetControlReportedInCurrentRunLoop(nil)
        }
    }

    /**
     * [EN] `CYLTabBarControllerDelegate`: shows or hides the Liquid Glass lens (and its gestures) for `control`, as the
     *      delegate's `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` decides (YES without one).
     * [CN] `CYLTabBarControllerDelegate`：按代理的 `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` 显示或隐藏 `control`
     *      的液态玻璃放大镜（及其手势）（没有实现时为 YES）。
     */
    @objc(tabBarController:beginShowPlatterLiquidLensViewForControl:)
    func cylTabBarController(_ tabBarController: CYLTabBarController, beginShowPlatterLiquidLensViewFor control: UIControl) {
        let tabBar: UITabBar = tabBarController.tabBar
        guard CYLConstants.isLiquidGlassActive(), let tabBar = tabBar as? CYLTabBar else {
            return
        }
        let delegate = cylDelegate
        let shows = delegate?.tabBarController?(tabBarController, shouldShowPlatterLiquidLensViewFor: control) ?? true
        tabBar.cyl_platterLiquidLensViewContentView()?.cylSetHidden(!shows)
        tabBar.liquidGlassContinuousGestureRecognizer?.isEnabled = shows
        tabBar.liquidGlassLongGestureRecognizer?.isEnabled = shows
    }
}

// MARK: - Whether the Liquid Glass lens shows (docs/Swift-Migration.md, step 62)

/**
 * [EN] The key CYLTabBarController.m sets from a configuration's `CYLPlusButtonShowsSelection` (selector based, the same
 *      pointer on both sides). [CN] CYLTabBarController.m 根据配置的 `CYLPlusButtonShowsSelection` 设置的 key（基于 selector，两边是同一个指针）。
 */
enum CYLLiquidGlassLensKeys {
    static let plusButtonShowsSelection = CYLUtilsKeys.key("cyl_plusButtonShowsSelection")
}

/**
 * [EN] `CYLTabBarControllerDelegate`: whether the Liquid Glass lens shows for a control. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 62).
 *      TODO (2026-11-13, to verify): PR #793 keeps the lens on the plus page when the plus button's title is drawn by its tab
 *      item. The maintainer considers this as risky as `-[CYLPlusButton cyl_updateLiquidGlassMask]` (AGENTS.md). It is on by
 *      default; on any plus button bug after selection, turn it off first with the Swift compilation condition
 *      `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED` (before step 62: the Objective-C macro `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_ENABLED`
 *      set to 0), together with the mask, and test again.
 * [CN] `CYLTabBarControllerDelegate`：某个控件是否显示液态玻璃放大镜。已从 Objective-C 翻译（docs/Swift-Migration.md，第 62 步）。
 *      TODO（2026-11-13，待验证）：PR #793 在 PlusButton 标题由其 TabBarItem 绘制时，PlusButton 页面保留放大镜。维护者认为这与
 *      `-[CYLPlusButton cyl_updateLiquidGlassMask]` 一样危险（AGENTS.md）。默认开启；选中后出现任何 PlusButton bug 时，先设置 Swift 编译条件
 *      `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED` 关闭它（第 62 步之前：Objective-C 宏 `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_ENABLED` 设为 0），连同遮罩一起关闭，再测试。
 */
extension CYLTabBarController {

    /// [EN] The PR #793 switch: on unless `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED` is set. [CN] PR #793 的开关：除非设置了该条件，否则开启。
    private static var cylPlusButtonTitleKeepsLens: Bool {
        #if CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED
        return false
        #else
        return true
        #endif
    }

    /**
     * [EN] YES when the plus button's title is drawn by the tab item under it: the plus button class aligns its title with
     *      the tab titles (`+alignsTitleWithTabBarItemTitles`), its picture is not a background image with the title on it,
     *      and the plus child view controller's tab item has a title.
     * [CN] PlusButton 的标题由其下方的 TabBarItem 绘制时为 YES：PlusButton 类要求标题与 Tab 标题对齐，其图片不是标题画在上面的背景图，且 PlusButton
     *      子控制器的 TabBarItem 有标题。
     */
    @objc(cyl_plusButtonTitleIsDrawnByItsTabItem)
    func cylPlusButtonTitleIsDrawnByItsTabItem() -> Bool {
        guard let plusButton = cylPrivate.cylContextPlusButton(), plusButton.cylAlignsTitleWithTabBarItemTitles(),
              !plusButton.cylDrawsTitleOverBackgroundImage() else {
            return false
        }
        return !(cylPrivate.cylContextPlusChildViewController()?.tabBarItem.title ?? "").isEmpty
    }

    @objc(tabBarController:shouldShowPlatterLiquidLensViewForControl:)
    open dynamic func tabBarController(_ tabBarController: CYLTabBarController, shouldShowPlatterLiquidLensViewFor _: UIControl) -> Bool {
        let tabBar: UITabBar = tabBarController.tabBar
        guard CYLConstants.isLiquidGlassActive(), let tabBar = tabBar as? CYLTabBar else {
            return false
        }
        guard hasPlusChildViewController() else {
            return true
        }
        // [EN] `CYLPlusButtonShowsSelection`: the selection stays under the plus button while its page is selected.
        // [CN] `CYLPlusButtonShowsSelection`：选中 PlusButton 的页面时，选中效果保留在 PlusButton 下方。
        if (objc_getAssociatedObject(self, CYLLiquidGlassLensKeys.plusButtonShowsSelection) as? NSNumber)?.boolValue == true {
            return true
        }
        // [EN] A plus button whose title is aligned with the tab titles leaves the title to its tab item, drawn by UIKit; the
        //      selected tab's title is part of the lens content, so hiding the lens on the plus page hid the title as well
        //      (CYLSearchViewController's Flutter example, docs/Liquid-Glass-Robustness.md). Keep the selection then.
        // [CN] 标题与 Tab 标题对齐的 PlusButton 把标题交给其 TabBarItem，由 UIKit 绘制；选中 Tab 的标题属于放大镜内容，因此在 PlusButton 页面隐藏
        //      放大镜也会隐藏标题（CYLSearchViewController 的 Flutter 示例，docs/Liquid-Glass-Robustness.md）。此时保留选中效果。
        if Self.cylPlusButtonTitleKeepsLens && cylPlusButtonTitleIsDrawnByItsTabItem() {
            return true
        }
        let plusPageSelected = tabBarController.selectedViewController?.isEqual(cylPrivate.cylContextPlusChildViewController()) == true
        return !(plusPageSelected && !tabBar.isPlusButtonLayoutCentered())
    }
}

// MARK: - A reported tab tap (docs/Swift-Migration.md, step 63)

/**
 * [EN] Everything a reported tab tap does, the same in every style (`-didSelectControl:` for the classic style and Liquid
 *      Glass, `-cyl_flatDesignReportDidSelectControl:` for FlatDesign), each once per reported tap and also without a
 *      `didSelectControl` delegate. Translated from Objective-C (docs/Swift-Migration.md, step 63).
 * [CN] 每次上报的 Tab 点击要做的事，所有样式相同（经典样式与液态玻璃为 `-didSelectControl:`，扁平样式为
 *      `-cyl_flatDesignReportDidSelectControl:`），每次上报各执行一次，没有实现 didSelectControl 代理时同样执行。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 63 步）。
 */
extension CYLTabBarController {

    /**
     * [EN] 1. the tap animation, sound and haptic (issue #535); 2. a configuration plus button's action
     *      (`CYLTabBarControllerPlusButtonAction`); 3. `-tabBarController:didSelectControl:`; 4. Reselect / DoubleTap (issue #152).
     * [CN] 1. 点击动画、声音与触感反馈（issue #535）；2. 配置中 PlusButton 的回调（`CYLTabBarControllerPlusButtonAction`）；
     *      3. `-tabBarController:didSelectControl:`；4. Reselect / DoubleTap（issue #152）。
     */
    @objc(cyl_sendDidSelectControl:)
    func cylSendDidSelectControl(_ control: UIControl) {
        cyl_playTabButtonAnimation(for: control)
        cyl_playTabButtonTapFeedback()
        if control.cylIsPlusControl(), let plusButton = CYLPlusButton.cylPlusButton(forTabBarContext: context) {
            let tapped = NSSelectorFromString("cyl_configurationPlusButtonTapped")
            if plusButton.responds(to: tapped) {
                plusButton.perform(tapped)
            }
        }
        let delegate = cylDelegate
        delegate?.tabBarController?(self, didSelect: control)
        cylRecognizeTabBarItemGestureForReportedControl(control)
    }
}

// MARK: - A tab button's tap, classic and Liquid Glass (docs/Swift-Migration.md, step 64)

/**
 * [EN] `-didSelectControl:`: what a tap on a tab button (classic tab bar and Liquid Glass) does to the controls, the lens
 *      and the report. Translated from Objective-C (docs/Swift-Migration.md, step 64); the private header declares it, as
 *      CYLTabBarController.m calls it. FlatDesign reports through `-cyl_flatDesignReportDidSelectControl:` instead.
 * [CN] `-didSelectControl:`：点击 Tab 按钮（经典 TabBar 与液态玻璃）对控件、放大镜与上报所做的事。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 64 步）；私有头文件声明它，因为 CYLTabBarController.m 会调用。扁平样式改为通过
 *      `-cyl_flatDesignReportDidSelectControl:` 上报。
 */
extension CYLTabBarController {

    @objc(didSelectControl:)
    func cylDidSelectControl(_ control: UIControl?) {
        cylPrivate.cylSetNeedsUpdateTabBarItemIconViews()
        guard tabBarStyleType != .flatDesign else {
            return
        }
        let shouldSelectViewController = control.map { cylControlReportsTapsEntryPoint($0) && !$0.isHidden } ?? false
        var selectedContentControl: UIControl?
        if let tabBar = cyl_tabBar as? CYLTabBar {
            selectedContentControl = tabBar.cylSelectedContentControl(fromContentControl: control)
            if control?.cylIsPlusControl() == true {
                tabBar.cylSetSelectedControl(cylPrivate.cylContextPlusButton())
            } else {
                tabBar.cylSetSelectedControl(selectedContentControl ?? control)
            }
            // [EN] Liquid Glass with a plus child view controller: the plus button's stand-in in the selected layer keeps its
            //      own state (`-cyl_updateSelectedContentViewImage`); selecting it here left it with the old image after a
            //      theme change (plus child theme test) once the plus button reported its taps.
            // [CN] 液态玻璃且有 PlusButton 子控制器：PlusButton 在选中图层中的替身自己维护状态（`-cyl_updateSelectedContentViewImage`）；
            //      PlusButton 上报点击时若在这里选中它，换肤后替身会保留旧图片（PlusButton 子控制器换肤测试）。
            let plusButtonKeepsItsOwnState = CYLConstants.isLiquidGlassActive() && hasPlusChildViewController() &&
                control?.cylIsPlusControl() == true
            if shouldSelectViewController {
                ((tabBar.cylVisibleControls() ?? []) + (tabBar.cylPlatterSelectedContentViews() ?? [])).forEach { $0.isSelected = false }
                if !plusButtonKeepsItsOwnState {
                    control?.isSelected = true
                }
                // [EN] Shared by the classic tab bar and Liquid Glass; Lottie playback lives in tabChangedToSelectedIndex.
                // [CN] 非液态玻璃与液态玻璃逻辑共用，Lottie 播放逻辑都在 tabChangedToSelectedIndex 中。
                selectedContentControl?.isSelected = true
            }
        }
        guard let tappedControl = control ?? selectedViewController?.cyl_tabButton else {
            cylSetNeedsApplyTabBarItemAnimationTintColors()
            return
        }
        cylTabBarController(self, beginShowPlatterLiquidLensViewFor: tappedControl)
        // FIX: plus button badge does not change on tap
        // [EN] A plus button with a child view controller has two layers: the plus button and, under it, the system tab
        //      button of `plusChildViewController`. A tap could be reported with that system tab button, or not at all (the
        //      plus child view controller already selected disables it). Report the plus button itself instead (its own
        //      `reportsTapsToDelegate` still opts out), so the delegate always gets the same control for the plus button.
        // [CN] 带子控制器的 PlusButton 有两个图层：PlusButton 本身，以及其下方 `plusChildViewController` 的系统 Tab 按钮。点击时可能上报的是该系统
        //      Tab 按钮，或者根本不上报（子控制器已选中时该按钮被禁用）。这里统一上报 PlusButton 本身（其 `reportsTapsToDelegate` 仍可关闭回调）。
        let reportedControl = cylReportedControl(for: tappedControl) ?? tappedControl
        var shouldReport = shouldSelectViewController
        if reportedControl !== tappedControl {
            shouldReport = cylControlReportsTapsEntryPoint(reportedControl)
        }
        // [EN] One report per tap, only for a plus button with a child view controller: on Liquid Glass one tap reported it
        //      two or three times (the `selectedViewController` setter, `-setSelectedIndex:`, the gesture path), and a badge
        //      that toggles on each callback looked unchanged. Reports of the same control within one run loop turn belong
        //      to the same tap, so only the first one is sent. Tab buttons are not affected.
        // [CN] 每次点击只上报一次，仅限带子控制器的 PlusButton：液态玻璃下一次点击会上报两到三次（`selectedViewController` 的 setter、
        //      `-setSelectedIndex:`、手势路径），每次回调切换一次的角标看起来没有变化。同一 runloop 内对同一控件的多次上报属于同一次点击，只发送第一次。
        let isPlusButtonWithChildViewController = hasPlusButton() && hasPlusChildViewController() &&
            reportedControl === cylPrivate.cylContextPlusButton()
        if shouldReport && isPlusButtonWithChildViewController && reportedControl === cylPrivate.cylControlReportedInCurrentRunLoop() {
            shouldReport = false
        }
        if shouldReport {
            if isPlusButtonWithChildViewController {
                cylMarkControlReportedInCurrentRunLoop(reportedControl)
            }
            cylSendDidSelectControl(reportedControl)
        }
        cylSetNeedsApplyTabBarItemAnimationTintColors()
        guard shouldSelectViewController, let control else {
            return
        }
        // [EN] A tap plays the tab's animated images (they rest until played). [CN] 点击播放该 Tab 的动图（播放前保持静止）。
        cylPlayAnimatedImages(ofTabButton: control)
        if let selectedContentControl, selectedContentControl !== control {
            cylPlayAnimatedImages(ofTabButton: selectedContentControl)
        }
    }
}

// MARK: - The delegate as CYLTabBarControllerDelegate

extension CYLTabBarController {

    /**
     * [EN] The delegate seen as a `CYLTabBarControllerDelegate`, also when it only implements the methods without adopting the
     *      protocol (React Native's `CYLTabBarHostView`, many Objective-C apps): every method of the protocol is optional, so
     *      each call checks `respondsToSelector:` at run time, as the Objective-C code did. `delegate as?
     *      CYLTabBarControllerDelegate` was nil for such a delegate, so its `-tabBarController:didSelectControl:` was never
     *      called and React Native's onTabSelect stayed silent (regression of migration step 63, fixed 2026-11-19).
     * [CN] 把 delegate 视为 `CYLTabBarControllerDelegate`，包括只实现方法而未采用该协议的 delegate（React Native 的 `CYLTabBarHostView`、
     *      许多 Objective-C App）：协议的方法都是可选的，因此每次调用都会在运行时检查 `respondsToSelector:`，与 Objective-C 代码相同。
     *      对这样的 delegate，`delegate as? CYLTabBarControllerDelegate` 为 nil，其 `-tabBarController:didSelectControl:` 从未被调用，
     *      React Native 的 onTabSelect 没有任何事件（迁移第 63 步引入的回归，2026-11-19 修复）。
     */
    var cylDelegate: CYLTabBarControllerDelegate? {
        guard let delegate = (self as UITabBarController).delegate else {
            return nil
        }
        return unsafeBitCast(delegate as AnyObject, to: CYLTabBarControllerDelegate.self)
    }
}

// MARK: - The plus button in the Liquid Glass layers (docs/Swift-Migration.md, step 70)

/**
 * [EN] The associated object keys of the plus button's layout in the Liquid Glass layers.
 * [CN] PlusButton 在液态玻璃图层中布局所用的关联对象 key。
 */
private enum CYLPlusButtonGlassLayoutKeys {
    /// [EN] Re-entrancy guard. [CN] 防止重入。
    static let layingOut = CYLUtilsKeys.key("cyl_layingOutPlusButtonInGlassLayers")
    /// [EN] One fallback retry pending. [CN] 有一次兜底重试待执行。
    static let retryPending = CYLUtilsKeys.key("cyl_plusButtonGlassLayoutRetryPending")
}

/**
 * [EN] The plus button in the two Liquid Glass layers. Translated from Objective-C line by line (docs/Swift-Migration.md, step
 *      70); AGENTS.md's plus button rules apply (`-[CYLPlusButton cyl_updateLiquidGlassMask]` stays off; on any plus button
 *      bug, check it and PR #793's lens switch first).
 * [CN] PlusButton 在液态玻璃的两个图层中。已从 Objective-C 逐行翻译（docs/Swift-Migration.md，第 70 步）；适用 AGENTS.md 中 PlusButton 的规则
 *      （`-[CYLPlusButton cyl_updateLiquidGlassMask]` 保持关闭；出现任何 PlusButton 问题时先检查它与 PR #793 的放大镜开关）。
 */
extension CYLTabBarController {

    /**
     * [EN] Hides the tab icon under the plus button in both Liquid Glass layers and puts the plus button's stand-in
     *      (`selectedContentView`) in the selected layer. Idempotent, and run on every layout pass of the controller and of
     *      the tab bar: the selected layer is rendered later than the normal one, so whatever is missing now is added on a
     *      later pass. Everything is looked up again on each call. When the selected layer is still missing, one retry is
     *      scheduled as a fallback. A stand-in still inside an old tab button (UIKit rebuilds the buttons) is taken out
     *      first, so it can be put in the new one.
     * [CN] 在液态玻璃的两个图层中隐藏 PlusButton 下方的 Tab 图标，并把 PlusButton 的替身（`selectedContentView`）放进选中层。可重复调用，控制器与
     *      TabBar 每次布局都会执行：选中层比普通层渲染得晚，本次缺少的部分会在之后的布局中补上。每次调用都重新查找全部视图。选中层仍不存在时，
     *      安排一次重试作为兜底。替身仍留在旧 Tab 按钮中时（UIKit 会重建按钮），先把它移出，才能放进新按钮。
     */
    @objc(cyl_layOutPlusButtonInLiquidGlassLayers)
    func cylLayOutPlusButtonInLiquidGlassLayers() {
        cylLayOutPlusButtonInLiquidGlassLayers(isRetry: false)
    }

    /**
     * [EN] `isRetry`: the fallback run, which acts without waiting for readiness and schedules nothing more.
     * [CN] `isRetry`：兜底执行，不再等待就绪，也不再安排新的重试。
     */
    @objc(cyl_layOutPlusButtonInLiquidGlassLayersIsRetry:)
    func cylLayOutPlusButtonInLiquidGlassLayers(isRetry: Bool) {
        guard tabBarStyleType != .flatDesign, CYLConstants.isLiquidGlassActive(), hasPlusButton(),
              let tabBar = cyl_tabBar as? CYLTabBar else {
            return
        }
        // [EN] More editing: the views are hidden until it ends (`-[CYLTabBar endCustomizingAnimated:]`).
        // [CN] 「More」编辑期间这些视图保持隐藏，直到编辑结束。
        if tabBar.cylIsCustomizingItems() {
            return
        }
        // [EN] Re-entrancy guard: adding the stand-in can lay views out again. [CN] 防止重入：添加替身可能再次触发布局。
        if (objc_getAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.layingOut) as? NSNumber)?.boolValue == true {
            return
        }
        objc_setAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.layingOut, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        defer {
            objc_setAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.layingOut, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        guard let contextPlusButton = cylPrivate.cylContextPlusButton() else {
            return
        }
        let plusControlOrigin = tabBar.cylPlatterContentView(withIndex: contextPlusButton.cyl_tabBarItemVisibleIndex) as? UIControl
        let selectedCover = contextPlusButton.cylSelectedContentView
        // FIX: issue #216
        // [EN] On every layout pass, before the early return below: a theme changes the image of a stand-in that is already
        //      in its tab button. [CN] 每次布局都执行，且在下面的提前返回之前：主题会修改已在 Tab 按钮中的替身的图片。
        contextPlusButton.cylUpdateSelectedContentViewImage()
        contextPlusButton.cylMoveSelectedContentViewWithPlusButton()
        let plusSelectedControl = plusControlOrigin?.cylPlatterSelected()
        plusControlOrigin?.cylTabImageView()?.cylSetHidden(true)
        plusControlOrigin?.cylSwappableImageViewViewInTabBarButton()?.cylSetHidden(true)

        // [EN] The selected layer renders later than the normal one, so it may be missing now; a later layout pass or the
        //      single retry below adds what is missing.
        // [CN] 由于选中层的渲染比未选中层有延迟，可能暂时取不到；之后的布局或下面的一次重试会补上。
        let delaySecondsForSelectedContentView: TimeInterval = 0.5
        var needsRetry = plusSelectedControl == nil
        if let plusSelectedControl, hasPlusChildViewController() {
            // [EN] A stand-in left in another (old) tab button is taken out, so it can be put in this one.
            // [CN] 留在其他（旧）Tab 按钮中的替身先移出，才能放进当前按钮。
            if let selectedCover, selectedCover.superview != nil, selectedCover.cyl_insertedForTabControl !== plusSelectedControl {
                selectedCover.removeFromSuperview()
            }
            // [EN] Already in this button: nothing to do (this runs on every layout pass, so nothing is queued again).
            // [CN] 已在当前按钮中：无需处理（每次布局都会执行，因此不再重复排队）。
            if !isRetry, let selectedCover, selectedCover.superview === plusSelectedControl,
               selectedCover.cyl_insertedForTabControl === plusSelectedControl {
                return
            }
            // [EN] The stand-in is centered on the plus button (`-[CYLPlusButton cyl_placeSelectedContentView]`).
            // [CN] 替身与 PlusButton 对齐（`-[CYLPlusButton cyl_placeSelectedContentView]`）。
            let centerOnPlusButton: CYLTabButtonReplaceCompletion = { [weak contextPlusButton] _, _, _ in
                contextPlusButton?.cylPlaceSelectedContentView()
            }
            if let selectedCover {
                if contextPlusButton.cyl_showsTitleInTabBarItem() {
                    // FIX: issue #636
                    // [EN] The tab item shows the plus button's title: as the plus button does in the normal layer, its stand-in
                    //      replaces only the tab icon, and the tab's title and the rest of the tab button stay as the system lays
                    //      them out (covering the whole tab button hid the title's container too).
                    // [CN] TabBarItem 显示 PlusButton 的标题：与普通图层中的 PlusButton 一样，替身只替换 Tab 图标，Tab 的标题及按钮的其他子视图保持系统
                    //      布局（覆盖整个 Tab 按钮也会隐藏标题的容器）。
                    if isRetry || (plusSelectedControl as UIView).cyl_isReady() {
                        plusSelectedControl.cylReplaceTabImageView(withNewView: selectedCover, offset: .zero, show: true,
                                                                    completion: centerOnPlusButton)
                        plusSelectedControl.cylSwappableImageViewViewInTabBarButton()?.cylSetHidden(true)
                    } else {
                        needsRetry = true
                    }
                } else {
                    plusSelectedControl.cylCoverTabImageViewOrTabButton(true, newView: selectedCover, offset: .zero, show: true,
                                                                         delayIfNeededForSeconds: CGFloat(delaySecondsForSelectedContentView),
                                                                         completion: centerOnPlusButton)
                }
            }
        } else if let plusSelectedControl {
            // [EN] The image view is the main one; it is sometimes not there yet, then it is retried. The swappable image view
            //      is hidden defensively. [CN] imageView 是主要的；有时暂时取不到，此时重试。可替换的图片视图出于防御一并隐藏。
            let tabImageView = plusSelectedControl.cylTabImageView()
            tabImageView?.cylSetHidden(true)
            plusSelectedControl.cylSwappableImageViewViewInTabBarButton()?.cylSetHidden(true)
            needsRetry = tabImageView == nil
        }
        // [EN] Fallback: one pending retry at a time, which looks everything up again. [CN] 兜底：同一时间只安排一次重试，重试时重新查找全部视图。
        let retryPending = (objc_getAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.retryPending) as? NSNumber)?.boolValue == true
        if needsRetry && !isRetry && !retryPending {
            objc_setAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.retryPending, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySecondsForSelectedContentView) { [weak self] in
                guard let self else {
                    return
                }
                objc_setAssociatedObject(self, CYLPlusButtonGlassLayoutKeys.retryPending, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.cylLayOutPlusButtonInLiquidGlassLayers(isRetry: true)
            }
        }
    }
}
