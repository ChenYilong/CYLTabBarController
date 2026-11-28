//
//  CYLFlatDesignTabBar.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

/**
 [EN] The FlatDesign tab bar: a plain view with one `CYLFlatDesignTabBarButton` per item, laid out by the Swift implementation
      (`CYLFlatDesignTabBar+CYLImplementation.swift`). Swift since docs/Swift-Migration.md step 101 (was the Objective-C shell
      `CYLFlatDesignTabBar.m`, which now only defines the C constant `CYLFlatDesignTabBarItemDidChange`). Same Objective-C API,
      declared for Objective-C callers by the generated Swift interface (`CYLFlatDesignTabBar.h` imports it); the
      `CYLFlatDesignTabBarDelegate` protocol stays in that header. Nothing subclasses it in Objective-C (this repository and
      the three dependent ones checked), so no shell is kept.
 [CN] 扁平样式 TabBar：一个普通视图，每个 item 对应一个 `CYLFlatDesignTabBarButton`，由 Swift 实现布局（`CYLFlatDesignTabBar+CYLImplementation.swift`）。
      自 docs/Swift-Migration.md 第 101 步起为 Swift（原为 Objective-C 外壳 `CYLFlatDesignTabBar.m`，该文件现在只定义 C 常量
      `CYLFlatDesignTabBarItemDidChange`）。Objective-C API 不变，由生成的 Swift 接口向 Objective-C 调用方声明（`CYLFlatDesignTabBar.h` 会导入它）；
      `CYLFlatDesignTabBarDelegate` 协议仍在该头文件中。Objective-C 中没有子类（已检查本仓库与三个依赖仓库），因此不保留外壳。
 */
@objc(CYLFlatDesignTabBar)
open class CYLFlatDesignTabBar: UIView {

