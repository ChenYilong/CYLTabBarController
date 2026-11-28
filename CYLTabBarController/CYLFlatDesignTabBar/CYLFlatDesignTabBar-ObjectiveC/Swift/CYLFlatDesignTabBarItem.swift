//
//  CYLFlatDesignTabBarItem.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 [EN] Posted with the item as its object whenever a shown value of a `CYLFlatDesignTabBarItem` changes. Swift since
      docs/Swift-Migration.md step 118 (it was the only content of CYLFlatDesignTabBar.m); Objective-C reads the same string
      through the macro of CYLFlatDesignTabBarItem.h.
 [CN] `CYLFlatDesignTabBarItem` 显示的值每次变化时发送，object 为该 item。自第 118 步起为 Swift（原为 CYLFlatDesignTabBar.m 的唯一内容）；
      Objective-C 通过 CYLFlatDesignTabBarItem.h 中的宏读取同一字符串。
 */
public let cylFlatDesignTabBarItemDidChange = "CYLFlatDesignTabBarItemDidChange"

// [EN] The item of a FlatDesign tab, translated from Objective-C together with its button (docs/Swift-Migration.md,
//      step 49): each interface names the other. Objective-C names, selectors and Swift names are kept;
//      `CYLFlatDesignTabBarItemDidChange` stays a C constant (defined in CYLFlatDesignTabBar.m).
// [CN] 扁平样式 Tab 的 item，与其按钮一起从 Objective-C 翻译（docs/Swift-Migration.md，第 49 步）：两者的接口互相引用。保留 Objective-C
//      名称、selector 与 Swift 名称；`CYLFlatDesignTabBarItemDidChange` 仍是 C 常量（定义在 CYLFlatDesignTabBar.m 中）。

/**
 * [EN] The model of one FlatDesign tab, like `UITabBarItem`. Each change of a shown value posts
 *      `CYLFlatDesignTabBarItemDidChange`, and its button draws itself again.
 * [CN] 一个扁平样式 Tab 的模型，与 `UITabBarItem` 相同。显示的值每次变化都会发送 `CYLFlatDesignTabBarItemDidChange`，其按钮随之重新绘制。
 */
@objc(CYLFlatDesignTabBarItem)
open class CYLFlatDesignTabBarItem: NSObject {

    private let titleTextAttributesByState = NSMutableDictionary()
    private let badgeTextAttributesByState = NSMutableDictionary()

    /**
     * [EN] The button that shows this item; set by the button.
     * [CN] 显示本 item 的按钮；由按钮设置。
     */
    @objc open var tabBarButton: CYLFlatDesignTabBarButton? {
        didSet { linkSystemTabBarItem() }
    }

    /// [EN] Makes this item's button the system item's button (`UITabBarItem.cyl_replacementTabButton`), so a badge set on the
    ///      page's `tabBarItem` reaches the visible FlatDesign button instead of UIKit's hidden one. Runs when the button or
    ///      the page is set, whichever comes last.
    /// [CN] 把本 item 的按钮设为系统 item 的按钮（`UITabBarItem.cyl_replacementTabButton`），使设置在页面 `tabBarItem` 上的角标到达可见的扁平样式
    ///      按钮，而不是 UIKit 隐藏的按钮。在设置按钮或页面时运行，以后设置的一方为准。
    private func linkSystemTabBarItem() {
        guard let button = tabBarButton, let page = childViewController else { return }
        page.tabBarItem?.cyl_replacementTabButton = button
        if let navigation = page as? UINavigationController, let root = navigation.viewControllers.first {
            root.tabBarItem?.cyl_replacementTabButton = button
        }
    }

    // MARK: - [EN] Properties of the system UITabBarItem [CN] 系统 UITabBarItem 有的属性

    private var enabledStorage = true

    /**
     * [EN] Default is YES.
     * [CN] 默认为 YES。
     */
    @objc(enabled) open var isEnabled: Bool {
        @objc(isEnabled) get { enabledStorage }
        @objc(setEnabled:) set {
            guard enabledStorage != newValue else { return }
            enabledStorage = newValue
            postDidChange()
        }
    }

    /**
     * [EN] The index of the tab.
     * [CN] Tab 的索引。
     */
    @objc open var index: UInt = 0

