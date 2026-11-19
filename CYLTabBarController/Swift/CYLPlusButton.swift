//
//  CYLPlusButton.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC

// MARK: - The legacy globals 旧的全局变量

/**
 [EN] The registered plus button (the one registered last, with several contexts). Swift since docs/Swift-Migration.md
      step 109; Objective-C reads it through the macro of CYLPlusButton.h (`CYLPlusButtonCurrentExternPlusButton()`).
 [CN] 已注册的 PlusButton（有多个 context 时为最后注册的）。自第 109 步起为 Swift；Objective-C 通过 CYLPlusButton.h 的宏读取。
 */
public var CYLExternPlusButton: (CYLPlusButton & CYLPlusButtonSubclassing)!

/**
 [EN] The plus button's child view controller, if any. [CN] PlusButton 的子控制器（如有）。
 */
public var CYLPlusChildViewController: UIViewController!

/**
 [EN] The plus button's width. [CN] PlusButton 的宽度。
 */
public var CYLPlusButtonWidth: CGFloat = 0

/**
 [EN] Objective-C's `CYLExternPlusButton` (a macro of CYLPlusButton.h). [CN] Objective-C 的 `CYLExternPlusButton`（CYLPlusButton.h 中的宏）。
 */
@_cdecl("CYLPlusButtonCurrentExternPlusButton")
public func CYLPlusButtonCurrentExternPlusButton() -> CYLPlusButton? {
    CYLExternPlusButton
}

/**
 [EN] Objective-C's `CYLPlusChildViewController` (a macro of CYLPlusButton.h). [CN] Objective-C 的 `CYLPlusChildViewController`（宏）。
 */
@_cdecl("CYLPlusButtonCurrentPlusChildViewController")
public func CYLPlusButtonCurrentPlusChildViewController() -> UIViewController? {
    CYLPlusChildViewController
}

/**
 [EN] Objective-C's `CYLPlusButtonWidth` (a macro of CYLTabBarController.h). [CN] Objective-C 的 `CYLPlusButtonWidth`（宏）。
 */
@_cdecl("CYLPlusButtonCurrentWidth")
public func CYLPlusButtonCurrentWidth() -> CGFloat {
    CYLPlusButtonWidth
}

/**
 [EN] A plus button a configuration's `CYLTabBarControllerPlusButton` entry chooses as its page
      (`CYLConfigurationPlusButtonPageKey`, a macro of CYLPlusButton.h with the same string).
 [CN] 配置中 `CYLTabBarControllerPlusButton` 选作页面的键（CYLPlusButton.h 中同名宏，字符串相同）。
 */
let CYLConfigurationPlusButtonPageKey = "CYLConfigurationPlusButtonPage"

/**
 [EN] `+cyl_plusButtonClassSelectedContentView` sent to the runtime class (it may be a class made at run time).
 [CN] 向运行时的类发送 `+cyl_plusButtonClassSelectedContentView`（可能是运行时创建的类）。
 */
@objc private protocol CYLPlusButtonClassSelectedContentViewSource {
    @objc(cyl_plusButtonClassSelectedContentView) func cylPlusButtonClassSelectedContentView() -> UIButton?
}

private let CYLPlusButtonSetConfigurationSelector = NSSelectorFromString("setConfiguration:")
private let CYLPlusButtonClearBadgeSelector = NSSelectorFromString("cyl_clearBadge")

/**
 [EN] `+[cls new]` through the Objective-C runtime: a class made at run time (`objc_allocateClassPair`) has no Swift metadata,
      and Swift's `init()` on its metatype would allocate the nearest Swift class instead.
 [CN] 通过 Objective-C 运行时调用 `+[cls new]`：运行时创建的类（`objc_allocateClassPair`）没有 Swift 元数据，对其元类型调用 Swift 的
      `init()` 会创建最近的 Swift 类的实例。
 */
func CYLPlusButtonNewInstance(of cls: AnyClass) -> AnyObject {
    (cls as AnyObject).perform(NSSelectorFromString("new")).takeRetainedValue()
}

// MARK: - CYLPlusButton

