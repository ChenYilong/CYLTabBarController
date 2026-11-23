//
//  CYLTabBar.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

/**
 [EN] The tab bar of `CYLTabBarController`: lays out the tab buttons and the plus button, syncs the classic styles into
      `UITabBarAppearance`, follows the Liquid Glass gestures. Swift since docs/Swift-Migration.md step 100 (was the
      Objective-C shell `CYLTabBar.m`; its logic was already Swift in `CYLTabBar+CYLImplementation.swift`). Same
      Objective-C API, declared for Objective-C callers by the generated Swift interface (`CYLTabBar.h` imports it).
      Nothing subclasses it in Objective-C (checked in this repository and the three dependent ones), so no shell is kept.
 [CN] `CYLTabBarController` 的 TabBar：布局 Tab 按钮与 PlusButton，把经典样式同步到 `UITabBarAppearance`，跟随液态玻璃手势。自
      docs/Swift-Migration.md 第 100 步起为 Swift（原为 Objective-C 外壳 `CYLTabBar.m`，其逻辑已在 `CYLTabBar+CYLImplementation.swift`
      中用 Swift 实现）。Objective-C API 不变，由生成的 Swift 接口向 Objective-C 调用方声明（`CYLTabBar.h` 会导入它）。Objective-C 中没有
      子类（已检查本仓库与三个依赖仓库），因此不保留外壳。
 */
@objc(CYLTabBar)
open class CYLTabBar: UITabBar, UIGestureRecognizerDelegate {

    // MARK: - Stored properties 存储属性

    /**
     [EN] When YES (default, set by the shared init), each classic setter also writes its value into `standardAppearance`
          (and `scrollEdgeAppearance` when there is one); not with Liquid Glass. NO keeps UIKit's own behavior.
     [CN] 为 YES（默认，由共用初始化设置）时，每个经典 setter 同时写入 `standardAppearance`（存在 `scrollEdgeAppearance` 时也写入）；液态玻璃时不写。
          设为 NO 保持 UIKit 原有行为。
     */
    @objc public var syncsClassicStylesToAppearance = false

    /**
     [EN] Called after each layout pass of the tab bar. [CN] TabBar 每次布局之后调用。
     */
    // [EN] Spelled out, not `CYLTabBarDidLayoutSubViewsBlock`: the generated header may be read before that typedef; the
    //      types are the same for Objective-C callers. [CN] 写出完整类型而非 `CYLTabBarDidLayoutSubViewsBlock`：生成的头文件可能在该 typedef
    //      之前被读取；对 Objective-C 调用方而言类型相同。
    @objc public var didLayoutSubViewsBlock: (@convention(block) (CYLTabBar) -> Void)? {
        // [EN] Registered as a keyed `.end` block of CYLDeallocBlockExecutor (see `cylRegisterDidLayoutSubViewsBlock`). [CN] 登记为 CYLDeallocBlockExecutor 中带 key 的 `.end` block（见 `cylRegisterDidLayoutSubViewsBlock`）。
        didSet { cylRegisterDidLayoutSubViewsBlock() }
    }

    /**
     [EN] The plus button's state: registered and its context matches. [CN] PlusButton 的状态：已注册且 context 一致。
     */
    @objc(plusButtonActive) public var isPlusButtonActive: Bool {
        @objc(isPlusButtonActive) get { storedPlusButtonActive }
        set { storedPlusButtonActive = newValue }
    }
    private var storedPlusButtonActive = false

    /**
     [EN] Whether the Liquid Glass lens is up. [CN] 液态玻璃透镜是否抬起。
     */
    @objc public var isLensViewLifed = false

    /**
     [EN] UIKit's continuous Liquid Glass gesture recognizer of this tab bar, followed by the controller.
     [CN] 本 TabBar 上 UIKit 的液态玻璃连续手势识别器，由控制器跟随。
     */
    @objc public var liquidGlassContinuousGestureRecognizer: UIGestureRecognizer?

    /**
     [EN] UIKit's Liquid Glass long-press recognizer; its states are forwarded to
          `-[CYLTabBarController cyl_liquidGlassTabBarGestureRecognizerDidUpdate:]` (issue #152 / #535).
     [CN] UIKit 的液态玻璃长按识别器；其状态转发给 `-[CYLTabBarController cyl_liquidGlassTabBarGestureRecognizerDidUpdate:]`（issue #152 / #535）。
     */
    @objc public var liquidGlassLongGestureRecognizer: UIGestureRecognizer?