    /**
     * [EN] The title.
     * [CN] 标题。
     */
    @objc open var title: String? {
        didSet { postDidChangeIfStringChanged(oldValue, title) }
    }

    /**
     * [EN] The image.
     * [CN] 图片。
     */
    @objc open var image: UIImage? {
        didSet { if oldValue !== image { postDidChange() } }
    }

    /**
     * [EN] The image while selected.
     * [CN] 选中时的图片。
     */
    @objc open var selectedImage: UIImage? {
        didSet { if oldValue !== selectedImage { postDidChange() } }
    }

    /**
     * [CN] ⚠️ PATCH(aifirx): 原本是 strong，与 UIViewController.cyl_tabBarItem 的关联对象（RETAIN）构成
     *      <ViewController> → <CYLFlatDesignTabBarItem> → <childViewController> 的自我强引用闭环，
     *      导致 tab 子控制器在 pop 之后永远无法释放。改为 weak。
     * [EN] ⚠️ PATCH(aifirx): This used to be strong, which together with the associated object (RETAIN) of
     *      UIViewController.cyl_tabBarItem formed the retain cycle
     *      <ViewController> → <CYLFlatDesignTabBarItem> → <childViewController>,
     *      so tab child controllers were never released after being popped. Changed to weak.
     */
    @objc open weak var childViewController: UIViewController? {
        didSet {
            childViewController?.cylflatdesign_tabBarController = cylflatdesign_tabBarController
            linkSystemTabBarItem()
        }
    }

    /**
     * [CN] default is nil, badgeValue为nil并且badgeSize为CGSizeZero时，badge隐藏
     * [EN] default is nil; the badge is hidden when badgeValue is nil and badgeSize is CGSizeZero
     */
    @objc open var badgeValue: String? {
        didSet { postDidChangeIfStringChanged(oldValue, badgeValue) }
    }

    /**
     * [EN] The badge color; default system red.
     * [CN] 角标颜色；默认为系统红色。
     */
    @objc open var badgeColor: UIColor? = .systemRed {
        didSet { if oldValue !== badgeColor { postDidChange() } }
    }

    /**
     * [EN] The title offset.
     * [CN] 标题偏移。
     */
    @objc open var titlePositionAdjustment: UIOffset = .zero {
        didSet { if oldValue != titlePositionAdjustment { postDidChange() } }
    }

    /**
     * [EN] Like `-[UITabBarItem standardAppearance]`: while this item is selected, the whole flat design tab bar uses this
     *      appearance instead of `-[CYLFlatDesignTabBar standardAppearance]`. `CYLTabBarController` assigns the child view
     *      controller's `tabBarItem.standardAppearance` here when the app has set one. See
     *      `-[CYLFlatDesignTabBar standardAppearance]` for what is mapped.
     * [CN] 与 `-[UITabBarItem standardAppearance]` 相同：该 item 选中期间，整个扁平样式 TabBar 使用此 appearance，而不是
     *      `-[CYLFlatDesignTabBar standardAppearance]`。App 设置了子控制器的 `tabBarItem.standardAppearance` 时，`CYLTabBarController`
     *      会将其赋给这里。映射关系见 `-[CYLFlatDesignTabBar standardAppearance]`。
     */
    @objc open var standardAppearance: UITabBarAppearance? {
        get { standardAppearanceStorage }
        set {
            guard standardAppearanceStorage !== newValue else { return }
            standardAppearanceStorage = newValue?.copy() as? UITabBarAppearance
            postDidChange()
        }
    }
    private var standardAppearanceStorage: UITabBarAppearance?