/**
 [EN] The plus button of the tab bar: subclass it and adopt `CYLPlusButtonSubclassing`, then call `register()` before the tab
      bar controller is created. An `open` Swift class since docs/Swift-Migration.md step 109 (phase ②, the maintainer's
      decision "Open Swift classes", 2026-11-19): subclasses are written in Swift (docs/Subclassing-In-Swift.md). The work is
      done in `CYLPlusButton+CYLImplementation.swift`; this class keeps the overrides and the public API, with the selectors and
      Swift names of the former Objective-C class.
 [CN] TabBar 的 PlusButton：继承它并遵循 `CYLPlusButtonSubclassing`，在创建 TabBarController 之前调用 `register()`。自第 109 步起为 `open` 的
      Swift 类（第 ② 阶段，维护者 2026-11-19 的决定"Open Swift classes"）：子类用 Swift 编写（docs/Subclassing-In-Swift.md）。具体实现在
      `CYLPlusButton+CYLImplementation.swift`；本类保留重写方法与公开 API，selector 与 Swift 名称与原 Objective-C 类相同。
 */
@objc(CYLPlusButton)
open class CYLPlusButton: UIButton {

    // MARK: Life cycle, accessibility 生命周期、无障碍

    public override init(frame: CGRect) {
        CYLPlusButton.cylInstallRuntimeOverrides
        super.init(frame: frame)
        cylSetUpTabLikeInteractions()
    }

    public required init?(coder: NSCoder) {
        CYLPlusButton.cylInstallRuntimeOverrides
        super.init(coder: coder)
        cylSetUpTabLikeInteractions()
    }

    /**
     [EN] `-setConfiguration:` and `-cyl_clearBadge` cannot be overridden in Swift (UIKit declares `configuration` in a Swift
          extension; `cyl_clearBadge` has two declarations above this class), so they are added to the class at run time, once,
          as the Objective-C class overrode them; `super` is UIButton's / UIControl's implementation.
     [CN] `-setConfiguration:` 与 `-cyl_clearBadge` 无法在 Swift 中重写（UIKit 在 Swift 扩展中声明 `configuration`；`cyl_clearBadge` 在本类之上有两个
          声明），因此与原 Objective-C 类的重写一样，在运行时添加到类上一次；`super` 为 UIButton / UIControl 的实现。
     */
    private static let cylInstallRuntimeOverrides: Void = {
        let setConfiguration: @convention(block) (CYLPlusButton, AnyObject?) -> Void = { button, configuration in
            button.cylPlusButtonSetConfiguration(configuration as? UIButton.Configuration)
        }
        class_addMethod(CYLPlusButton.self, CYLPlusButtonSetConfigurationSelector, imp_implementationWithBlock(setConfiguration), "v@:@")
        let clearBadge: @convention(block) (CYLPlusButton) -> Void = { button in
            button.cylPlusButtonClearBadge()
        }
        class_addMethod(CYLPlusButton.self, CYLPlusButtonClearBadgeSelector, imp_implementationWithBlock(clearBadge), "v@:")
        // [EN] The default `+selectedContentView` (a new plus button of the class), added at run time so a Swift subclass can
        //      still declare its own (`CYLPlusButtonSubclassing`) without a selector conflict. `+contentImage` /
        //      `+selectedContentImage` have no default: the Objective-C class returned nil, which is what a missing one gives.
        // [CN] 默认的 `+selectedContentView`（该类新建的 PlusButton），在运行时添加，使 Swift 子类仍能声明自己的实现（`CYLPlusButtonSubclassing`）
        //      而不产生 selector 冲突。`+contentImage` / `+selectedContentImage` 没有默认实现：原 Objective-C 类返回 nil，与未实现相同。
        let classSelectedContentView: @convention(block) (AnyObject) -> UIButton? = { cls in
            unsafeBitCast(cls, to: CYLPlusButtonClassSelectedContentViewSource.self).cylPlusButtonClassSelectedContentView()
        }
        if let metaClass = object_getClass(CYLPlusButton.self) {
            class_addMethod(metaClass, NSSelectorFromString("selectedContentView"), imp_implementationWithBlock(classSelectedContentView), "@@:")
        }
    }()

    open override var accessibilityLabel: String? {
        get { cylPlusButtonAccessibilityLabel() }
        set { cylPlusButtonSetAccessibilityLabel(newValue) }
    }

    open override var accessibilityTraits: UIAccessibilityTraits {
        get { cylPlusButtonAccessibilityTraits(super.accessibilityTraits) }
        set { super.accessibilityTraits = newValue }
    }

    open override var largeContentTitle: String? {
        get { cylPlusButtonLargeContentTitle(super.largeContentTitle) }
        set { super.largeContentTitle = newValue }
    }

    open override var largeContentImage: UIImage? {
        get { super.largeContentImage ?? currentImage }
        set { super.largeContentImage = newValue }
    }