    // MARK: - Initializers 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        cylTabBarSharedInit()
        cylKeepStackedItemLayoutOnHingedDevice()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        cylTabBarSharedInit()
        cylKeepStackedItemLayoutOnHingedDevice()
    }

    deinit {
        cylTabBarDealloc()
    }

    /// [EN] iOS 27.1 hinged devices: keep the stacked item layout (regular vertical size class) under Liquid Glass. Made
    ///      through the runtime, as `UIHingeInteraction` only exists in the iOS 27.1 SDK and the library builds with older
    ///      ones too (CI uses Xcode 26); nothing happens where the class does not exist.
    /// [CN] iOS 27.1 折叠设备：液态玻璃下保持堆叠的 item 布局（常规的竖向 size class）。通过运行时创建，因为 `UIHingeInteraction` 只在
    ///      iOS 27.1 SDK 中存在，而本库也用更早的 SDK 编译（CI 使用 Xcode 26）；该类不存在时什么也不做。
    private func cylKeepStackedItemLayoutOnHingedDevice() {
        guard CYLConstants.isLiquidGlassActive(), let hingeClass = NSClassFromString("UIHingeInteraction") as? NSObject.Type else { return }
        guard #available(iOS 17.0, *) else { return }
        typealias UpdateHandler = @convention(block) (AnyObject, AnyObject) -> Void
        // [EN] `-init…` consumes its receiver and returns a retained object. [CN] `-init…` 消耗接收者，并返回已 retain 的对象。
        typealias InitWithHandler = @convention(c) (Unmanaged<AnyObject>, Selector, UpdateHandler) -> Unmanaged<AnyObject>?
        let selector = NSSelectorFromString("initWithUpdateHandler:")
        guard hingeClass.instancesRespond(to: selector), let method = class_getInstanceMethod(hingeClass, selector),
              let allocated = (hingeClass as AnyObject).perform(NSSelectorFromString("alloc"))?.takeRetainedValue() else { return }
        let handler: UpdateHandler = { [weak self] _, update in
            guard let self = self, (update as? NSObject)?.value(forKey: "hinge") != nil else { return }
            if !self.traitOverrides.contains(UITraitVerticalSizeClass.self) {
                self.traitOverrides.verticalSizeClass = .regular
            }
        }
        let initialize = unsafeBitCast(method_getImplementation(method), to: InitWithHandler.self)
        if let interaction = initialize(Unmanaged.passRetained(allocated), selector, handler)?.takeRetainedValue() as? UIInteraction {
            addInteraction(interaction)
        }
    }

    open override class func automaticallyNotifiesObservers(forKey _: String) -> Bool {
        false
    }

    // MARK: - Overrides 重写

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        cylTabBarSizeThatFits(super.sizeThatFits(size))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        cylTabBarLayoutSubviews()
    }

    open override var tintColor: UIColor! {
        get { super.tintColor }
        set {
            super.tintColor = newValue
            cylTabBarSyncTintColor(newValue)
        }
    }

    open override var unselectedItemTintColor: UIColor? {
        get { super.unselectedItemTintColor }
        set {
            let previous = super.unselectedItemTintColor
            super.unselectedItemTintColor = newValue
            cylTabBarSyncUnselectedItemTintColor(newValue, previous: previous)
        }
    }

    open override var barTintColor: UIColor? {
        get { super.barTintColor }
        set {
            let previous = super.barTintColor
            super.barTintColor = newValue
            cylTabBarSyncBarTintColor(newValue, previous: previous)
        }
    }

    open override var backgroundImage: UIImage? {
        get { super.backgroundImage }
        set {
            let previous = super.backgroundImage
            super.backgroundImage = newValue
            cylTabBarSyncBackgroundImage(newValue, previous: previous)
        }
    }

    open override var shadowImage: UIImage? {
        get { super.shadowImage }
        set {
            let previous = super.shadowImage
            super.shadowImage = newValue
            cylTabBarSyncShadowImage(newValue, previous: previous)
        }
    }

    open override var barStyle: UIBarStyle {
        get { super.barStyle }
        set {
            let previous = super.barStyle
            super.barStyle = newValue
            cylTabBarSyncBarStyle(newValue, previous: previous)
        }
    }

    open override func beginCustomizingItems(_ items: [UITabBarItem]) {
        cylTabBarWillBeginCustomizing()
        super.beginCustomizingItems(items)
        cylTabBarDidBeginCustomizing()
    }

    open override func endCustomizing(animated: Bool) -> Bool {
        let changed = super.endCustomizing(animated: animated)
        cylTabBarDidEndCustomizing()
        return changed
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        cylTabBarHitTest(point, with: event) { superPoint in
            super.hitTest(superPoint, with: event)
        }
    }

    open override func addSubview(_ view: UIView) {
        cylTabBarWillAddSubview(view)
        super.addSubview(view)
    }

    open override func addInteraction(_ interaction: UIInteraction) {
        if !cylTabBarAddScrollEdgeElementContainerInteraction(interaction) {
            super.addInteraction(interaction)
        }
    }

    open override func removeInteraction(_ interaction: UIInteraction) {
        if !cylTabBarRemoveScrollEdgeElementContainerInteraction(interaction) {
            super.removeInteraction(interaction)
        }
    }

    open override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        cylTabBarWillAddGestureRecognizer(gestureRecognizer)
        super.addGestureRecognizer(gestureRecognizer)
    }

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        cylTabBarGestureRecognizerShouldBegin(gestureRecognizer)
    }

    // MARK: - Public API 公开 API

    /**
     [EN] The tab bar's context; it must match `+[CYLPlusButton tabBarContext]` when set (default `CYLTabBarController`).
     [CN] TabBar 的 context；设置后须与 `+[CYLPlusButton tabBarContext]` 一致（默认 `CYLTabBarController`）。
     */
    @objc public var context: String? {
        get { cylTabBarContext() }
        set { cylTabBarSetContext(newValue) }
    }

    /**
     [EN] The tab buttons, in order. [CN] 按顺序排列的 Tab 按钮。
     */
    @objc public var tabBarButtonArray: [UIControl] {
        get { cylTabBarTabBarButtonArray() }
        set { cylTabBarSetTabBarButtonArray(newValue) }
    }

    /**
     [EN] The width of one tab item. [CN] 单个 Tab item 的宽度。
     */
    @objc public var tabBarItemWidth: CGFloat {
        get { cylTabBarTabBarItemWidth() }
        set { cylTabBarSetTabBarItemWidth(newValue) }
    }

    /**
     [EN] The default offset that centers the tab image vertically (used for top and bottom image insets).
     [CN] 让 Tab 图片垂直居中所需的默认偏移量（同时用于图片内边距的 top 与 bottom）。
     */
    @objc public var tabImageViewDefaultOffset: CGFloat {
        cylTabBarTabImageViewDefaultOffset()
    }

    /**
     [EN] Space kept free at the two ends of the classic tab bar (`left` / `right`; docs/Tab-Item-Positioning.md).
     [CN] 经典 TabBar 两端留出的空白（`left` / `right`；docs/Tab-Item-Positioning.md）。
     */
    @objc(cyl_itemEdgeInsets) public var cylItemEdgeInsets: UIEdgeInsets {
        @objc(cyl_itemEdgeInsets) get { cylTabBarItemEdgeInsets() }
        @objc(setCyl_itemEdgeInsets:) set { cylTabBarSetItemEdgeInsets(newValue) }
    }

    /**
     [EN] The plus button of this tab bar. [CN] 本 TabBar 的 PlusButton。
     */
    @objc public var plusButton: CYLPlusButton? {
        get { cylTabBarPlusButton() }
        set { cylTabBarSetPlusButton(newValue) }
    }

    /**
     [EN] The plus button's index in the tab bar; it also repositions the plus button. [CN] PlusButton 在 TabBar 中的索引；同时会重新放置 PlusButton。
     */
    @objc public func plusButtonIndex() -> UInt {
        cylTabBarPlusButtonIndex()
    }

    /**
     [EN] Lays the tab buttons out again on the next run loop and 0.5 s later (merged). [CN] 在下一个 run loop 与 0.5 秒后重新布局 Tab 按钮（会合并）。
     */
    @objc(cyl_reloadTabButtons) public func reloadTabButtons() {
        cylTabBarReloadTabButtons()
    }

    /**
     [EN] Whether the registered plus button's context matches this tab bar's. [CN] 已注册 PlusButton 的 context 是否与本 TabBar 一致。
     */
    @objc public func hasPlusButton() -> Bool {
        cylTabBarHasPlusButton()
    }

    /**
     [EN] Whether the plus child view controller exists and matches this tab bar's context. [CN] PlusButton 子控制器是否存在且 context 一致。
     */
    @objc public func hasPlusChildViewController() -> Bool {
        cylTabBarHasPlusChildViewController()
    }

    /**
     [EN] Whether the plus button is vertically centered in the tab bar. [CN] PlusButton 是否在 TabBar 中垂直居中。
     */
    @objc public func isPlusButtonLayoutCentered() -> Bool {
        cylTabBarIsPlusButtonLayoutCentered()
    }

    /**
     [EN] The owning `CYLTabBarController` (the delegate if it is one, else `cyl_tabBarController`).
     [CN] 所属的 `CYLTabBarController`（优先取 delegate，否则取 `cyl_tabBarController`）。
     */
    @objc public func tabBarController() -> CYLTabBarController? {
        cylTabBarOwningTabBarController()
    }
}