    /**
     * [EN] Sets the title text attributes for `state` (like UITabBarItem).
     * [CN] 设置指定状态下的标题文字属性（同 UITabBarItem）。
     */
    @objc(setTitleTextAttributes:forState:)
    open func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
        setAttributes(attributes, for: state, in: titleTextAttributesByState)
    }

    /**
     * [EN] Returns the title text attributes for `state`.
     * [CN] 返回指定状态下的标题文字属性。
     */
    @objc(titleTextAttributesForState:)
    open func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
        titleTextAttributesByState[NSNumber(value: state.rawValue)] as? [NSAttributedString.Key: Any]
    }

    /**
     * [EN] Sets the badge text attributes for `state`.
     * [CN] 设置指定状态下的角标文字属性。
     */
    @objc(setBadgeTextAttributes:forState:)
    open func setBadgeTextAttributes(_ textAttributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
        setAttributes(textAttributes, for: state, in: badgeTextAttributesByState)
    }

    /**
     * [EN] Returns the badge text attributes for `state`.
     * [CN] 返回指定状态下的角标文字属性。
     */
    @objc(badgeTextAttributesForState:)
    open func badgeTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
        badgeTextAttributesByState[NSNumber(value: state.rawValue)] as? [NSAttributedString.Key: Any]
    }

    // MARK: - [EN] Properties added by CYLFlatDesignTabBarItem [CN] CYLFlatDesignTabBarItem 新增属性

    /**
     * [CN] 若设置badgeSize为CGSizeZero，则badge自动计算大小，默认为CGSizeZero
     * [EN] If badgeSize is CGSizeZero, the badge size is calculated automatically. Defaults to CGSizeZero
     */
    @objc open var badgeSize: CGSize = .zero {
        didSet { if oldValue != badgeSize { postDidChange() } }
    }

    /**
     * [EN] Default {1, 6, 1, 6}.
     * [CN] 默认为 {1, 6, 1, 6}。
     */
    @objc open var badgeContentInset = UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6) {
        didSet { if oldValue != badgeContentInset { postDidChange() } }
    }

    /**
     * [EN] The badge offset.
     * [CN] 角标偏移。
     */
    @objc open var badgePositionAdjustment: UIOffset = .zero {
        didSet { if oldValue != badgePositionAdjustment { postDidChange() } }
    }

    /**
     * [EN] The image offset.
     * [CN] 图片偏移。
     */
    @objc open var imagePositionAdjustment: UIOffset = .zero {
        didSet { if oldValue != imagePositionAdjustment { postDidChange() } }
    }

    /**
     * [CN] 没有image时，title是否居中显示，或没有title时，image是否居中显示，默认为NO
     * [EN] Whether the title is centered when there is no image, or the image is centered when there is no title. Defaults
     *      to NO
     */
    @objc open var layoutCentered = false {
        didSet { if oldValue != layoutCentered { postDidChange() } }
    }

    /**
     * [EN] The background color of the tab.
     * [CN] Tab 的背景色。
     */
    @objc open var backgroundColor: UIColor? {
        didSet { if oldValue !== backgroundColor { postDidChange() } }
    }

    /**
     * [EN] The background color of the tab while selected.
     * [CN] 选中时 Tab 的背景色。
     */
    @objc open var selectedBackgroundColor: UIColor? {
        didSet { if oldValue !== selectedBackgroundColor { postDidChange() } }
    }

    /**
     * [EN] Insets of the image: they shrink its size, its origin stays.
     * [CN] 图片的内边距：缩小图片尺寸，原点不变。
     */
    @objc open var imageInsets: UIEdgeInsets = .zero {
        didSet { if oldValue != imageInsets { postDidChange() } }
    }

    /**
     * [EN] The animation file of the tab (any animation library), used before `lottieFilePath`.
     * [CN] Tab 的动画文件（任意动画库），优先于 `lottieFilePath`。
     */
    @objc open var lottieURL: URL?

    /**
     * [EN] The path of the animation file of the tab.
     * [CN] Tab 动画文件的路径。
     */
    @objc open var lottieFilePath: String?

    /**
     * [EN] The size of the animation (an `NSValue` of a `CGSize`).
     * [CN] 动画尺寸（`CGSize` 的 `NSValue`）。
     */
    @objc open var lottieSizeValue: NSValue?

    // MARK: - [EN] Initializers [CN] 初始化方法

    /**
     * [EN] Designated initializer: title, images, index, title/image offsets, image insets and optional Lottie file path and size.
     * [CN] 指定初始化方法：设置标题、图片、索引、标题/图片偏移、图片内边距，以及可选的 Lottie 文件路径与尺寸。
     */
    @objc(initWithTitle:image:selectedImage:index:titlePositionAdjustment:imagePositionAdjustment:imageInsets:lottieFilePath:lottieSizeValue:)
    public init(title: String?, image: Any?, selectedImage: Any?, index: Int,
                titlePositionAdjustment: UIOffset, imagePositionAdjustment: UIOffset, imageInsets: UIEdgeInsets,
                lottieFilePath: String?, lottieSizeValue: NSValue?) {
        self.title = title
        self.image = image as? UIImage
        self.selectedImage = selectedImage as? UIImage
        self.index = UInt(bitPattern: index)
        self.titlePositionAdjustment = titlePositionAdjustment
        self.imagePositionAdjustment = imagePositionAdjustment
        self.imageInsets = imageInsets
        self.lottieFilePath = lottieFilePath
        self.lottieSizeValue = lottieSizeValue
        super.init()
    }

    /**
     * [EN] Creates a flat-design tab bar item with a title, image and selected image.
     * [CN] 使用标题、图片与选中态图片创建扁平化 TabBarItem。
     */
    @objc(initWithTitle:image:selectedImage:)
    public convenience init(title: String?, image: UIImage?, selectedImage: UIImage?) {
        self.init(title: title, image: image, selectedImage: selectedImage, index: 0, titlePositionAdjustment: .zero,
                  imagePositionAdjustment: .zero, imageInsets: .zero, lottieFilePath: nil, lottieSizeValue: nil)
    }

    /**
     * [EN] Creates a flat-design tab bar item with a title and image.
     * [CN] 使用标题与图片创建扁平化 TabBarItem。
     */
    @objc(initWithTitle:image:)
    public convenience init(title: String?, image: UIImage?) {
        self.init(title: title, image: image, selectedImage: nil)
    }

    public override convenience init() {
        self.init(title: nil, image: nil)
    }

    /**
     * [EN] Returns the view that hosts this item's badge (from its tab bar button).
     * [CN] 返回承载该 Item 角标的视图（取自其 TabBar 按钮）。
     */
    @objc open func actualBadgeSuperView() -> UIView! {
        tabBarButton?.actualBadgeSuperView()
    }

    // MARK: - [EN] Equality [CN] 相等性

    open override func isEqual(_ object: Any?) -> Bool {
        if self === object as AnyObject? { return true }
        guard let other = object as? CYLFlatDesignTabBarItem else { return false }
        return isEnabled == other.isEnabled &&
            title == other.title &&
            image === other.image &&
            selectedImage === other.selectedImage &&
            badgeColor === other.badgeColor &&
            badgeValue == other.badgeValue &&
            badgeSize == other.badgeSize &&
            badgePositionAdjustment == other.badgePositionAdjustment &&
            badgeContentInset == other.badgeContentInset &&
            titlePositionAdjustment == other.titlePositionAdjustment &&
            imagePositionAdjustment == other.imagePositionAdjustment &&
            imageInsets == other.imageInsets &&
            titleTextAttributesByState.isEqual(other.titleTextAttributesByState) &&
            badgeTextAttributesByState.isEqual(other.badgeTextAttributesByState) &&
            layoutCentered == other.layoutCentered &&
            backgroundColor === other.backgroundColor &&
            selectedBackgroundColor === other.selectedBackgroundColor
    }

    // MARK: - [EN] Change notification [CN] 变化通知

    private func postDidChange() {
        NotificationCenter.default.post(name: NSNotification.Name(cylFlatDesignTabBarItemDidChange), object: self)
    }

    /// [EN] As before: a change from nil always posts. [CN] 与以前相同：从 nil 变化时总会发送。
    private func postDidChangeIfStringChanged(_ oldValue: String?, _ newValue: String?) {
        if oldValue == nil || oldValue != newValue {
            postDidChange()
        }
    }

    private func setAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State,
                               in storage: NSMutableDictionary) {
        let key = NSNumber(value: state.rawValue)
        let current = storage[key] as? NSDictionary
        // [EN] As before: no stored attributes always posts. [CN] 与以前相同：没有已存属性时总会发送。
        if let current, let attributes, current.isEqual(to: attributes) {
            return
        }
        storage[key] = attributes as NSDictionary?
        postDidChange()
    }
}