    /**
     [EN] A plus button with an image above a title, the title colored when selected.
     [CN] 图片在上、标题在下的 PlusButton，选中时标题着色。
     */
    @objc(cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:)
    open class func cyl_plusButton(with image: UIImage, title: String, selectedTitle: String?, selectedTitleColor: UIColor?) -> Self {
        // [EN] `-init` through the runtime: a class method cannot call a non-required initializer on `self`.
        // [CN] 通过运行时调用 `-init`：类方法不能对 `self` 调用非 required 的初始化方法。
        let button = unsafeDowncast(CYLPlusButtonNewInstance(of: self), to: self)
        button.cylPlusButtonSetUp(image: image, title: title, selectedTitle: selectedTitle, selectedTitleColor: selectedTitleColor)
        return button
    }

    // MARK: Overrides 重写

    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        cylPlusButtonSetImage(image, for: state)
    }

    open override func image(for state: UIControl.State) -> UIImage? {
        cylPlusButtonKeptImage(for: state) ?? super.image(for: state)
    }

    open override func setBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        cylPlusButtonSetBackgroundImage(image, for: state)
    }

    open override func cyl_showBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        cylPlusButtonShowBadgeValue(value, animationTypeValue: animationTypeValue)
    }

    open override func cyl_badgeLayerControls() -> [UIControl] {
        cylPlusButtonBadgeLayerControls()
    }

    open override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer === self.layer {
            cylPlusButtonLayoutSublayers()
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cylPlusButtonTraitCollectionDidChange(previousTraitCollection)
    }

    open override var center: CGPoint {
        get { super.center }
        set {
            let center = cylPlusButtonCenter(forCenter: newValue)
            let moved = center != super.center
            super.center = center
            cylPlusButtonDidSetCenter(moved: moved)
        }
    }

    open override var frame: CGRect {
        get { super.frame }
        set {
            let moved = newValue != super.frame
            super.frame = newValue
            if let center = cylPlusButtonDidSetFrame(moved: moved) {
                super.center = center.cgPointValue
            }
            cylPlusButtonUpdateTouchableAreaIfShown()
        }
    }

    open override var isSelected: Bool {
        didSet { cylPlusButtonDidSetSelected() }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        cylPlusButtonLayoutSubviews()
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event) || cylPlusButtonTouchableAreaContains(point)
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        cylPlusButtonDidMoveToSuperview()
    }

    open override func removeFromSuperview() {
        cylPlusButtonWillRemoveFromSuperview()
        super.removeFromSuperview()
    }

    open override var isHidden: Bool {
        didSet { cylPlusButtonUpdateTouchableAreaIfShown() }
    }

    // MARK: For CYLPlusButton+CYLImplementation.swift (CYLPlusButtonSuperAPI, CYLPlusButtonGlobalsAPI)

    @objc(cyl_mirrorLegacyGlobalsWithPlusButton:plusChildViewController:width:)
    class func cylMirrorLegacyGlobals(plusButton: CYLPlusButton?, plusChildViewController: UIViewController?, width: CGFloat) {
        CYLExternPlusButton = plusButton as? (CYLPlusButton & CYLPlusButtonSubclassing)
        CYLPlusChildViewController = plusChildViewController
        CYLPlusButtonWidth = width
    }

    @objc(cyl_superImageForState:)
    func cylSuperImage(for state: UIControl.State) -> UIImage? { super.image(for: state) }

    @objc(cyl_superSetImage:forState:)
    func cylSuperSetImage(_ image: UIImage?, for state: UIControl.State) { super.setImage(image, for: state) }

    @objc(cyl_superBackgroundImageForState:)
    func cylSuperBackgroundImage(for state: UIControl.State) -> UIImage? { super.backgroundImage(for: state) }

    @objc(cyl_superSetBackgroundImage:forState:)
    func cylSuperSetBackgroundImage(_ image: UIImage?, for state: UIControl.State) { super.setBackgroundImage(image, for: state) }

    @objc(cyl_superSetConfiguration:)
    func cylSuperSetConfiguration(_ configuration: UIButton.Configuration?) {
        typealias Setter = @convention(c) (AnyObject, Selector, AnyObject?) -> Void
        guard let imp = class_getMethodImplementation(UIButton.self, CYLPlusButtonSetConfigurationSelector) else { return }
        unsafeBitCast(imp, to: Setter.self)(self, CYLPlusButtonSetConfigurationSelector, configuration.map { $0 as AnyObject })
    }

    @objc(cyl_superShowBadgeValue:animationTypeValue:)
    func cylSuperShowBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        super.cyl_showBadgeValue(value, animationTypeValue: animationTypeValue)
    }

    @objc(cyl_superClearBadge)
    func cylSuperClearBadge() {
        typealias Clear = @convention(c) (AnyObject, Selector) -> Void
        guard let imp = class_getMethodImplementation(UIControl.self, CYLPlusButtonClearBadgeSelector) else { return }
        unsafeBitCast(imp, to: Clear.self)(self, CYLPlusButtonClearBadgeSelector)
    }

    // MARK: Public API 公开 API

    /**
     [EN] Registers this plus button class: call it before the tab bar controller is created.
     [CN] 注册该 PlusButton 类：在创建 TabBarController 之前调用。
     */
    @objc(registerPlusButton)
    open class func register() {
        CYLPlusButton.cylInstallRuntimeOverrides
        cylPlusButtonRegister()
    }

    /**
     [EN] Lines the title up with the tab titles again, after a change of its size or image.
     [CN] 尺寸或图片改变后，重新让标题与 Tab 标题对齐。
     */
    @objc open func cyl_setNeedsTitleAlignment() { cylPlusButtonSetNeedsTitleAlignment() }

    /**
     [EN] Issue #91: how far the touchable area reaches beyond the frame (positive values grow it).
     [CN] Issue #91：点击范围超出 frame 的距离（正值向外扩展）。
     */
    @objc open var touchableAreaOutsets: UIEdgeInsets {
        get { cylPlusButtonTouchableAreaOutsets() }
        set { cylPlusButtonSetTouchableAreaOutsets(newValue) }
    }

    /**
     [EN] Whether every tap reaches `-tabBarController:didSelectControl:`. [CN] 每次点击是否都到达 `-tabBarController:didSelectControl:`。
     */
    @objc open var reportsTapsToDelegate: Bool {
        get { cylPlusButtonReportsTapsToDelegate() }
        set { cylPlusButtonSetReportsTapsToDelegate(newValue) }
    }

    /**
     [EN] Scales the touchable area around the center. [CN] 以中心按倍数放大点击范围。
     */
    @objc open var touchableAreaScale: CGFloat {
        get { cylPlusButtonTouchableAreaScale() }
        set { cylPlusButtonSetTouchableAreaScale(newValue) }
    }

    /**
     [EN] Draws the touchable area, for debugging. [CN] 绘制点击范围（调试用）。
     */
    @objc open var showsTouchableArea: Bool {
        get { cylPlusButtonShowsTouchableArea() }
        set { cylPlusButtonSetShowsTouchableArea(newValue) }
    }

    /**
     [EN] The color of the drawn touchable area. [CN] 绘制的点击范围的颜色。
     */
    @objc open var touchableAreaColor: UIColor? {
        get { cylPlusButtonTouchableAreaColor() }
        set { cylPlusButtonSetTouchableAreaColor(newValue) }
    }

    /**
     [EN] The touchable area in `view`'s coordinates. [CN] `view` 坐标系中的点击范围。
     */
    @objc(touchableRectInView:)
    open func touchableRect(in view: UIView?) -> CGRect { cylPlusButtonTouchableRect(in: view) }

    /**
     [EN] The interactive subview (a UIControl) under `point`, if any (issue #202). [CN] `point` 下的可交互子视图（UIControl），如有（issue #202）。
     */
    @objc(hitTestInteractiveSubview:withEvent:)
    open func hitTestInteractiveSubview(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        cylPlusButtonHitTestInteractiveSubview(point, with: event)
    }

    /**
     [EN] Whether the title is drawn by the plus button's tab item. [CN] 标题是否由 PlusButton 的 Tab item 绘制。
     */
    @objc open func cyl_showsTitleInTabBarItem() -> Bool { cylShowsTitleInTabBarItem() }

    /**
     [EN] Whether the center Y offset applies to a plus button without a title. [CN] 中心 Y 偏移是否用于没有标题的 PlusButton。
     */
    @objc open var cyl_appliesCenterYOffsetWithoutTitle: Bool {
        @objc(cyl_appliesCenterYOffsetWithoutTitle) get { cylPlusButtonAppliesCenterYOffsetWithoutTitle() }
        @objc(cyl_setAppliesCenterYOffsetWithoutTitle:) set { cylPlusButtonSetAppliesCenterYOffsetWithoutTitle(newValue) }
    }

    /**
     [EN] Removes the plus button. [CN] 移除 PlusButton。
     */
    @objc(removePlusButton)
    open class func remove() { cylPlusButtonRemove() }

    /**
     [EN] Removes the plus button of a context. [CN] 移除某个 context 的 PlusButton。
     */
    @objc(removePlusButtonForTabBarContext:)
    open class func remove(forTabBarContext tabBarContext: String) { cylPlusButtonRemove(forTabBarContext: tabBarContext) }

    /**
     [EN] The plus button of a context (Swift: `CYLPlusButton(forTabBarContext:)`). [CN] 某个 context 的 PlusButton（Swift：`CYLPlusButton(forTabBarContext:)`）。
     */
    @available(swift, obsoleted: 1.0, message: "Use CYLPlusButton(forTabBarContext:)")
    @objc(plusButtonForTabBarContext:)
    open class func plusButton(forTabBarContext tabBarContext: String?) -> (CYLPlusButton & CYLPlusButtonSubclassing)? {
        cylPlusButton(forTabBarContext: tabBarContext) as? (CYLPlusButton & CYLPlusButtonSubclassing)
    }

    /**
     [EN] The plus child view controller of a context. [CN] 某个 context 的 PlusButton 子控制器。
     */
    @objc(plusChildViewControllerForTabBarContext:)
    open class func plusChildViewController(forTabBarContext tabBarContext: String?) -> UIViewController? {
        cylPlusChildViewController(forTabBarContext: tabBarContext)
    }

    /**
     [EN] The plus button's width in a context. [CN] 某个 context 中 PlusButton 的宽度。
     */
    @objc(plusButtonWidthForTabBarContext:)
    open class func plusButtonWidth(forTabBarContext tabBarContext: String?) -> CGFloat {
        cylPlusButtonWidth(forTabBarContext: tabBarContext)
    }

    /**
     [EN] The context of the tab bar controller `owner` (a view or a view controller) belongs to. [CN] `owner`（视图或控制器）所属 TabBarController 的 context。
     */
    @objc(tabBarContextForOwner:)
    open class func tabBarContext(forOwner owner: Any?) -> String? { cylPlusButtonTabBarContext(forOwner: owner) }

    /**
     [EN] The plus button of `owner`'s tab bar controller (Swift: `CYLPlusButton(forOwner:)`). [CN] `owner` 所属 TabBarController 的 PlusButton（Swift：`CYLPlusButton(forOwner:)`）。
     */
    @available(swift, obsoleted: 1.0, message: "Use CYLPlusButton(forOwner:)")
    @objc(plusButtonForOwner:)
    open class func plusButton(forOwner owner: Any?) -> (CYLPlusButton & CYLPlusButtonSubclassing)? {
        cylPlusButton(forOwner: owner) as? (CYLPlusButton & CYLPlusButtonSubclassing)
    }

    /**
     [EN] The plus child view controller of `owner`'s tab bar controller. [CN] `owner` 所属 TabBarController 的 PlusButton 子控制器。
     */
    @objc(plusChildViewControllerForOwner:)
    open class func plusChildViewController(forOwner owner: Any?) -> UIViewController? { cylPlusChildViewController(forOwner: owner) }

    /**
     [EN] The plus button's width in `owner`'s tab bar controller. [CN] `owner` 所属 TabBarController 中 PlusButton 的宽度。
     */
    @objc(plusButtonWidthForOwner:)
    open class func plusButtonWidth(forOwner owner: Any?) -> CGFloat { cylPlusButtonWidth(forOwner: owner) }

    /**
     [EN] Whether `view` is a plus button or its stand-in. [CN] `view` 是否为 PlusButton 或其替身。
     */
    @objc(isPlusButtonView:)
    open class func isPlusButtonView(_ view: UIView?) -> Bool { cylPlusButtonIsPlusButtonView(view) }

    /**
     [EN] Selects the plus child view controller (the target of a plus button with a child). [CN] 选中 PlusButton 子控制器（有子控制器时 PlusButton 的 target）。
     */
    @objc(plusChildViewControllerButtonClicked:)
    open func plusChildViewControllerButtonClicked(_ sender: UIButton & CYLPlusButtonSubclassing) {
        cylPlusButtonPlusChildViewControllerButtonClicked(sender)
    }

    /**
     [EN] The context this class's plus button is matched with. [CN] 本类 PlusButton 匹配的 context。
     */
    @objc open class func matchedTabBarContext() -> String { cylPlusButtonMatchedTabBarContext() }

    /**
     [EN] Whether a plus button is registered for a context. [CN] 某个 context 是否注册了 PlusButton。
     */
    @objc(hasPlusButtonForTabBarContext:)
    open class func hasPlusButton(forTabBarContext tabBarContext: String) -> Bool {
        cylPlusButton(forTabBarContext: tabBarContext) != nil
    }

    /**
     [EN] Whether a context has a plus child view controller. [CN] 某个 context 是否有 PlusButton 子控制器。
     */
    @objc(hasPlusChildViewControllerForTabBarContext:)
    open class func hasPlusChildViewController(forTabBarContext tabBarContext: String) -> Bool {
        plusChildViewController(forTabBarContext: tabBarContext) != nil
    }

    /**
     [EN] The multiplier of the tab bar height for the center Y. [CN] 中心 Y 所用的 TabBar 高度倍数。
     */
    @objc(multiplierOfTabBarHeight:)
    open func multiplier(ofTabBarHeight tabBarHeight: CGFloat) -> CGFloat { cylPlusButtonMultiplierOfTabBarHeight(tabBarHeight) }

    /**
     [EN] The center Y offset. [CN] 中心 Y 的偏移。
     */
    @objc(constantOfPlusButtonCenterYOffsetForTabBarHeight:)
    open func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        cylConstantOfPlusButtonCenterYOffset(forTabBarHeight: tabBarHeight)
    }

    /**
     [EN] The plus button's index for a number of tabs. [CN] 给定 Tab 数量时 PlusButton 的下标。
     */
    @objc(indexForTabbarItemsCount:)
    open class func index(forTabbarItemsCount tabbarItemsCount: UInt) -> UInt { cylPlusButtonIndex(forTabbarItemsCount: tabbarItemsCount) }

    /**
     [EN] Hides the plus button's tab label. [CN] 隐藏 PlusButton 的 Tab 标签。
     */
    @objc open func setTabLabelHidden(_ hidden: Bool) { cylPlusButtonSetTabLabelHidden(hidden) }

    /**
     [EN] The plus button's title. [CN] PlusButton 的标题。
     */
    @objc open func cyl_title() -> String? { cylPlusButtonTitle() }

    /**
     [EN] Updates the title and images in place. [CN] 原地更新标题与图片。
     */
    @objc(cyl_updateTitle:image:selectedImage:)
    open func cyl_updateTitle(_ title: String?, image: UIImage?, selectedImage: UIImage?) {
        cylPlusButtonUpdate(title: title, image: image, selectedImage: selectedImage)
    }

    /**
     [EN] Deprecated. Use `register()` instead. [CN] 已废弃，请改用 `register()`。
     */
    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+[CYLPlusButton registerPlusButton]` instead.")
    @objc open class func registerSubclass() { register() }

    // MARK: Internal, reached by selector 内部，通过 selector 访问

    /** [EN] The stand-in in Liquid Glass's selected layer. [CN] 液态玻璃选中图层中的替身。 */
    @objc(selectedContentView) var cylSelectedContentView: UIButton? {
        get { cylPlusButtonSelectedContentView() }
        set { cylPlusButtonSetSelectedContentView(newValue) }
    }

    /** [EN] The stand-in's selected image. [CN] 替身选中状态的图片。 */
    @objc(selectedContentImage) var cylSelectedContentImage: UIImage? {
        get { cylPlusButtonSelectedContentImage() }
        set { cylPlusButtonSetSelectedContentImage(newValue) }
    }

    /** [EN] The stand-in's image. [CN] 替身的图片。 */
    @objc(contentImage) var cylContentImage: UIImage? {
        get { cylPlusButtonContentImage() }
        set { cylPlusButtonSetContentImage(newValue) }
    }

    @objc(addSelectViewControllerTarget:)
    class func cylAddSelectViewControllerTarget(_ plusButton: UIButton) { cylPlusButtonAddSelectViewControllerTarget(plusButton) }

}

// MARK: - The class a plus button really has 运行时的真实类

extension CYLPlusButton {

    /**
     [EN] The class as the runtime sees it: `type(of:)` and Swift metatype calls skip a class made at run time (a
          configuration's plus button, `objc_allocateClassPair`) and answer for the nearest Swift class instead (step 109).
     [CN] 运行时看到的类：`type(of:)` 与 Swift 元类型调用会跳过运行时创建的类（配置的 PlusButton，`objc_allocateClassPair`），
          改由最近的 Swift 类回答（第 109 步）。
     */
    var cylRuntimeClass: AnyClass {
        object_getClass(self) ?? type(of: self)
    }

    /**
     [EN] `+indexForTabbarItemsCount:` of the runtime class, sent through the Objective-C runtime.
     [CN] 通过 Objective-C 运行时调用运行时类的 `+indexForTabbarItemsCount:`。
     */
    func cylIndex(forTabbarItemsCount tabbarItemsCount: UInt) -> UInt {
        typealias Index = @convention(c) (AnyObject, Selector, UInt) -> UInt
        let selector = NSSelectorFromString("indexForTabbarItemsCount:")
        let cls: AnyClass = cylRuntimeClass
        guard let metaClass = object_getClass(cls), let imp = class_getMethodImplementation(metaClass, selector) else {
            return type(of: self).index(forTabbarItemsCount: tabbarItemsCount)
        }
        return unsafeBitCast(imp, to: Index.self)(cls, selector, tabbarItemsCount)
    }
}

// MARK: - Swift initializers that return the registered plus button

/**
 [EN] The factory initializers `CYLPlusButton(forTabBarContext:)` and `CYLPlusButton(forOwner:)`, which Swift code used while the
      class was Objective-C: an initializer of a protocol extension may assign `self`, so it returns the registered button.
 [CN] Swift 代码在本类为 Objective-C 时使用的工厂初始化方法 `CYLPlusButton(forTabBarContext:)` 与 `CYLPlusButton(forOwner:)`：协议扩展中的
      初始化方法可以给 `self` 赋值，因此能返回已注册的按钮。
 */
public protocol CYLPlusButtonRegisteredInstance {}

extension CYLPlusButton: CYLPlusButtonRegisteredInstance {}

extension CYLPlusButtonRegisteredInstance {

    /**
     [EN] The plus button of a context, or nil. [CN] 某个 context 的 PlusButton，或 nil。
     */
    public init?(forTabBarContext tabBarContext: String?) {
        guard let button = CYLPlusButton.cylPlusButton(forTabBarContext: tabBarContext) as? Self else { return nil }
        self = button
    }

    /**
     [EN] The plus button of `owner`'s tab bar controller, or nil. [CN] `owner` 所属 TabBarController 的 PlusButton，或 nil。
     */
    public init?(forOwner owner: Any?) {
        guard let button = CYLPlusButton.cylPlusButton(forOwner: owner) as? Self else { return nil }
        self = button
    }
}

// MARK: - Registering a plus button from attributes (CYLTabBarControllerPlusButton)

private var CYLConfigurationPlusButtonEntryKey: UInt8 = 0
private let CYLConfigurationPlusButtonAttributesKey = "attributes"
private let CYLConfigurationPlusButtonActionKey = "action"
private let CYLConfigurationPlusButtonContextKey = "context"
private let CYLConfigurationPlusButtonDefaultContext = "CYLTabBarController"
private var CYLConfigurationPlusButtonCounter = 0

extension CYLPlusButton {

    /**
     [EN] Registers a plus button made from attributes (a configuration's `CYLTabBarControllerPlusButton`): the keys of a tab
          item plus the `CYLPlusButton…` keys. Taps call `action`. Nothing happens without an image.
     [CN] 注册由属性创建的 PlusButton（配置中的 `CYLTabBarControllerPlusButton`）：Tab item 的键加上 `CYLPlusButton…` 键。点击时调用
          `action`。没有图片时不做任何事。
     */
    @objc(cyl_registerPlusButtonWithAttributes:action:context:)
    open class func cyl_register(attributes: [String: Any] = [:], action: ((CYLPlusButton) -> Void)?, context: String?) {
        let hasImage = attributes[CYLTabBarItemImage] is UIImage || attributes[CYLPlusButtonBackgroundImage] is UIImage
        guard hasImage else { return }
        CYLConfigurationPlusButtonCounter += 1
        let className = "CYLConfigurationPlusButton_\(CYLConfigurationPlusButtonCounter)"
        guard let cls = objc_allocateClassPair(CYLConfigurationPlusButton.self, className, 0) else { return }
        objc_registerClassPair(cls)
        var entry: [String: Any] = [CYLConfigurationPlusButtonAttributesKey: attributes]
        entry[CYLConfigurationPlusButtonContextKey] = (context?.isEmpty == false) ? context : CYLConfigurationPlusButtonDefaultContext
        if let action {
            entry[CYLConfigurationPlusButtonActionKey] = action
        }
        objc_setAssociatedObject(cls, &CYLConfigurationPlusButtonEntryKey, entry as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        CYLConfigurationPlusButton.cylAddClassMethods(to: cls, attributes: attributes)
        // [EN] By selector: Swift's metatype dispatch would see the nearest Swift class, not the class made at run time.
        // [CN] 通过 selector 调用：Swift 的元类型派发看到的是最近的 Swift 类，而不是运行时创建的类。
        _ = (cls as AnyObject).perform(NSSelectorFromString("registerPlusButton"))
    }
}

/**
 [EN] The plus button of a configuration: each configuration makes a subclass at run time (`objc_allocateClassPair`) that keeps
      its attributes, tap action and context, and answers the `CYLPlusButtonSubclassing` class methods from them. Swift since
      step 109 (it subclasses the Swift `CYLPlusButton`).
 [CN] 配置的 PlusButton：每份配置在运行时创建一个子类（`objc_allocateClassPair`），保存其属性、点击回调与 context，并据此回答
      `CYLPlusButtonSubclassing` 的类方法。自第 109 步起为 Swift（继承 Swift 的 `CYLPlusButton`）。
 */
@objc(CYLConfigurationPlusButton)
final class CYLConfigurationPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    private class var cylConfigurationEntry: [String: Any] {
        (objc_getAssociatedObject(self, &CYLConfigurationPlusButtonEntryKey) as? [String: Any]) ?? [:]
    }

    static func plusButton() -> Any {
        // [EN] The runtime class (`self` may be a class made at run time). [CN] 运行时的类（`self` 可能是运行时创建的类）。
        let button = unsafeDowncast(CYLPlusButtonNewInstance(of: self), to: CYLPlusButton.self)
        button.cylConfigurationPlusButtonSetUp(attributes: cylConfigurationEntry[CYLConfigurationPlusButtonAttributesKey] as? [String: Any])
        return button
    }

    @objc static func tabBarContext() -> String {
        (cylConfigurationEntry[CYLConfigurationPlusButtonContextKey] as? String) ?? CYLConfigurationPlusButtonDefaultContext
    }

    static func alignsTitleWithTabBarItemTitles() -> Bool {
        cylConfigurationPlusButtonAlignsTitle(attributes: cylConfigurationEntry[CYLConfigurationPlusButtonAttributesKey] as? [String: Any])
    }

    @objc func cyl_configurationPlusButtonTapped() {
        let action = (object_getClass(self) as? CYLConfigurationPlusButton.Type)?.cylConfigurationEntry[CYLConfigurationPlusButtonActionKey]
        (action as? (CYLPlusButton) -> Void)?(self)
    }

    /**
     [EN] The class methods a configuration gives, added to its class at run time. [CN] 配置给出的类方法，在运行时添加到其类上。
     */
    fileprivate class func cylAddClassMethods(to cls: AnyClass, attributes: [String: Any]) {
        guard let metaClass = object_getClass(cls) else { return }
        if let index = (attributes[CYLPlusButtonIndexInTabBar] as? NSNumber)?.uintValue {
            let block: @convention(block) (AnyObject) -> UInt = { _ in index }
            class_addMethod(metaClass, NSSelectorFromString("indexOfPlusButtonInTabBar"), imp_implementationWithBlock(block), "Q@:")
        }
        if let multiplier = (attributes[CYLPlusButtonCenterYMultiplier] as? NSNumber)?.doubleValue {
            let block: @convention(block) (AnyObject, CGFloat) -> CGFloat = { _, _ in CGFloat(multiplier) }
            class_addMethod(metaClass, NSSelectorFromString("multiplierOfTabBarHeight:"), imp_implementationWithBlock(block), "d@:d")
        }
        if let offset = (attributes[CYLPlusButtonCenterYOffset] as? NSNumber)?.doubleValue {
            let block: @convention(block) (AnyObject, CGFloat) -> CGFloat = { _, _ in CGFloat(offset) }
            class_addMethod(metaClass, NSSelectorFromString("constantOfPlusButtonCenterYOffsetForTabBarHeight:"),
                            imp_implementationWithBlock(block), "d@:d")
        }
        if let identifier = attributes[CYLTabBarItemIdentifier] as? String, !identifier.isEmpty {
            let block: @convention(block) (AnyObject) -> NSString = { _ in identifier as NSString }
            class_addMethod(metaClass, NSSelectorFromString("tabBarItemIdentifier"), imp_implementationWithBlock(block), "@@:")
        }
        if let page = attributes[CYLConfigurationPlusButtonPageKey] as? UIViewController {
            let block: @convention(block) (AnyObject) -> UIViewController = { _ in page }
            class_addMethod(metaClass, NSSelectorFromString("plusChildViewController"), imp_implementationWithBlock(block), "@@:")
        }
    }
}