    // MARK: - Initializers 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        cylFlatDesignCommonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        cylFlatDesignCommonInit()
    }

    // MARK: - Overrides 重写

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        cylFlatDesignSizeThatFits(super.sizeThatFits(size))
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        cylFlatDesignLayoutSubviews()
    }

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.layoutDirection != traitCollection.layoutDirection {
            setNeedsLayout()
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        cylFlatDesignHitTest(point, with: event)
    }

    // MARK: - Public API 公开 API

    /**
     [EN] Adds an item (title, images, index, title offset, image insets, optional Lottie file and size) and returns it.
     [CN] 添加一个 item（标题、图片、索引、标题偏移、图片内边距、可选的 Lottie 文件与尺寸）并返回它。
     */
    @objc(addItemWithTitle:tabBarItemImage:tabBarItemSelectedImage:index:titlePositionAdjustment:imageInsets:lottieFilePath:lottieSizeValue:)
    public func addItem(title: String?, tabBarItemImage: Any?, tabBarItemSelectedImage: Any?, index: Int,
                        titlePositionAdjustment: UIOffset, imageInsets: UIEdgeInsets,
                        lottieFilePath: String?, lottieSizeValue: NSValue?) -> CYLFlatDesignTabBarItem {
        cylFlatDesignAddItem(title: title, image: tabBarItemImage, selectedImage: tabBarItemSelectedImage, index: index,
                             titlePositionAdjustment: titlePositionAdjustment, imageInsets: imageInsets,
                             lottieFilePath: lottieFilePath, lottieSizeValue: lottieSizeValue)
    }

    /** [EN] The buttons, one per item. [CN] 按钮，每个 item 一个。 */
    @objc public var tabBarButtons: [CYLFlatDesignTabBarButton] { cylFlatDesignTabBarButtons() }

    /** [EN] The delegate told about selections. [CN] 接收选中通知的代理。 */
    @objc public var delegate: CYLFlatDesignTabBarDelegate? {
        get { cylFlatDesignDelegate() }
        set { cylFlatDesignSetDelegate(newValue) }
    }

    /** [EN] The items. [CN] 各 item。 */
    @objc public var items: [CYLFlatDesignTabBarItem]? {
        get { cylFlatDesignItems() }
        set { cylFlatDesignSetItems(newValue) }
    }

    /**
     [EN] Legacy: the buttons when read, the items when set (as the Objective-C class did). [CN] 旧接口：读取时为按钮，设置时为 item（与原 Objective-C 类相同）。
     */
    @objc public var tabBarItems: [Any]? {
        get { cylFlatDesignTabBarButtons() }
        set { cylFlatDesignSetItems(newValue?.compactMap { $0 as? CYLFlatDesignTabBarItem }) }
    }

    /** [EN] The selected item. [CN] 选中的 item。 */
    @objc public var selectedItem: CYLFlatDesignTabBarItem? {
        get { cylFlatDesignSelectedItem() }
        set { cylFlatDesignSetSelectedItem(newValue) }
    }

    /** [EN] The selected index. [CN] 选中的下标。 */
    @objc public var selectedIndex: UInt {
        get { cylFlatDesignSelectedIndex() }
        set { cylFlatDesignSetSelectedIndex(newValue) }
    }

    /** [EN] The bar's appearance (UIKit's `UITabBarAppearance`). [CN] TabBar 的外观（UIKit 的 `UITabBarAppearance`）。 */
    @objc public var standardAppearance: UITabBarAppearance? {
        get { cylFlatDesignStandardAppearance() }
        set { cylFlatDesignSetStandardAppearance(newValue) }
    }

    /** [EN] The selected tint. [CN] 选中的着色。 */
    open override var tintColor: UIColor! {
        get { cylFlatDesignTintColor() }
        set { cylFlatDesignSetTintColor(newValue) }
    }

    /** [EN] The bar's background color. [CN] TabBar 的背景色。 */
    @objc public dynamic var barTintColor: UIColor? {
        get { cylFlatDesignBarTintColor() }
        set { cylFlatDesignSetBarTintColor(newValue) }
    }

    /** [EN] The bar's background image. [CN] TabBar 的背景图。 */
    @objc public dynamic var backgroundImage: UIImage? {
        get { cylFlatDesignBackgroundImage() }
        set { cylFlatDesignSetBackgroundImage(newValue) }
    }

    /** [EN] The shadow line above the bar. [CN] TabBar 上方的阴影线。 */
    @objc public dynamic var shadowImage: UIImage? {
        get { cylFlatDesignShadowImage() }
        set { cylFlatDesignSetShadowImage(newValue) }
    }

    /** [EN] Whether the buttons avoid the left and right safe areas (YES). [CN] 按钮是否避开左右安全区（YES）。 */
    @objc public dynamic var useLayoutSafeAreaInsets: Bool {
        get { cylFlatDesignUseLayoutSafeAreaInsets() }
        set { cylFlatDesignSetUseLayoutSafeAreaInsets(newValue) }
    }

    /** [EN] Whether the iPhone Duo vertical status bar's safe area is respected. [CN] 是否避开 iPhone Duo 竖向状态栏的安全区。 */
    @objc public dynamic var respectsVerticalStatusBarSafeArea: Bool {
        get { cylFlatDesignRespectsVerticalStatusBarSafeArea() }
        set { cylFlatDesignSetRespectsVerticalStatusBarSafeArea(newValue) }
    }

    /** [EN] The tab bar's context (matches `+[CYLPlusButton tabBarContext]`). [CN] TabBar 的 context（与 `+[CYLPlusButton tabBarContext]` 一致）。 */
    @objc public var context: String? {
        get { cylFlatDesignContext() }
        set { cylFlatDesignSetContext(newValue) }
    }

    /** [EN] Whether a plus button with this context is registered. [CN] 是否注册了 context 一致的 PlusButton。 */
    @objc public func hasPlusButton() -> Bool { cylFlatDesignHasPlusButton() }

    /** [EN] Whether the plus child view controller exists for this context. [CN] 该 context 的 PlusButton 子控制器是否存在。 */
    @objc public func hasPlusChildViewController() -> Bool { cylFlatDesignHasPlusChildViewController() }
}
