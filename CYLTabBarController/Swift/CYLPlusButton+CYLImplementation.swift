//
//  CYLPlusButton+CYLImplementation.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The implementation of `CYLPlusButton`, translated from Objective-C (docs/Swift-Migration.md, step 52), like `CYLTabBar`
//      in step 51. The class stays declared in Objective-C: apps subclass it in Objective-C, and `CYLTabBarController.h`
//      names it. CYLPlusButton.m keeps the C globals of CYLTabBarController.h, the overrides and the public methods, each a
//      one-line forward to a `cyl_plusButton…` method below (declared there), and the calls to `super` that these methods
//      need (`-cyl_super…`, reached through `CYLPlusButtonSuperAPI`).
// [CN] `CYLPlusButton` 的实现，已从 Objective-C 翻译（docs/Swift-Migration.md，第 52 步），与第 51 步的 `CYLTabBar` 相同。类仍在 Objective-C 中
//      声明：App 在 Objective-C 中继承它，`CYLTabBarController.h` 也引用了它。CYLPlusButton.m 保留 CYLTabBarController.h 中的 C 全局变量、重写方法与
//      公开方法（均为一行转发到下面的 `cyl_plusButton…` 方法，在该文件中声明），以及这些方法需要的 `super` 调用（`-cyl_super…`，通过
//      `CYLPlusButtonSuperAPI` 调用）。

/**
 * [EN] The calls to `super` (UIButton, and the badge category of UIControl) that CYLPlusButton.m makes for this file.
 * [CN] CYLPlusButton.m 为本文件执行的 `super` 调用（UIButton，以及 UIControl 的角标分类）。
 */
@objc private protocol CYLPlusButtonSuperAPI {
    @objc(cyl_superImageForState:) func superImage(for state: UIControl.State) -> UIImage?
    @objc(cyl_superSetImage:forState:) func superSetImage(_ image: UIImage?, for state: UIControl.State)
    @objc(cyl_superBackgroundImageForState:) func superBackgroundImage(for state: UIControl.State) -> UIImage?
    @objc(cyl_superSetBackgroundImage:forState:) func superSetBackgroundImage(_ image: UIImage?, for state: UIControl.State)
    @objc(cyl_superSetConfiguration:) func superSetConfiguration(_ configuration: UIButton.Configuration?)
    @objc(cyl_superShowBadgeValue:animationTypeValue:) func superShowBadgeValue(_ value: String, animationTypeValue: NSNumber)
    @objc(cyl_superClearBadge) func superClearBadge()
}

/**
 * [EN] The class methods of `CYLPlusButtonSubclassing` (all optional here: the library asks whether the class has them), and the
 *      deprecated `+multiplerInCenterY`. A class method is an instance method of the class object.
 * [CN] `CYLPlusButtonSubclassing` 的类方法（这里全部为可选：库会先询问类是否实现），以及已废弃的 `+multiplerInCenterY`。类方法是类对象的实例方法。
 */
@objc private protocol CYLPlusButtonClassAPI {
    @objc(plusButton) optional func plusButton() -> Any?
    @objc(plusChildViewController) optional func plusChildViewController() -> UIViewController?
    @objc(indexOfPlusButtonInTabBar) optional func indexOfPlusButtonInTabBar() -> UInt
    @objc(multiplierOfTabBarHeight:) optional func multiplierOfTabBarHeight(_ tabBarHeight: CGFloat) -> CGFloat
    @objc(multiplerInCenterY) optional func multiplerInCenterY() -> CGFloat
    @objc(constantOfPlusButtonCenterYOffsetForTabBarHeight:) optional func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat
    @objc(shouldSelectPlusChildViewController) optional func shouldSelectPlusChildViewController() -> Bool
    @objc(tabBarContext) optional func tabBarContext() -> String?
    @objc(alignsTitleWithTabBarItemTitles) optional func alignsTitleWithTabBarItemTitles() -> Bool
    @objc(selectedContentView) optional func selectedContentView() -> UIButton?
    @objc(contentImage) optional func contentImage() -> UIImage?
    @objc(selectedContentImage) optional func selectedContentImage() -> UIImage?
}

/**
 * [EN] `-setSelectedIndex:` of the FlatDesign tab bar, whose class the core reaches by name.
 * [CN] 扁平样式 TabBar 的 `-setSelectedIndex:`，Core 按类名访问该类。
 */
@objc private protocol CYLPlusButtonFlatDesignTabBarAPI {
    @objc(setSelectedIndex:) func setSelectedIndex(_ selectedIndex: UInt)
}

/**
 * [EN] The class method of CYLPlusButton.m that sets the C globals of CYLTabBarController.h.
 * [CN] CYLPlusButton.m 中设置 CYLTabBarController.h 里 C 全局变量的类方法。
 */
@objc private protocol CYLPlusButtonGlobalsAPI {
    @objc(cyl_mirrorLegacyGlobalsWithPlusButton:plusChildViewController:width:)
    func mirrorLegacyGlobals(plusButton: CYLPlusButton?, plusChildViewController: UIViewController?, width: CGFloat)
}

private func cylPlusButtonClass(_ cls: AnyClass) -> CYLPlusButtonClassAPI {
    unsafeBitCast(cls as AnyObject, to: CYLPlusButtonClassAPI.self)
}

private let cylPlusButtonImageStates: [UIControl.State] = [.normal, .highlighted, .selected, [.selected, .highlighted], .disabled]

/**
 * [EN] The states UIKit draws from another state's image when they have none, darkened (highlighted) or faded (disabled), mapped
 *      to the state whose image they show instead.
 * [CN] 没有图片时，系统会用其他状态的图片并加暗（高亮）或变淡（禁用）绘制的状态，以及改为显示其图片的状态。
 */
private let cylPlusButtonDerivedImageStates: [(derived: UIControl.State, source: UIControl.State)] = [
    (.highlighted, .normal), (.disabled, .normal), ([.selected, .highlighted], .selected),
]

/** [EN] Between the image and the title it sits above. [CN] 图片与其下方标题之间的间距。 */
private let cylPlusButtonImageToTitleSpacing: CGFloat = 2

/** [EN] The name of the lens mask layer. [CN] 放大镜遮罩图层的名称。 */
private let cylPlusButtonLensMaskName = "CYLPlusButtonLensMask"

// MARK: - Registry: context -> plus button

/**
 * [EN] What `+registerPlusButton` registers for one context. The globals of CYLTabBarController.h used to be the only plus button,
 *      so a second `+registerPlusButton` overwrote the first (issues #414, #489).
 * [CN] `+registerPlusButton` 为一个 context 注册的内容。CYLTabBarController.h 中的全局变量曾经是唯一的 PlusButton，第二次 `+registerPlusButton`
 *      会覆盖第一次（issue #414、#489）。
 */
final class CYLPlusButtonRegistration: NSObject {
    var context = ""
    var plusButton: CYLPlusButton?
    var plusChildViewController: UIViewController?
    var plusButtonWidth: CGFloat = 0
    var plusButtonClass: AnyClass?
    /** [EN] The tab bar controller that uses the registered instances (weak: free again once it is gone). [CN] 使用已注册实例的 TabBarController（弱引用）。 */
    weak var claimingTabBarController: CYLTabBarController?
    /** [EN] Plus buttons and plus child view controllers made for the other tab bar controllers of this context (weak). [CN] 为该 context 其他 TabBarController 创建的副本（弱引用）。 */
    let boundCopies = NSHashTable<AnyObject>.weakObjects()
}

/**
 * [EN] The plus button (and plus child view controller) ONE tab bar controller shows, kept on that controller: a view has one
 *      superview and a view controller one parent, so tab bar controllers that share a context cannot share the registered
 *      instances.
 * [CN] **一个** TabBarController 展示的 PlusButton（及子控制器），保存在该控制器上：一个 View 只能有一个父视图，一个 ViewController 只能有一个父控制器，
 *      所以共用 context 的多个 TabBarController 无法共用已注册的实例。
 */
final class CYLPlusButtonBinding: NSObject {
    weak var registration: CYLPlusButtonRegistration?
    var context = ""
    var plusButtonClass: AnyClass?
    var plusButton: CYLPlusButton?
    var plusChildViewController: UIViewController?
}

/**
 * [EN] The registrations by context, and the context registered last (nil once removed), which the globals describe.
 * [CN] 按 context 保存的注册内容，以及最后注册的 context（移除后为 nil），即全局变量描述的那个。
 */
private final class CYLPlusButtonRegistry: @unchecked Sendable {
    static let shared = CYLPlusButtonRegistry()
    private let lock = NSRecursiveLock()
    private var registrations: [String: CYLPlusButtonRegistration] = [:]
    var latestContext: String?

    func withLock<T>(_ body: (inout [String: CYLPlusButtonRegistration]) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&registrations)
    }

    func registration(for context: String?) -> CYLPlusButtonRegistration? {
        guard let context else { return nil }
        return withLock { $0[context] }
    }
}

/** [EN] Points the globals at `registration` (nil clears them). [CN] 让全局变量指向 `registration`（nil 时清空）。 */
private func cylPlusButtonMirrorLegacyGlobals(_ registration: CYLPlusButtonRegistration?) {
    CYLPlusButtonRegistry.shared.latestContext = registration?.context
    // [EN] The globals are nonnull in CYLTabBarController.h, so Swift cannot clear them: CYLPlusButton.m sets them.
    // [CN] 这些全局变量在 CYLTabBarController.h 中为 nonnull，Swift 无法将其置空：由 CYLPlusButton.m 设置。
    unsafeBitCast(CYLPlusButton.self as AnyObject, to: CYLPlusButtonGlobalsAPI.self)
        .mirrorLegacyGlobals(plusButton: registration?.plusButton, plusChildViewController: registration?.plusChildViewController,
                             width: registration?.plusButtonWidth ?? 0)
}

/**
 * [EN] The width registered for `plusButton`'s context, after the button changed size (e.g. its image loaded later): the classic
 *      and Flat tab bars lay the tabs out with it.
 * [CN] PlusButton 尺寸变化后（例如图片之后才加载）更新其 context 登记的宽度：经典与扁平样式的 TabBar 用它布局各 Tab。
 */
private func cylPlusButtonUpdateRegisteredWidth(_ plusButton: CYLPlusButton) {
    let registry = CYLPlusButtonRegistry.shared
    registry.withLock { registrations in
        for registration in registrations.values
        where registration.plusButton === plusButton || registration.boundCopies.contains(plusButton) {
            registration.plusButtonWidth = plusButton.bounds.width
            if registration.context == registry.latestContext {
                cylPlusButtonWidthValue = registration.plusButtonWidth
            }
        }
    }
}

// MARK: - Helpers

/**
 * [EN] Every image given to a plus button is drawn as is (`UIImageRenderingModeAlwaysOriginal`), in every style: never tinted by
 *      the tab bar, Liquid Glass's selected layer or a button configuration, and not darkened while touched.
 * [CN] 加载给 PlusButton 的所有图片在所有样式下都按原图绘制（`UIImageRenderingModeAlwaysOriginal`）：不会被 TabBar、液态玻璃的选中图层或按钮
 *      configuration 染色，按下时也不会变暗。
 */
private func cylPlusButtonOriginalImage(_ image: UIImage?) -> UIImage? {
    guard let image, image.renderingMode != .alwaysOriginal else { return image }
    return image.withRenderingMode(.alwaysOriginal)
}

/**
 * [EN] Whether two images draw the same picture: the same object, the same bitmap at the same size, or equal (e.g. the same symbol).
 * [CN] 两张图片是否绘制相同的内容：同一对象、相同尺寸的同一位图，或相等（例如同一 SF Symbol）。
 */
private func cylPlusButtonImagesDrawTheSame(_ image: UIImage?, _ otherImage: UIImage?) -> Bool {
    if image === otherImage {
        return true
    }
    guard let image, let otherImage, image.size == otherImage.size else { return false }
    if let cgImage = image.cgImage, cgImage === otherImage.cgImage {
        return true
    }
    return image.isEqual(otherImage)
}

/**
 * [EN] Draws the images a button already has as is: a stand-in returned by `+selectedContentView` may be any UIButton.
 * [CN] 让按钮已有的图片按原图绘制：`+selectedContentView` 返回的替身可能是任意 UIButton。
 */
private func cylPlusButtonDrawImagesAsIs(_ button: UIButton) {
    for state in cylPlusButtonImageStates {
        if let image = button.image(for: state), image.renderingMode != .alwaysOriginal {
            button.setImage(cylPlusButtonOriginalImage(image), for: state)
        }
        if let backgroundImage = button.backgroundImage(for: state), backgroundImage.renderingMode != .alwaysOriginal {
            button.setBackgroundImage(cylPlusButtonOriginalImage(backgroundImage), for: state)
        }
    }
}

/**
 * [EN] The center of `button`'s icon in `view`; nil while the icon is not laid out, or hidden: after the image is removed the hidden
 *      image view keeps its old frame.
 * [CN] `button` 的图标中心在 `view` 中的坐标；图标尚未布局或已隐藏时返回 nil：图片移除后，隐藏的 imageView 仍保留旧 frame。
 */
private func cylPlusButtonIconCenter(_ button: UIButton, in view: UIView?) -> CGPoint? {
    guard let imageView = button.imageView, let superview = imageView.superview, !imageView.isHidden, !imageView.frame.isEmpty else {
        return nil
    }
    return superview.convert(imageView.center, to: view)
}

/**
 * FIX: issue #216
 * [EN] The center of the stand-in, in its superview. When the app asks for the title to be aligned with the tab titles
 *      (`+alignsTitleWithTabBarItemTitles`), the stand-in and the plus button line up by icon only; in any other layout, or
 *      without a laid out icon, the plus button's center. A button whose picture is its background image has no icon to line up.
 * [CN] 替身在其父视图中的中心。App 要求标题与 Tab 标题对齐时（`+alignsTitleWithTabBarItemTitles`），替身与 PlusButton 只对齐图标；其他布局，或图标
 *      尚未布局时，使用 PlusButton 的中心。以背景图为图片的按钮没有可对齐的图标。
 */
private func cylPlusButtonCenterOfStandIn(_ plusButton: CYLPlusButton, _ standIn: UIButton) -> CGPoint {
    let container = standIn.superview
    if !plusButton.cylDrawsTitleOverBackgroundImage(), plusButton.cylAlignsTitleWithTabBarItemTitles(),
       let plusIcon = cylPlusButtonIconCenter(plusButton, in: container),
       let standInIcon = cylPlusButtonIconCenter(standIn, in: standIn) {
        return CGPoint(x: plusIcon.x - (standInIcon.x - standIn.bounds.midX), y: plusIcon.y - (standInIcon.y - standIn.bounds.midY))
    }
    return container?.convert(plusButton.center, from: plusButton.superview) ?? plusButton.center
}

/**
 * [EN] YES when `plusButton` is in a Liquid Glass tab bar: Liquid Glass is active AND its tab bar controller is not the FlatDesign
 *      style (on iOS 26 `+isLiquidGlassActive` is YES with the FlatDesign tab bar too). NO when there is no controller.
 * [CN] `plusButton` 位于液态玻璃 TabBar 中时为 YES：液态玻璃处于活动状态，且其 TabBarController 不是扁平样式（iOS 26 上使用扁平样式 TabBar 时
 *      `+isLiquidGlassActive` 也为 YES）。找不到 TabBarController 时为 NO。
 */
private func cylPlusButtonIsInLiquidGlassTabBar(_ plusButton: CYLPlusButton) -> Bool {
    guard CYLConstants.isLiquidGlassActive() else { return false }
    let tabBarController = plusButton.cylOwningTabBarController()
        ?? CYLTabBarController.cylTabBarController(forContext: CYLPlusButton.cylPlusButtonTabBarContext(forOwner: plusButton))
    guard let tabBarController else { return false }
    return tabBarController.tabBarStyleType != .flatDesign
}

/**
 * [EN] YES when `view`, or a superview of it below `plusButton`, takes touches itself (issue #202).
 * [CN] `view` 或它在 `plusButton` 之下的某个父视图自己接收触摸时为 YES（issue #202）。
 */
private func cylPlusButtonSubviewTakesTouches(_ view: UIView, _ plusButton: UIView) -> Bool {
    var current: UIView? = view
    while let candidate = current, candidate !== plusButton {
        if let control = candidate as? UIControl, control.isEnabled {
            return true
        }
        if candidate.gestureRecognizers?.contains(where: { $0.isEnabled }) == true {
            return true
        }
        current = candidate.superview
    }
    return false
}

/**
 * [EN] The stand-in (`-selectedContentView`) is a picture of the plus button in Liquid Glass's selected layer; the real plus button
 *      is the accessibility element. Hidden from accessibility.
 * [CN] 替身（`-selectedContentView`）是 PlusButton 在液态玻璃选中图层中的画面；真实 PlusButton 是无障碍元素。这里对无障碍隐藏。
 */
private func cylPlusButtonHideStandInFromAccessibility(_ plusButton: UIButton, _ standIn: UIButton) {
    guard standIn !== plusButton else { return }
    standIn.isAccessibilityElement = false
    standIn.accessibilityElementsHidden = true
}

/** [EN] The first `UITabBar` among `view` and its superviews. [CN] `view` 及其父视图中的第一个 `UITabBar`。 */
private func cylPlusButtonSystemTabBar(of view: UIView?) -> UITabBar? {
    var current = view
    while let candidate = current {
        if let tabBar = candidate as? UITabBar {
            return tabBar
        }
        current = candidate.superview
    }
    return nil
}

// MARK: - State

/**
 * [EN] The state of one `CYLPlusButton` (the stored values of its properties, and its private state).
 * [CN] 一个 `CYLPlusButton` 的状态（属性的存储值，以及私有状态）。
 */
final class CYLPlusButtonStorage: NSObject {
    var snapshot: UIImage?
    weak var selectedContentView: UIButton?
    var contentImage: UIImage?
    var selectedContentImage: UIImage?
    /** [EN] Issue #91: the overlay of `showsTouchableArea`, in the superview, under the plus button. [CN] 可点击区域的调试覆盖层。 */
    var touchableAreaView: UIView?
    var touchableAreaOutsets: UIEdgeInsets = .zero
    var touchableAreaScale: CGFloat = 0
    var showsTouchableArea = false
    var touchableAreaColor: UIColor?
    /** [EN] Issue #152: the view controller selected on the last touch down, and whether there was one. [CN] 上次按下时选中的控制器，以及是否有按下。 */
    weak var selectedViewControllerAtTouchDown: UIViewController?
    var hasTouchDownForTabBarItemGesture = false
    /** [EN] Set while this class lays out its image and title (`cylLayOutContentOnce`). [CN] 本类布置图片与标题期间为 YES。 */
    var isLayingOutContent = false
    /** [EN] Made by `+cyl_plusButtonWithImage:…`: its image sits above its title. [CN] 由 `+cyl_plusButtonWithImage:…` 创建：图片位于标题上方。 */
    var isMadeWithImageAndTitle = false
    var appAccessibilityLabel: String?
    /** [EN] Not set: the deprecated flag decides. [CN] 未设置：由已废弃的标记决定。 */
    var reportsTapsToDelegate: Bool?
    var appliesCenterYOffsetWithoutTitle = false
    /**
     * [EN] Issue #636: the title moved into the tab item, and from the image's bottom edge to the title's center line, measured
     *      before the title moved (from the edge, so an image set or replaced later keeps the distance).
     * [CN] Issue #636：移到 TabBarItem 中的标题，以及标题移走前测得的图片底边到标题中心线的距离（以底边计算，之后设置或替换的图片保持同一距离）。
     */
    var movedTitle: String?
    var imageBottomToTitle: CGFloat?
    /** [EN] The title style applied from the tab titles (font, normal, selected). [CN] 按 Tab 标题应用的标题样式（字体、普通、选中）。 */
    var titleStyle: NSDictionary?
    /** [EN] The title font the app gave the plus button, before the tab titles' font was applied. [CN] 应用 Tab 标题字体之前 App 设置的字体。 */
    var originalTitleFont: UIFont?
    /** [EN] The tab titles' center line, in the plus button, while its title stays in the button. [CN] 标题留在按钮中时 Tab 标题的中心线。 */
    var alignedTitleCenterY: CGFloat?
    /** [EN] The images last set by `-cyl_updateTitle:image:selectedImage:`. [CN] 最近一次由 `-cyl_updateTitle:image:selectedImage:` 设置的图片。 */
    var updatedImage: UIImage?
    var updatedSelectedImage: UIImage?
    /** [EN] The last badge asked for, see `cylShowRequestedBadgeIfNeeded`. [CN] 最后一次请求的角标。 */
    var requestedBadgeValue: String?
    var requestedBadgeAnimationType: NSNumber?
    /** [EN] See `-cyl_setBackgroundImageDidChangeHandler:`. [CN] 见 `-cyl_setBackgroundImageDidChangeHandler:`。 */
    var backgroundImageHandler: (() -> Void)?
    /** [EN] The selected images set while the plus button draws its normal image instead. [CN] PlusButton 改为绘制普通图片期间保存的选中图片。 */
    var keptSelectedImages: [UInt: UIImage] = [:]
    /** [EN] The states whose image, or background image, was set on purpose. [CN] 主动设置过图片或背景图片的状态。 */
    var explicitImageStates: Set<UInt> = []
    var explicitBackgroundImageStates: Set<UInt> = []
    var isLensMaskSuspended = false
    weak var observedTitleLabel: UILabel?
}

private enum CYLPlusButtonImplementationKeys {
    static var storage: UInt8 = 0
    static var binding: UInt8 = 0
}

extension CYLPlusButton {

    var cylPlusButtonStorage: CYLPlusButtonStorage {
        if let storage = objc_getAssociatedObject(self, &CYLPlusButtonImplementationKeys.storage) as? CYLPlusButtonStorage {
            return storage
        }
        let storage = CYLPlusButtonStorage()
        objc_setAssociatedObject(self, &CYLPlusButtonImplementationKeys.storage, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return storage
    }

    private var cylSuper: CYLPlusButtonSuperAPI {
        unsafeBitCast(self as AnyObject, to: CYLPlusButtonSuperAPI.self)
    }

    /**
     * [EN] The class of this button as the runtime sees it (`object_getClass`), so a class made at run time answers for itself.
     * [CN] 运行时看到的本按钮的类（`object_getClass`），运行时创建的类因此由其自身回答。
     */
    private var cylClass: CYLPlusButtonClassAPI {
        cylPlusButtonClass(object_getClass(self) ?? type(of: self))
    }

    /** [EN] The stand-in, unless it is this button itself. [CN] 替身（不是本按钮自身时）。 */
    private var cylStandIn: UIButton? {
        let standIn = cylPlusButtonStorage.selectedContentView
        return standIn === self ? nil : standIn
    }

    // MARK: Accessibility, interactions

    /**
     * [EN] VoiceOver: an icon-only plus button was read as its image's file name (or not at all). It is read as its title, or as
     *      "plus button" in the app's language when it has none; an `accessibilityLabel` set by the app still wins.
     * [CN] VoiceOver：仅有图标的 PlusButton 会被读成图片文件名（或不读）。现在朗读其标题；没有标题时朗读 App 语言的“加号按钮”；App 自行设置的
     *      `accessibilityLabel` 仍然优先。
     */
    @objc(cyl_plusButtonAccessibilityLabel)
    func cylPlusButtonAccessibilityLabel() -> String {
        if let label = cylPlusButtonStorage.appAccessibilityLabel, !label.isEmpty {
            return label
        }
        let title = currentTitle ?? cylPlusButtonStorage.movedTitle ?? titleLabel?.text
        if let title, !title.isEmpty {
            return title
        }
        return cylLocalizedString("加号按钮")
    }

    @objc(cyl_plusButtonSetAccessibilityLabel:)
    func cylPlusButtonSetAccessibilityLabel(_ accessibilityLabel: String?) {
        cylPlusButtonStorage.appAccessibilityLabel = accessibilityLabel
    }

    /**
     * [EN] VoiceOver: the plus button is announced as selected while its page is shown, like a tab.
     * [CN] VoiceOver：PlusButton 对应的页面显示时，与 Tab 一样朗读为"已选中"。
     */
    @objc(cyl_plusButtonAccessibilityTraits:)
    func cylPlusButtonAccessibilityTraits(_ superTraits: UIAccessibilityTraits) -> UIAccessibilityTraits {
        let traits = superTraits.union(.button)
        return isSelected ? traits.union(.selected) : traits
    }

    /**
     * [EN] Defaults that system tab buttons already have: the iPad pointer hover effect and the Large Content Viewer. Set at
     *      creation, so the app can turn them off afterwards.
     * [CN] 系统 Tab 按钮本来就有的默认行为：iPad 指针悬停效果与大内容查看器。在创建时设置，App 之后可以关闭。
     */
    @objc(cyl_setUpTabLikeInteractions)
    func cylSetUpTabLikeInteractions() {
        isPointerInteractionEnabled = true
        showsLargeContentViewer = true
        scalesLargeContentImage = true
    }

    @objc(cyl_plusButtonLargeContentTitle:)
    func cylPlusButtonLargeContentTitle(_ superTitle: String?) -> String? {
        if let superTitle, !superTitle.isEmpty {
            return superTitle
        }
        return accessibilityLabel
    }

    /**
     * [EN] The Large Content Viewer needs an interaction on an ancestor; add one to the bar when it has none.
     * [CN] 大内容查看器需要祖先视图上有对应的 interaction；所在的 TabBar 没有时为其添加一个。
     */
    private func cylInstallLargeContentViewerInteractionIfNeeded() {
        guard let bar = superview, showsLargeContentViewer else { return }
        if bar.interactions.contains(where: { $0 is UILargeContentViewerInteraction }) {
            return
        }
        bar.addInteraction(UILargeContentViewerInteraction())
    }

    // MARK: Creation

    /**
     * [EN] Sets up a button made by `+cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:`.
     * [CN] 设置由 `+cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:` 创建的按钮。
     */
    @objc(cyl_plusButtonSetUpWithImage:title:selectedTitle:selectedTitleColor:)
    func cylPlusButtonSetUp(image: UIImage?, title: String?, selectedTitle: String?, selectedTitleColor: UIColor?) {
        setImage(image, for: .normal)
        // [EN] An explicit highlighted image is drawn as is, so the button does not darken on touch.
        // [CN] 显式设置的高亮图片按原样绘制，按下时按钮不会变暗。
        setImage(image, for: .highlighted)
        // [EN] Issue #636: Liquid Glass with a title, the selected states too, so the selected plus button is not dimmed either.
        // [CN] 液态玻璃下有标题时（issue #636）选中状态也显式设置，选中后不会变暗。
        if CYLConstants.isLiquidGlassActive(), let title, !title.isEmpty {
            setImage(image, for: .selected)
            setImage(image, for: [.selected, .highlighted])
        }
        titleLabel?.textAlignment = .center
        titleLabel?.font = UIFont.systemFont(ofSize: 10)
        setTitle(cylLocalizedString(title ?? ""), for: .normal)
        setTitleColor(.gray, for: .normal)
        setTitle(cylLocalizedString(selectedTitle ?? title ?? ""), for: .selected)
        setTitleColor(selectedTitleColor ?? .blue, for: .selected)
        cylPlusButtonStorage.isMadeWithImageAndTitle = true
        sizeToFit()
    }

    // MARK: Images

    /**
     * [EN] Sets `image` for `state` (through `setter`, the superclass's), then gives every derived state that was never set on
     *      purpose the plain image of its source state, so UIKit never darkens or fades a plus button's image.
     * [CN] 为 `state` 设置 `image`（通过 `setter`，即父类方法），然后为每个未被主动设置过的派生状态设置其来源状态的原图，系统因此不会把 PlusButton
     *      的图片画暗或变淡。
     */
    private func cylSetImage(_ image: UIImage?, for state: UIControl.State, explicitStates: inout Set<UInt>,
                             getter: (UIControl.State) -> UIImage?, setter: (UIImage?, UIControl.State) -> Void) {
        explicitStates.insert(state.rawValue)
        setter(cylPlusButtonOriginalImage(image), state)
        for (derived, source) in cylPlusButtonDerivedImageStates where !explicitStates.contains(derived.rawValue) {
            // [EN] `getter` falls back like UIKit (e.g. no selected image: the normal one). [CN] `getter` 与系统一样回退。
            setter(getter(source), derived)
        }
    }

    @objc(cyl_plusButtonSetImage:forState:)
    func cylPlusButtonSetImage(_ image: UIImage?, for state: UIControl.State) {
        let storage = cylPlusButtonStorage
        storage.keptSelectedImages[state.rawValue] = nil
        var explicitStates = storage.explicitImageStates
        cylSetImage(image, for: state, explicitStates: &explicitStates,
                    getter: { cylSuper.superImage(for: $0) }, setter: { cylSuper.superSetImage($0, for: $1) })
        storage.explicitImageStates = explicitStates
        if state == .normal {
            cylUpdateSelectedContentViewImage(removingIfEmpty: image == nil)
            cylContentImageDidChange()
        }
    }

    /** [EN] A selected image kept by `cylUpdateSelectedContentViewImage`. [CN] 由 `cylUpdateSelectedContentViewImage` 保存的选中图片。 */
    @objc(cyl_plusButtonKeptImageForState:)
    func cylPlusButtonKeptImage(for state: UIControl.State) -> UIImage? {
        cylPlusButtonStorage.keptSelectedImages[state.rawValue]
    }

    @objc(cyl_removeImage)
    func cylRemoveImage() {
        let standIn = cylStandIn
        for state in cylPlusButtonImageStates {
            setImage(nil, for: state)
            standIn?.setImage(nil, for: state)
        }
        if var configuration = self.configuration, configuration.image != nil {
            configuration.image = nil
            self.configuration = configuration
        }
        if let standIn, var configuration = standIn.configuration, configuration.image != nil {
            configuration.image = nil
            standIn.configuration = configuration
        }
        superview?.setNeedsLayout()
    }

    /** [EN] Liquid Glass with a plus child view controller. [CN] 液态玻璃且有 PlusButton 子控制器。 */
    private func cylStandInShowsNormalImageOnly() -> Bool {
        cylPlusButtonIsInLiquidGlassTabBar(self) && CYLPlusButton.cylPlusChildViewControllerValue(forOwner: self) != nil
    }

    /**
     * FIX: issue #216
     * [EN] Liquid Glass with a plus child view controller only: the stand-in in the selected layer is a copy of the one real plus
     *      button, split by the glass, so both show the real button's normal image, in every state of the stand-in. A selected
     *      image set on the plus button stays on it and is not used here. Idempotent: also run on every layout pass.
     * [CN] 仅限液态玻璃且有 PlusButton 子控制器时：选中图层中的替身是唯一的真实 PlusButton 的副本，两者被玻璃分开，因此都显示真实按钮普通状态的图片，
     *      替身所有状态都用它。设置给 PlusButton 的选中图片仍保留在 PlusButton 上，这里不使用。可重复调用：每次布局时也会执行。
     */
    @objc(cyl_updateSelectedContentViewImage)
    func cylUpdateSelectedContentViewImage() {
        cylUpdateSelectedContentViewImage(removingIfEmpty: false)
    }

    /**
     * [EN] `removingIfEmpty`: the normal image was removed; its copies in the selected states go too.
     * [CN] `removingIfEmpty`：普通图片已被移除；选中状态下的副本也一并移除。
     */
    private func cylUpdateSelectedContentViewImage(removingIfEmpty: Bool) {
        guard let standIn = cylStandIn, cylStandInShowsNormalImageOnly() else { return }
        let image = configuration?.image ?? image(for: .normal)
        if image == nil && !removingIfEmpty {
            return
        }
        if var configuration = standIn.configuration, !cylPlusButtonImagesDrawTheSame(configuration.image, image) {
            configuration.image = image
            standIn.configuration = configuration
        }
        for state in cylPlusButtonImageStates where !cylPlusButtonImagesDrawTheSame(standIn.image(for: state), image) {
            standIn.setImage(image, for: state)
        }
        // [EN] The real button is selected while the stand-in shows, so it draws the same picture too; its own selected image
        //      stays readable through `-imageForState:`.
        // [CN] 显示替身时真实按钮处于选中状态，因此也绘制同一张图片；它自己的选中图片仍可通过 `-imageForState:` 读取。
        let storage = cylPlusButtonStorage
        for state: UIControl.State in [.selected, [.selected, .highlighted]] {
            guard let drawnImage = cylSuper.superImage(for: state), !cylPlusButtonImagesDrawTheSame(drawnImage, image) else {
                continue
            }
            if storage.keptSelectedImages[state.rawValue] == nil {
                storage.keptSelectedImages[state.rawValue] = drawnImage
            }
            cylSuper.superSetImage(image, for: state)
        }
    }

    @objc(cyl_plusButtonSetBackgroundImage:forState:)
    func cylPlusButtonSetBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        let storage = cylPlusButtonStorage
        var explicitStates = storage.explicitBackgroundImageStates
        cylSetImage(image, for: state, explicitStates: &explicitStates,
                    getter: { cylSuper.superBackgroundImage(for: $0) }, setter: { cylSuper.superSetBackgroundImage($0, for: $1) })
        storage.explicitBackgroundImageStates = explicitStates
        if state == .normal {
            if image != nil, let handler = storage.backgroundImageHandler {
                handler()
            }
            cylContentImageDidChange()
        }
    }

    @objc(cyl_setBackgroundImageDidChangeHandler:)
    func cylSetBackgroundImageDidChangeHandler(_ handler: (() -> Void)?) {
        cylPlusButtonStorage.backgroundImageHandler = handler
    }

    /**
     * [EN] Content that changed after the plus button was sized and placed (an image set, replaced or removed, or the title's
     *      font): the button grows around its center when the content no longer fits (never below a size the app set), and the
     *      tab bar places it again. Before it is first sized, nothing to do.
     * [CN] PlusButton 确定尺寸与位置之后内容发生变化（设置、替换或移除图片，或标题字体变化）：内容放不下时按钮以中心为基准变大（不会小于 App 设置的
     *      尺寸），TabBar 重新放置它。首次确定尺寸之前无需处理。
     */
    private func cylGrowToFitContentIfNeeded() {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return }
        let fittingSize = sizeThatFits(.zero)
        if fittingSize.width > size.width + 0.5 || fittingSize.height > size.height + 0.5 {
            let center = self.center
            bounds = CGRect(origin: .zero, size: CGSize(width: max(size.width, fittingSize.width), height: max(size.height, fittingSize.height)))
            self.center = center
            cylPlusButtonUpdateRegisteredWidth(self)
        }
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    @objc(cyl_plusButtonSetConfiguration:)
    func cylPlusButtonSetConfiguration(_ configuration: UIButton.Configuration?) {
        var configuration = configuration
        if var newConfiguration = configuration,
           (newConfiguration.image.map { $0.renderingMode != .alwaysOriginal } ?? false) ||
           (newConfiguration.background.image.map { $0.renderingMode != .alwaysOriginal } ?? false) {
            newConfiguration.image = cylPlusButtonOriginalImage(newConfiguration.image)
            newConfiguration.background.image = cylPlusButtonOriginalImage(newConfiguration.background.image)
            configuration = newConfiguration
        }
        let oldConfiguration = self.configuration
        cylSuper.superSetConfiguration(configuration)
        // [EN] Only a new picture: the plus button sets its configuration too (e.g. without the title, #636), and treating that
        //      as a new picture moved the title back and forth forever. Images are compared by what they draw.
        // [CN] 仅在图片变化时处理：PlusButton 自己也会设置 configuration（例如去掉标题，#636），把它当作新图片会让标题来回移动、无限循环。按绘制内容比较图片。
        if !cylPlusButtonImagesDrawTheSame(configuration?.image, oldConfiguration?.image) ||
            !cylPlusButtonImagesDrawTheSame(configuration?.background.image, oldConfiguration?.background.image) {
            cylUpdateSelectedContentViewImage()
            cylContentImageDidChange()
        }
    }

    /**
     * [EN] Liquid Glass, an image arriving while the plus button shows its own title: the title is about to move into the tab item
     *      (#636), so it gets back the font the app gave it first (sized with the tab titles' font, the image sat on half a point).
     *      Buttons with a configuration keep their transformer.
     * [CN] 液态玻璃下，PlusButton 显示自己的标题时图片到来：标题即将移到 TabBarItem 中（#636），因此先恢复 App 设置的字体（按 Tab 标题字体计算时，图片落在
     *      半个点上）。使用 configuration 的按钮保留其 transformer。
     */
    private func cylRestoreOriginalTitleFontBeforeTitleMoves() {
        let storage = cylPlusButtonStorage
        guard let originalFont = storage.originalTitleFont, CYLConstants.isLiquidGlassActive(), cylHasImage(),
              cylAlignsTitleWithTabBarItemTitles(), configuration == nil else {
            return
        }
        titleLabel?.font = originalFont
        storage.titleStyle = nil
    }

    /**
     * [EN] The picture changed: the title moved into the tab item comes back so the next layout measures with the new picture, room
     *      for the picture, and a badge already shown moves onto it. Only when a badge exists; never during layout.
     * [CN] 图片发生变化：移到 TabBarItem 中的标题先回到按钮，下次布局用新图片测量；为图片留出空间；已显示的角标移到图片上。仅在已有角标时处理；不会在布局
     *      期间执行。
     */
    private func cylContentImageDidChange() {
        cylReturnTitleFromTabBarItem()
        cylRestoreOriginalTitleFontBeforeTitleMoves()
        cylGrowToFitContentIfNeeded()
        if objc_getAssociatedObject(self, unsafeBitCast(NSSelectorFromString("cyl_badgeAnchorViewAlignedToView:"), to: UnsafeRawPointer.self)) != nil {
            cylRefreshBadge()
        }
        cylShowRequestedBadgeIfNeeded()
    }

    // MARK: Badges

    /**
     * [EN] A badge asked for while the plus button had no picture is dropped once its layout retries run out, and the picture can
     *      arrive much later: the last request is kept and shown when the picture comes.
     * [CN] PlusButton 还没有图片时请求的角标，在布局重试用完后会被丢弃，而图片可能很久之后才到：这里保留最后一次请求，图片到达时再显示。
     */
    @objc(cyl_plusButtonShowBadgeValue:animationTypeValue:)
    func cylPlusButtonShowBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        let storage = cylPlusButtonStorage
        storage.requestedBadgeValue = value
        storage.requestedBadgeAnimationType = animationTypeValue
        cylSuper.superShowBadgeValue(value, animationTypeValue: animationTypeValue)
    }

    @objc(cyl_plusButtonClearBadge)
    func cylPlusButtonClearBadge() {
        cylPlusButtonStorage.requestedBadgeValue = nil
        cylSuper.superClearBadge()
    }

    /** [EN] Also when the stand-in is made after the badge was asked for. [CN] 也包括在请求角标之后才创建替身的情况。 */
    private func cylShowRequestedBadgeIfNeeded() {
        let storage = cylPlusButtonStorage
        guard let value = storage.requestedBadgeValue else { return }
        let animationType = storage.requestedBadgeAnimationType ?? NSNumber(value: 0)
        for control in cylPlusButtonBadgeLayerControls() where control.cyl_badge?.superview == nil {
            control.cylShowBadgeValueInThisLayer(value, animationTypeValue: animationType)
        }
    }

    /**
     * FIX: issue #779
     * [EN] The plus button's two layers: the real button, and on Liquid Glass with a stand-in, the stand-in in the selected layer;
     *      the glass splits the badge as it splits the icon.
     * [CN] PlusButton 的两个图层：真实按钮，以及液态玻璃下选中图层中的替身；玻璃像分割图标一样分割角标。
     */
    @objc(cyl_plusButtonBadgeLayerControls)
    func cylPlusButtonBadgeLayerControls() -> [UIControl] {
        if let standIn = cylStandIn, cylPlusButtonIsInLiquidGlassTabBar(self) {
            return [self, standIn]
        }
        return [self]
    }

    // MARK: Title alignment

    /** [EN] Called by `-layoutSublayersOfLayer:` for the button's own layer, after super. [CN] 由 `-layoutSublayersOfLayer:` 在 super 之后为按钮自身图层调用。 */
    @objc(cyl_plusButtonLayoutSublayers)
    func cylPlusButtonLayoutSublayers() {
        cylLayOutContentOnce { cylAlignTitleWithTabBarItemTitlesIfNeeded() }
    }

    /**
     * [EN] Runs `layout` unless this class is already laying out the image and title: the first read of `imageView` (or
     *      `titleLabel`) lays the button out again, which ran this layout again, endlessly. One flag for both layouts.
     * [CN] 本类正在布置图片与标题时不再执行 `layout`：第一次读取 `imageView`（或 `titleLabel`）会再次布局按钮，从而再次执行本布局，无限递归。两种布局
     *      共用一个标记。
     */
    private func cylLayOutContentOnce(_ layout: () -> Void) {
        let storage = cylPlusButtonStorage
        guard !storage.isLayingOutContent else { return }
        storage.isLayingOutContent = true
        layout()
        storage.isLayingOutContent = false
    }

    @objc(cyl_alignsTitleWithTabBarItemTitles)
    func cylAlignsTitleWithTabBarItemTitles() -> Bool {
        if let aligns = cylClass.alignsTitleWithTabBarItemTitles?() {
            return aligns
        }
        // [EN] Not implemented: the core's default. A plus button with a title (and not one whose title is part of its background image) lines
        //      its title up with the tab titles, so no app has to implement the method; implementing it can still return NO.
        // [CN] 未实现：核心的默认值。有标题的 PlusButton（标题不是背景图的一部分）使其标题与 Tab 标题对齐，App 无需实现该方法；
        //      实现后仍可返回 NO。
        let title = title(for: .normal) ?? configuration?.title ?? ""
        return !title.isEmpty && !cylDrawsTitleOverBackgroundImage()
    }

    @objc(cyl_plusButtonSetNeedsTitleAlignment)
    func cylPlusButtonSetNeedsTitleAlignment() {
        if cylAlignsTitleWithTabBarItemTitles() {
            setNeedsLayout()
        }
    }

    /**
     * [EN] Called by `-traitCollectionDidChange:` after super: the title colors are resolved for the tab titles' appearance.
     * [CN] 由 `-traitCollectionDidChange:` 在 super 之后调用：标题颜色按 Tab 标题的外观解析。
     */
    @objc(cyl_plusButtonTraitCollectionDidChange:)
    func cylPlusButtonTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            cylPlusButtonSetNeedsTitleAlignment()
        }
    }

    /**
     * [EN] The center `-setCenter:` passes to super: moving the plus button does not lay it out again, but moves its title off the
     *      tab titles' line.
     * [CN] `-setCenter:` 传给 super 的中心：移动 PlusButton 不会再次布局，但会让标题偏离 Tab 标题所在的线。
     */
    @objc(cyl_plusButtonCenterForCenter:)
    func cylPlusButtonCenter(forCenter center: CGPoint) -> CGPoint {
        cylCenterOfStandIn(forCenter: center)
    }

    /** [EN] Called by `-setCenter:` after super. [CN] 由 `-setCenter:` 在 super 之后调用。 */
    @objc(cyl_plusButtonDidSetCenterMoved:)
    func cylPlusButtonDidSetCenter(moved: Bool) {
        if moved {
            cylPlusButtonSetNeedsTitleAlignment()
            cylMoveSelectedContentViewWithPlusButton()
        }
        // [EN] Issue #91: the touchable area overlay follows the plus button. [CN] 可点击区域的调试视图跟随 PlusButton。
        if cylPlusButtonStorage.showsTouchableArea {
            cylUpdateTouchableAreaView()
        }
    }

    /**
     * [EN] Called by `-setFrame:` after super; returns the center to put back with super's `-setCenter:` (a stand-in placed by
     *      frame goes back onto the plus button's position), or nil.
     * [CN] 由 `-setFrame:` 在 super 之后调用；返回需要通过 super 的 `-setCenter:` 放回的中心（按 frame 放置的替身回到 PlusButton 的位置），否则为 nil。
     */
    @objc(cyl_plusButtonDidSetFrameMoved:)
    func cylPlusButtonDidSetFrame(moved: Bool) -> NSValue? {
        var correctedCenter: NSValue?
        if moved {
            cylPlusButtonSetNeedsTitleAlignment()
            let center = cylCenterOfStandIn(forCenter: self.center)
            if center != self.center {
                correctedCenter = NSValue(cgPoint: center)
            }
        }
        return correctedCenter
    }

    /** [EN] Called by `-setFrame:` last. [CN] 由 `-setFrame:` 最后调用。 */
    @objc(cyl_plusButtonUpdateTouchableAreaIfShown)
    func cylPlusButtonUpdateTouchableAreaIfShown() {
        if cylPlusButtonStorage.showsTouchableArea {
            cylUpdateTouchableAreaView()
        }
    }

    /**
     * FIX: issue #636
     * [EN] With a plus child view controller, Liquid Glass shows this plus button's stand-in in the selected layer, through the
     *      lens; its center must be the plus button's, converted from the other layer. Returns `center` for any other view.
     * [CN] 有 PlusButton 子控制器时，液态玻璃在选中图层（透过放大镜）显示 PlusButton 的替身；替身中心必须与 PlusButton 一致（在两个图层之间坐标转换）。
     *      对其他视图原样返回 `center`。
     */
    private func cylCenterOfStandIn(forCenter center: CGPoint) -> CGPoint {
        guard superview != nil, CYLConstants.isLiquidGlassActive(), cylIsInPlatterSelectedLayer(),
              let plusButton = CYLPlusButton.cylPlusButton(forOwner: self), plusButton !== self, plusButton.superview != nil,
              CYLPlusButton.cylPlusChildViewControllerValue(forOwner: self) != nil, plusButton.cylStandInFollowsPlusButton() else {
            return center
        }
        return cylPlusButtonCenterOfStandIn(plusButton, self)
    }

    /**
     * [EN] The layouts whose stand-in stays on the plus button's position: the title in the tab item, no title, a title drawn over
     *      the background image, or whenever the app asks for the title to be aligned.
     * [CN] 替身保持在 PlusButton 位置的布局：标题由 TabBarItem 显示、没有标题、标题画在背景图上，或 App 要求标题对齐时。
     */
    private func cylStandInFollowsPlusButton() -> Bool {
        cylShowsTitleInTabBarItem() || cylHasNoTitleInLiquidGlass() ||
            (CYLConstants.isLiquidGlassActive() && (cylDrawsTitleOverBackgroundImage() || cylAlignsTitleWithTabBarItemTitles()))
    }

    // MARK: Liquid Glass: the title in the tab item (issue #636)

    /**
     * FIX: issue #636
     * [EN] Liquid Glass, a plus button with a title and an image, and `+alignsTitleWithTabBarItemTitles` returning YES: the title
     *      moves into the tab item under the plus button, which the system draws in both layers with the tab font, position and
     *      colors, and the plus button keeps only its image, in place of the tab icon.
     * [CN] 液态玻璃下，PlusButton 有标题与图片，且 `+alignsTitleWithTabBarItemTitles` 返回 YES：标题改由 PlusButton 下方的 TabBarItem 显示，系统在两个图层中
     *      以 Tab 的字体、位置和颜色绘制；PlusButton 只保留图片，替换 Tab 的图标。
     */
    @objc(cyl_plusButtonShowsTitleInTabBarItem)
    func cylShowsTitleInTabBarItem() -> Bool {
        guard CYLConstants.isLiquidGlassActive(), cylViewControllerOfTabBarItem() != nil, !cylDrawsTitleOverBackgroundImage(), cylHasImage() else {
            return false
        }
        if (cylPlusButtonStorage.movedTitle ?? "").isEmpty && (currentTitle ?? "").isEmpty {
            return false
        }
        return cylPlusButtonSystemTabBar(of: superview) != nil
    }

    /**
     * [EN] A plus button drawn with a background image and no image: its title is part of that picture, so it keeps its title and is
     *      placed as in the other styles.
     * [CN] 使用背景图片且没有图片的 PlusButton：标题是这张图的一部分，因此保留自己的标题，与其他样式一样定位。
     */
    @objc(cyl_drawsTitleOverBackgroundImage)
    func cylDrawsTitleOverBackgroundImage() -> Bool {
        backgroundImage(for: .normal) != nil && !cylHasImage()
    }

    /**
     * [EN] Whether the plus button has an image to show (not empty). Without one it keeps its own title.
     * [CN] PlusButton 是否有可显示的图片（非空）。没有时保留自己的标题。
     */
    private func cylHasImage() -> Bool {
        guard let image = image(for: .normal) ?? configuration?.image else { return false }
        return image.size.width > 0 && image.size.height > 0
    }

    /**
     * [EN] The view controller of the tab item under the plus button: the plus button's own, else the placeholder.
     * [CN] PlusButton 下方 TabBarItem 的控制器：PlusButton 的子控制器，没有时为占位控制器。
     */
    private func cylViewControllerOfTabBarItem() -> UIViewController? {
        if let plusChildViewController = CYLPlusButton.cylPlusChildViewControllerValue(forOwner: self) {
            return plusChildViewController
        }
        return cylOwningTabBarController()?.viewControllers?.first { $0.cyl_isPlaceholder }
    }

    private func cylLayOutForTitleInTabBarItem() {
        guard let imageView, let imageSuperview = imageView.superview else { return }
        let storage = cylPlusButtonStorage
        if storage.movedTitle == nil {
            // [EN] Measured while the title is still laid out, so the image keeps the distance from the title it has in the Flat style.
            // [CN] 在标题仍处于布局状态时测量，使图片与标题保持扁平样式中的距离。
            var imageFrame = imageSuperview.convert(imageView.frame, to: self)
            var titleFrame = titleLabel.flatMap { label in label.superview?.convert(label.frame, to: self) } ?? .zero
            if storage.isMadeWithImageAndTitle {
                (imageFrame, titleFrame) = cylImageAndTitleFrames()
            }
            storage.movedTitle = currentTitle
            storage.imageBottomToTitle = titleFrame.midY - imageFrame.maxY
            // [EN] The stand-in in the selected layer is a second plus button: it drops its title too, the tab item has it.
            // [CN] 选中图层中的替身是第二个 PlusButton：它也去掉标题，由 TabBarItem 显示。
            cylUpdateTitleInTabBarItem()
            for state: UIControl.State in [.normal, .highlighted, .selected, [.selected, .highlighted]] {
                setTitle(nil, for: state)
            }
            if var configuration = self.configuration {
                configuration.title = nil
                configuration.attributedTitle = nil
                self.configuration = configuration
            }
            setNeedsLayout()
            superview?.setNeedsLayout()
            return
        }
        // [EN] The stand-in is placed from the plus button. [CN] 替身根据 PlusButton 放置。
        if cylIsInPlatterSelectedLayer() {
            return
        }
        // [EN] New view controllers bring a new placeholder, without the title. [CN] 重设子控制器后占位控制器是新的，没有标题。
        cylUpdateTitleInTabBarItem()
        guard superview != nil else { return }
        let center = cylAlignedCenter(forCenter: self.center)
        if abs(center.x - self.center.x) >= 0.5 || abs(center.y - self.center.y) >= 0.5 {
            self.center = center
        }
    }

    /**
     * [EN] The title moved into the tab item (#636) comes back to the plus button when that layout no longer applies.
     * [CN] 移到 TabBarItem 中的标题（#636）在该布局不再适用时回到 PlusButton。
     */
    private func cylRestoreTitleFromTabBarItemIfNeeded() {
        if !cylShowsTitleInTabBarItem() {
            cylReturnTitleFromTabBarItem()
        }
    }

    /**
     * [EN] Gives the title moved into the tab item back to the plus button. The stand-in takes it back only without an image (a plus
     *      button that lost its image to a background image), and has no say over the tab item.
     * [CN] 把移到 TabBarItem 中的标题还给 PlusButton。替身只在没有图片时取回标题（因背景图片而失去图片的 PlusButton），且不改动 TabBarItem。
     */
    private func cylReturnTitleFromTabBarItem() {
        let storage = cylPlusButtonStorage
        let isStandIn = cylIsInPlatterSelectedLayer()
        guard let movedTitle = storage.movedTitle, !movedTitle.isEmpty, !(isStandIn && cylHasImage()) else { return }
        storage.movedTitle = nil
        storage.imageBottomToTitle = nil
        if !isStandIn, let tabBarItem = cylViewControllerOfTabBarItem()?.tabBarItem, tabBarItem.title == movedTitle {
            tabBarItem.title = nil
        }
        setTitle(movedTitle, for: .normal)
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    /**
     * [EN] Whether the tab bar shows its tab buttons in the iOS 27.1 vertical bar (unfolded iPhone Duo in landscape).
     * [CN] 系统是否把 Tab 按钮放在 iOS 27.1 竖向栏中（iPhone Duo 展开横屏）。
     */
    private func cylIsInVerticalBar() -> Bool {
        (superview as? CYLTabBar)?.cylTabBarShowsVerticalBar() ?? false
    }

    /** [EN] Issue #13: whether the tab bar is shown minimized (iOS 26+). [CN] 系统是否正以缩小状态显示 TabBar（iOS 26+）。 */
    private func cylIsInMinimizedBar() -> Bool {
        var view = superview
        while let candidate = view {
            if let tabBar = candidate as? CYLTabBar {
                return tabBar.cylTabBarShowsMinimizedBar()
            }
            view = candidate.superview
        }
        return false
    }

    /**
     * [EN] Issue #636: the moved title in the tab item under the plus button (a new placeholder doesn't have it yet). The stand-in
     *      shares the tab item with the plus button.
     * [CN] 在 PlusButton 下方的 TabBarItem 中显示移过去的标题（新的占位控制器还没有标题）。替身与 PlusButton 共用 TabBarItem。
     */
    private func cylUpdateTitleInTabBarItem() {
        guard let movedTitle = cylPlusButtonStorage.movedTitle, !movedTitle.isEmpty, !cylIsInPlatterSelectedLayer(),
              let tabBarItem = cylViewControllerOfTabBarItem()?.tabBarItem, tabBarItem.title != movedTitle else {
            return
        }
        tabBarItem.title = movedTitle
    }

    /**
     * FIX: issue #636, issue #601
     * [EN] With the title in the tab item, the center (in the plus button's superview) that puts the image's bottom edge the measured
     *      distance above the tab titles' center line, and on the vertical center line of its own title. Titles of the normal layer
     *      only. Returns `center` in any other case (the vertical and the minimized bar included), or while the titles are not laid out.
     * [CN] 标题由 TabBarItem 显示时，PlusButton 在其父视图中的中心：图片底边位于 Tab 标题中心线上方测得的距离处，并与它自己的标题竖向中心线对齐。只取普通图层
     *      中的标题。其他情况（包括竖向栏与缩小的 TabBar），或标题尚未布局时，原样返回 `center`。
     */
    @objc(cyl_alignedCenterForCenter:)
    func cylAlignedCenter(forCenter center: CGPoint) -> CGPoint {
        guard let container = superview, let imageView, let imageSuperview = imageView.superview,
              let imageBottomToTitle = cylPlusButtonStorage.imageBottomToTitle, !cylIsInPlatterSelectedLayer(),
              cylShowsTitleInTabBarItem(), !cylIsInVerticalBar(), !cylIsInMinimizedBar() else {
            return center
        }
        var center = center
        var imageFrame = imageSuperview.convert(imageView.frame, to: self)
        if cylPlusButtonStorage.isMadeWithImageAndTitle {
            imageFrame = cylImageAndTitleFrames().image
        }
        let imageOffsetX = imageFrame.midX - bounds.midX
        let imageOffsetY = imageFrame.midY - bounds.midY
        // [EN] Its own title first (the tab item's), else the other tab titles, which share its center line.
        // [CN] 优先用它自己的标题（TabBarItem 的），没有时用其他 Tab 标题（中心线相同）。
        let ownTitleLabel = cylOwnTitleLabelInTabBarItem(nearX: center.x, in: container)
        let itemTitleLabel = ownTitleLabel ?? cylTabBarItemTitleLabels().first { cylIsViewInNormalTabLayer($0) }
        if let itemTitleLabel, let itemTitleSuperview = itemTitleLabel.superview {
            itemTitleSuperview.layoutIfNeeded()
            let itemTitleCenterY = itemTitleSuperview.convert(itemTitleLabel.center, to: container).y
            // [EN] With the image's current height, so a later or replaced image keeps its bottom edge. [CN] 使用图片当前的高度。
            let imageToTitle = imageBottomToTitle + imageFrame.height * 0.5
            center.y = itemTitleCenterY - imageToTitle - imageOffsetY
        }
        if let ownTitleLabel, let ownTitleSuperview = ownTitleLabel.superview {
            center.x = ownTitleSuperview.convert(ownTitleLabel.center, to: container).x - imageOffsetX
        }
        return center
    }

    /**
     * FIX: issue #601
     * [EN] The tab item's label that shows the plus button's title, in the normal layer, near `x`: first in the tab button of the
     *      plus button's slot, else the nearest such label in the tab bar, none farther than half its tab button's width.
     * [CN] 普通图层中显示 PlusButton 标题、且靠近 `x` 的 TabBarItem 标签：先在 PlusButton 的 slot 对应的 Tab 按钮中查找，否则取 TabBar 中最近的此类标签，
     *      距离不超过其 Tab 按钮宽度的一半。
     */
    private func cylOwnTitleLabelInTabBarItem(nearX x: CGFloat, in container: UIView) -> UILabel? {
        guard let movedTitle = cylPlusButtonStorage.movedTitle, !movedTitle.isEmpty,
              let systemTabBar = cylPlusButtonSystemTabBar(of: superview) else {
            return nil
        }
        if let slotLabel = cylTitleLabel(movedTitle, inSlotTabButtonNearX: x, in: container) {
            return slotLabel
        }
        var nearestLabel: UILabel?
        var nearestDistance = CGFloat.greatestFiniteMagnitude
        var views: [UIView] = [systemTabBar]
        while !views.isEmpty {
            let view = views.removeFirst()
            // [EN] Not the plus button, nor anything in the selected layer. [CN] 跳过 PlusButton 及选中图层中的一切。
            if view === self || view.cylIsPlatterSelectedContentView() {
                continue
            }
            if let label = view as? UILabel {
                if label.text == movedTitle, label.window != nil, let tabButton = cylTabButton(ofTabBarItemTitleLabel: label),
                   cylIsViewInNormalTabLayer(label), let labelSuperview = label.superview {
                    let distance = abs(labelSuperview.convert(label.center, to: container).x - x)
                    if distance <= tabButton.bounds.width * 0.5 && distance < nearestDistance {
                        nearestLabel = label
                        nearestDistance = distance
                    }
                }
                continue
            }
            views.append(contentsOf: view.subviews)
        }
        return nearestLabel
    }

    /**
     * [EN] The label showing `title` in the normal-layer tab button of the plus button's slot, within half that button's width of
     *      `x`; nil when that button is not known, not in the normal layer, or has no such label.
     * [CN] PlusButton 的 slot 在普通图层中的 Tab 按钮里显示 `title` 的标签，且与 `x` 的距离不超过该按钮宽度的一半；该按钮未知、不在普通图层或没有该标签时
     *      返回 nil。
     */
    private func cylTitleLabel(_ title: String, inSlotTabButtonNearX x: CGFloat, in container: UIView) -> UILabel? {
        guard let slotTabButton = cylViewControllerOfTabBarItem()?.tabBarItem.cyl_tabButton, slotTabButton.window != nil,
              slotTabButton !== self else {
            return nil
        }
        if CYLConstants.isLiquidGlassActive() && !slotTabButton.cylIsPlatterNormalControl() {
            return nil
        }
        var views: [UIView] = [slotTabButton]
        while !views.isEmpty {
            let view = views.removeFirst()
            if view === self || view.cylIsPlatterSelectedContentView() {
                continue
            }
            if let label = view as? UILabel {
                if label.text == title, let labelSuperview = label.superview {
                    let distance = abs(labelSuperview.convert(label.center, to: container).x - x)
                    return distance <= slotTabButton.bounds.width * 0.5 ? label : nil
                }
                continue
            }
            views.append(contentsOf: view.subviews)
        }
        return nil
    }

    /**
     * FIX: issue #601
     * [EN] Whether `view` is in the normal layer of the tab buttons: under no Liquid Glass selected layer, and in a tab button of the
     *      normal layer. Always YES without Liquid Glass.
     * [CN] `view` 是否位于 Tab 按钮的普通图层：不在液态玻璃的选中图层之下，且位于普通图层的 Tab 按钮中。非液态玻璃时总是 YES。
     */
    private func cylIsViewInNormalTabLayer(_ view: UIView) -> Bool {
        guard CYLConstants.isLiquidGlassActive() else { return true }
        var ancestor = view.superview
        while let candidate = ancestor {
            if candidate.cylIsPlatterSelectedContentView() {
                return false
            }
            ancestor = candidate.superview
        }
        return cylTabButton(ofTabBarItemTitleLabel: view)?.cylIsPlatterNormalControl() ?? false
    }

    /**
     * [EN] Keeps the stand-in on the plus button's position (another view hierarchy) whenever the plus button moves.
     * [CN] PlusButton 每次移动时，让替身（位于另一个视图层级）保持在 PlusButton 的位置。
     */
    @objc(cyl_moveSelectedContentViewWithPlusButton)
    func cylMoveSelectedContentViewWithPlusButton() {
        if cylStandInFollowsPlusButton() {
            cylPlaceSelectedContentView()
        }
        // [EN] Every tab bar layout pass, also after the selection moved. [CN] TabBar 每次布局都执行，包括选中项改变之后。
        cylUpdateLiquidGlassMask()
    }

    /** [EN] Puts the stand-in in place (`cylPlusButtonCenterOfStandIn()`). [CN] 放置替身。 */
    @objc(cyl_placeSelectedContentView)
    func cylPlaceSelectedContentView() {
        guard let selectedContentView = cylPlusButtonStorage.selectedContentView, selectedContentView.superview != nil,
              superview != nil, selectedContentView !== self else {
            return
        }
        selectedContentView.layoutIfNeeded()
        let center = cylPlusButtonCenterOfStandIn(self, selectedContentView)
        if center != selectedContentView.center {
            selectedContentView.center = center
        }
        cylUpdateLiquidGlassMask()
    }

    // MARK: The lens mask (off)

    /**
     * [EN] While UIKit's Liquid Glass gesture presses or drags, the lens can leave the plus slot while the plus page is still
     *      selected: the mask is off for the whole gesture, and checked again 0.45 s after it ends.
     * [CN] 系统液态玻璃手势按压或拖动期间，放大镜可能在 PlusButton 页面仍选中时离开其位置：整个手势期间关闭遮罩，手势结束 0.45 秒后再判断。
     */
    @objc(cyl_setLiquidGlassLensMaskSuspended:)
    func cylSetLiquidGlassLensMaskSuspended(_ suspended: Bool) {
        let storage = cylPlusButtonStorage
        guard storage.isLensMaskSuspended != suspended else { return }
        storage.isLensMaskSuspended = suspended
        cylUpdateLiquidGlassMask()
        if suspended {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.cylUpdateLiquidGlassMask()
        }
    }

    /**
     * [EN] Liquid Glass, the plus button selected with its stand-in in the lens: the real button's title (never the icon) is masked
     *      out under the lens, only with `+alignsTitleWithTabBarItemTitles`.
     *      TODO (2026-11-12, docs/Liquid-Glass-Robustness.md "Task log"): OFF. It runs only when the Swift compilation condition
     *      `CYL_PLUS_BUTTON_LENS_MASK_ENABLED` is set (the Objective-C macro of the same name before step 52); on any plus button
     *      bug, test with it off first (AGENTS.md). A mask here once cut the plus button in two when the lens was dragged away.
     * [CN] 液态玻璃下 PlusButton 选中、替身显示在放大镜中时：在放大镜下遮住真实按钮的标题（从不遮住图标），仅在 `+alignsTitleWithTabBarItemTitles` 时生效。
     *      TODO（2026-11-12，docs/Liquid-Glass-Robustness.md「任务记录」）：关闭。只有设置 Swift 编译条件 `CYL_PLUS_BUTTON_LENS_MASK_ENABLED`（第 52 步之前为
     *      同名 Objective-C 宏）时才执行；PlusButton 出现任何 bug 时，先关闭它再测试（AGENTS.md）。这里的遮罩曾在拖走放大镜时把 PlusButton 切成两半。
     */
    @objc(cyl_updateLiquidGlassMask)
    func cylUpdateLiquidGlassMask() {
        #if CYL_PLUS_BUTTON_LENS_MASK_ENABLED
        cylApplyLiquidGlassLensMask()
        #endif
    }

    #if CYL_PLUS_BUTTON_LENS_MASK_ENABLED
    /**
     * [EN] Whether the Liquid Glass lens, as drawn now (its presentation layer), is centered on `tabButton` (within 2 pt). YES when
     *      no lens view is found.
     * [CN] 当前显示的液态玻璃放大镜是否居中于 `tabButton`（误差 2pt 以内）。找不到放大镜视图时返回 YES。
     */
    private func cylLensIsOnTabButton(_ tabButton: UIView) -> Bool {
        guard let platter = tabButton.superview?.superview,
              let lens = platter.subviews.first(where: { NSStringFromClass(type(of: $0)).contains("LiquidLens") }) else {
            return true
        }
        let drawn = lens.layer.presentation() ?? lens.layer
        let lensFrame = platter.layer.convert(drawn.frame, from: drawn.superlayer ?? platter.layer)
        let slotFrame = tabButton.convert(tabButton.bounds, to: platter)
        return abs(lensFrame.midX - slotFrame.midX) < 2
    }

    private func cylApplyLiquidGlassLensMask() {
        if cylPlusButtonStorage.isLensMaskSuspended {
            if layer.mask?.name == cylPlusButtonLensMaskName {
                layer.mask = nil
            }
            return
        }
        let standIn = cylPlusButtonStorage.selectedContentView
        let standInTabButton = standIn?.cyl_insertedForTabControl ?? (standIn?.superview as? UIControl)
        // [EN] The plus button's own `selected` flag stays NO while its page is selected: ask the tab bar controller.
        // [CN] PlusButton 的页面被选中时，按钮自身的 `selected` 仍为 NO：以 TabBarController 的选中为准。
        let plusPage = CYLPlusButton.cylPlusChildViewControllerValue(forOwner: self)
        let selectedPage = cylOwningTabBarController()?.selectedViewController
        let plusPageSelected = plusPage != nil && (selectedPage === plusPage || (selectedPage != nil && selectedPage === plusPage?.navigationController))
        var masks = plusPageSelected && standIn != nil && standIn !== self && standIn?.window != nil && standIn?.window === window &&
            standIn?.isHidden == false && standInTabButton != nil && !cylIsInPlatterSelectedLayer() && cylPlusButtonIsInLiquidGlassTabBar(self)
        // [EN] Only mask once the lens sits on the plus slot; until then check again every 0.1 s.
        // [CN] 只有放大镜停在 PlusButton 的位置上时才遮住；在此之前每 0.1 秒重新判断。
        if masks, let standInTabButton, !cylLensIsOnTabButton(standInTabButton) {
            masks = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.cylUpdateLiquidGlassMask()
            }
        }
        // [EN] A mask the app set itself is kept. [CN] 保留 App 自己设置的遮罩。
        let ownsMask = layer.mask == nil || layer.mask?.name == cylPlusButtonLensMaskName
        var hidden = CGRect.null
        if masks && ownsMask {
            layoutIfNeeded()
            if let titleLabel, !(titleLabel.text ?? "").isEmpty, !titleLabel.isHidden, titleLabel.alpha > 0,
               cylAlignsTitleWithTabBarItemTitles() {
                let title = titleLabel.convert(titleLabel.bounds, to: self)
                if !title.isEmpty {
                    hidden = title.insetBy(dx: -2, dy: -2)
                }
            }
        }
        if hidden.isNull {
            if ownsMask && layer.mask != nil {
                layer.mask = nil
            }
            return
        }
        let visible = bounds.insetBy(dx: -bounds.width, dy: -bounds.height)
        let path = UIBezierPath(rect: visible)
        path.append(UIBezierPath(rect: hidden))
        let mask = (layer.mask as? CAShapeLayer) ?? {
            let newMask = CAShapeLayer()
            newMask.name = cylPlusButtonLensMaskName
            newMask.fillRule = .evenOdd
            layer.mask = newMask
            return newMask
        }()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.frame = bounds
        mask.path = path.cgPath
        CATransaction.commit()
    }
    #endif

    /** [EN] Called by `-setSelected:` after super: the glass moves to or away from the plus button. [CN] 由 `-setSelected:` 在 super 之后调用。 */
    @objc(cyl_plusButtonDidSetSelected)
    func cylPlusButtonDidSetSelected() {
        cylUpdateLiquidGlassMask()
    }

    /** [EN] See `+alignsTitleWithTabBarItemTitles`. [CN] 见 `+alignsTitleWithTabBarItemTitles`。 */
    private func cylAlignTitleWithTabBarItemTitlesIfNeeded() {
        guard cylAlignsTitleWithTabBarItemTitles() else { return }
        cylRestoreTitleFromTabBarItemIfNeeded()
        if cylShowsTitleInTabBarItem() {
            cylLayOutForTitleInTabBarItem()
            return
        }
        if (currentTitle ?? "").isEmpty && (currentAttributedTitle?.length ?? 0) == 0 {
            return
        }
        let itemTitleLabels = cylTabBarItemTitleLabels()
        guard let itemTitleLabel = itemTitleLabels.first else { return }
        cylObserveAppearance(ofTabBarItemTitleLabel: itemTitleLabel)
        let colors = cylTitleColors(ofTabBarItemTitleLabels: itemTitleLabels)
        if cylApplyTitleFont(itemTitleLabel.font, normalColor: colors.normal, selectedColor: colors.selected) {
            // [EN] The title's size changes with the font: room for it, then align it after the next layout.
            // [CN] 标题尺寸随字体变化：先留出空间，下次布局后再对齐。
            cylGrowToFitContentIfNeeded()
            return
        }
        guard let titleLabel, let titleSuperview = titleLabel.superview, cylIsVisibleView(titleLabel, upTo: self),
              let itemTitleSuperview = itemTitleLabel.superview else {
            return
        }
        // [EN] The plus button can be laid out before the tab button whose title it follows: finish that layout first.
        // [CN] PlusButton 可能先于它所跟随标题的 Tab 按钮布局：先完成那次布局。
        itemTitleSuperview.layoutIfNeeded()
        let itemTitleCenter = itemTitleSuperview.convert(itemTitleLabel.center, to: titleSuperview)
        // [EN] Recorded for the layout of `+cyl_plusButtonWithImage:…`; a new line lays the button out again, once.
        // [CN] 供 `+cyl_plusButtonWithImage:…` 的布局使用；线变化时重新布局一次。
        if titleSuperview === self {
            let storage = cylPlusButtonStorage
            if storage.alignedTitleCenterY.map({ abs($0 - itemTitleCenter.y) >= 0.5 }) ?? true {
                storage.alignedTitleCenterY = itemTitleCenter.y
                setNeedsLayout()
            }
        }
        let titleCenter = titleLabel.center
        if abs(titleCenter.y - itemTitleCenter.y) < 0.5 {
            return
        }
        titleLabel.center = CGPoint(x: titleCenter.x, y: itemTitleCenter.y)
        // [EN] With UIButtonConfiguration the title sits in a container that clips to the button: let those containers show it.
        // [CN] 使用 UIButtonConfiguration 时标题位于裁剪到按钮的容器中：让这些容器显示它。
        var view: UIView? = titleSuperview
        while let container = view, container !== self {
            let titleFrame = titleSuperview.convert(titleLabel.frame, to: container)
            if container.clipsToBounds && !container.bounds.contains(titleFrame) {
                container.clipsToBounds = false
            }
            view = container.superview
        }
    }

    /**
     * [EN] Gives the title the tab item titles' font and colors (`normalColor` unselected, `selectedColor` selected; nil keeps the
     *      one applied before), with or without `UIButtonConfiguration`. Returns YES when something changed.
     * [CN] 让标题使用 TabBarItem 标题的字体和颜色（未选中为 `normalColor`，选中为 `selectedColor`；nil 保留之前的颜色），支持使用与未使用
     *      `UIButtonConfiguration` 的按钮。有变化时返回 YES。
     */
    private func cylApplyTitleFont(_ font: UIFont?, normalColor: UIColor?, selectedColor: UIColor?) -> Bool {
        let storage = cylPlusButtonStorage
        let applied = storage.titleStyle
        let titleFont = font ?? applied?["font"] as? UIFont
        let appliedNormal = applied?["normal"] as? UIColor
        let selectedTitleColor = selectedColor ?? applied?["selected"] as? UIColor ?? normalColor ?? appliedNormal
        // [EN] The stand-in in the selected layer is always shown selected. [CN] 选中图层中的替身总是显示为选中。
        let titleColor = cylIsInPlatterSelectedLayer() ? selectedTitleColor : (normalColor ?? appliedNormal)
        guard let titleFont, let titleColor, let selectedTitleColor else { return false }
        let style: NSDictionary = ["font": titleFont, "normal": titleColor, "selected": selectedTitleColor]
        if let applied, style.isEqual(to: applied as! [AnyHashable: Any]) {
            return false
        }
        storage.titleStyle = style
        if var configuration = self.configuration {
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] attributes in
                var titleAttributes = attributes
                titleAttributes.font = titleFont
                titleAttributes.foregroundColor = (self?.isSelected ?? false) ? selectedTitleColor : titleColor
                return titleAttributes
            }
            self.configuration = configuration
            return true
        }
        if storage.originalTitleFont == nil, let currentFont = titleLabel?.font {
            storage.originalTitleFont = currentFont
        }
        titleLabel?.font = titleFont
        setTitleColor(titleColor, for: .normal)
        setTitleColor(selectedTitleColor, for: .selected)
        setTitleColor(selectedTitleColor, for: [.selected, .highlighted])
        setNeedsLayout()
        return true
    }

    /**
     * [EN] Every visible, non-empty tab item title in the tab bar the plus button is in, in view order.
     * [CN] PlusButton 所在 TabBar 中所有可见、非空的 TabBarItem 标题，按视图顺序。
     */
    private func cylTabBarItemTitleLabels() -> [UILabel] {
        let flatDesignTabBarClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBar")
        var tabBar = superview
        while let candidate = tabBar, !(candidate is UITabBar), !(flatDesignTabBarClass.map { candidate.isKind(of: $0) } ?? false) {
            tabBar = candidate.superview
        }
        var labels: [UILabel] = []
        if let tabBar {
            cylCollectTabBarItemTitleLabels(in: tabBar, tabBar: tabBar, into: &labels)
        }
        return labels
    }

    private func cylCollectTabBarItemTitleLabels(in view: UIView, tabBar: UIView, into labels: inout [UILabel]) {
        for subview in view.subviews where subview !== self && !subview.isHidden && subview.alpha >= 0.01 {
            if let label = subview as? UILabel, cylIsTabBarItemTitleLabel(label, tabBar: tabBar) {
                labels.append(label)
                continue
            }
            cylCollectTabBarItemTitleLabels(in: subview, tabBar: tabBar, into: &labels)
        }
    }

    /**
     * [EN] The colors the tab item titles are shown in. Liquid Glass: the normal layer's titles in the system label color, the
     *      selected layer's in the selected color. The system tab bar and the Flat style: the most common color is the normal one,
     *      the selected one is a title's whose tab button is selected, else any other color. nil when it cannot be told.
     * [CN] TabBarItem 标题实际显示的颜色。液态玻璃：普通层标题为系统 label 颜色，选中层为选中颜色。系统 TabBar 与扁平样式：出现最多的颜色为未选中颜色，
     *      选中颜色取所在按钮为选中状态的标题颜色，否则取其他颜色。无法判断时为 nil。
     */
    private func cylTitleColors(ofTabBarItemTitleLabels labels: [UILabel]) -> (normal: UIColor?, selected: UIColor?) {
        if CYLConstants.isLiquidGlassActive(), cylPlusButtonSystemTabBar(of: superview) != nil {
            let normalColor = cylColor(.label, resolvedFor: labels.first)
            let selectedLabel = labels.first { cylTabButton(ofTabBarItemTitleLabel: $0)?.cylIsPlatterSelectedControl() ?? false }
            return (normalColor, selectedLabel.flatMap { cylShownTextColor(of: $0) })
        }
        let colors = NSCountedSet()
        var shownColors: [(label: UILabel, color: UIColor)] = []
        for label in labels {
            if let color = cylShownTextColor(of: label) {
                colors.add(color)
                shownColors.append((label, color))
            }
        }
        var mostCommonColor: UIColor?
        for case let color as UIColor in colors where mostCommonColor == nil || colors.count(for: color) > colors.count(for: mostCommonColor!) {
            mostCommonColor = color
        }
        var selectedColor: UIColor?
        for (label, color) in shownColors where !color.isEqual(mostCommonColor) &&
            (selectedColor == nil || (cylTabButton(ofTabBarItemTitleLabel: label)?.isSelected ?? false)) {
            selectedColor = color
        }
        return (mostCommonColor, selectedColor)
    }

    /**
     * [EN] The label's text color as it is drawn. A tint color placeholder resolves against the view that draws it: use the
     *      label's tint instead.
     * [CN] 标签实际绘制的文字颜色。tint 颜色占位符按绘制它的视图解析：改用标签的 tint。
     */
    private func cylShownTextColor(of label: UILabel) -> UIColor? {
        var color: UIColor? = label.textColor
        if let textColor = color, NSStringFromClass(type(of: textColor)).contains("TintColor") {
            color = label.tintColor
        }
        return cylColor(color, resolvedFor: label)
    }

    /**
     * [EN] The color as the label shows it: Liquid Glass gives the tab content its own light or dark appearance.
     * [CN] 标签显示的颜色：液态玻璃为 Tab 内容设置自己的浅色或深色外观。
     */
    private func cylColor(_ color: UIColor?, resolvedFor label: UILabel?) -> UIColor? {
        guard let color else { return nil }
        guard let label else { return color }
        return color.resolvedColor(with: label.traitCollection)
    }

    /**
     * [EN] Liquid Glass switches the tab content between light and dark without laying the plus button out: follow the reference
     *      title's appearance (iOS 17+).
     * [CN] 液态玻璃根据玻璃后面的内容切换 Tab 内容的浅色与深色，但不会重新布局 PlusButton：跟随参考标题的外观（iOS 17+）。
     */
    private func cylObserveAppearance(ofTabBarItemTitleLabel label: UILabel) {
        guard #available(iOS 17.0, *) else { return }
        let storage = cylPlusButtonStorage
        if storage.observedTitleLabel === label {
            return
        }
        storage.observedTitleLabel = label
        label.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: UILabel, _: UITraitCollection) in
            self?.setNeedsLayout()
        }
    }

    /** [EN] Whether the view is in Liquid Glass's selected layer, at any depth. [CN] 视图是否位于液态玻璃的选中图层中（任意层级）。 */
    private func cylIsInPlatterSelectedLayer() -> Bool {
        var view = superview
        while let candidate = view {
            if candidate.cylIsPlatterSelectedContentView() {
                return true
            }
            view = candidate.superview
        }
        return false
    }

    /** [EN] The tab button a tab item title belongs to. [CN] TabBarItem 标题所属的 Tab 按钮。 */
    private func cylTabButton(ofTabBarItemTitleLabel label: UIView) -> UIControl? {
        label.superview?.cylNearestControl(below: nil)
    }

    /**
     * [EN] A tab item's title: has text, sits in a tab button that is not a placeholder nor a plus button, and is not a badge (a
     *      control's own label is not asked: its `cyl_badge` would create and pin an anchor during the plus button's layout).
     * [CN] TabBarItem 的标题：有文字，位于非占位、非 PlusButton 的 Tab 按钮中，且不是角标（不询问控件自身的标签：其 `cyl_badge` 会在 PlusButton 布局期间
     *      创建并约束锚点）。
     */
    private func cylIsTabBarItemTitleLabel(_ label: UILabel, tabBar: UIView) -> Bool {
        guard let text = label.text, !text.isEmpty, let labelSuperview = label.superview else { return false }
        if !(labelSuperview is UIControl), label === labelSuperview.cyl_badge {
            return false
        }
        guard let tabButton = labelSuperview.cylNearestControl(below: tabBar) else { return false }
        return !tabButton.cyl_isPlaceholder && !CYLPlusButton.cylPlusButtonIsPlusButtonView(tabButton)
    }

    private func cylIsVisibleView(_ view: UIView, upTo ancestor: UIView) -> Bool {
        var current: UIView? = view
        while let candidate = current, candidate !== ancestor {
            if candidate.isHidden || candidate.alpha < 0.01 {
                return false
            }
            current = candidate.superview
        }
        return true
    }

    // MARK: Layout of `+cyl_plusButtonWithImage:…`

    /** [EN] Called by `-layoutSubviews` after super. [CN] 由 `-layoutSubviews` 在 super 之后调用。 */
    @objc(cyl_plusButtonLayoutSubviews)
    func cylPlusButtonLayoutSubviews() {
        // [EN] Issue #91: keep the touchable area overlay on the button. [CN] 保持可点击区域覆盖层与按钮一致。
        if cylPlusButtonStorage.showsTouchableArea {
            cylUpdateTouchableAreaView()
        }
        if cylPlusButtonStorage.isMadeWithImageAndTitle {
            cylLayOutContentOnce { cylLayOutImageAndTitle() }
        }
        // [EN] Last: the mask follows the title's final frame. [CN] 最后执行：遮罩跟随标题的最终位置。
        cylUpdateLiquidGlassMask()
    }

    private func cylLayOutImageAndTitle() {
        let (imageFrame, titleFrame) = cylImageAndTitleFrames()
        imageView?.bounds = CGRect(origin: .zero, size: imageFrame.size)
        imageView?.center = CGPoint(x: imageFrame.midX, y: imageFrame.midY)
        titleLabel?.bounds = CGRect(origin: .zero, size: titleFrame.size)
        titleLabel?.center = CGPoint(x: titleFrame.midX, y: titleFrame.midY)
    }

    /**
     * [EN] The image above the title of `+cyl_plusButtonWithImage:…`, from the bounds and the title font alone, in the button's
     *      coordinates, so the result never depends on when it is measured. The image keeps its natural size. With the title
     *      aligned with the tab titles and kept in the button: the title on their line and the image right above it.
     * [CN] `+cyl_plusButtonWithImage:…` 中位于标题上方的图片：只由 bounds 与标题字体计算，坐标系为按钮，因此与测量时机无关。图片保持其原始尺寸。标题与
     *      Tab 标题对齐且留在按钮中时：标题位于其中心线上，图片紧挨在标题上方。
     */
    private func cylImageAndTitleFrames() -> (image: CGRect, title: CGRect) {
        let width = bounds.width
        let imageWidth = width * 0.7
        let imageHeight = imageWidth * 0.9
        let lineHeight = titleLabel?.font.lineHeight ?? 0
        let verticalMargin = (bounds.height - lineHeight - imageHeight) * 0.5
        var imageSize = image(for: .normal)?.size ?? .zero
        if imageSize.width <= 0 || imageSize.height <= 0 {
            imageSize = CGSize(width: imageWidth, height: imageHeight)
        }
        var imageCenter = CGPoint(x: width * 0.5, y: verticalMargin + imageHeight * 0.5)
        var titleCenterY = imageHeight + verticalMargin * 2 + lineHeight * 0.5 + 10
        if let alignedTitleCenterY = cylPlusButtonStorage.alignedTitleCenterY, !cylShowsTitleInTabBarItem() {
            titleCenterY = alignedTitleCenterY
            imageCenter.y = titleCenterY - lineHeight * 0.5 - cylPlusButtonImageToTitleSpacing - imageSize.height * 0.5
        }
        let imageFrame = CGRect(x: imageCenter.x - imageSize.width * 0.5, y: imageCenter.y - imageSize.height * 0.5,
                                width: imageSize.width, height: imageSize.height)
        return (imageFrame, CGRect(x: 0, y: titleCenterY - lineHeight * 0.5, width: width, height: lineHeight))
    }

    // MARK: Registration

    @objc(cyl_plusButtonRegister)
    class func cylPlusButtonRegister() {
        guard (self as AnyClass).conforms(to: CYLPlusButtonSubclassing.self) else { return }
        let classAPI = cylPlusButtonClass(self)
        let registration = CYLPlusButtonRegistration()
        registration.context = cylPlusButtonMatchedTabBarContext()
        registration.plusButtonClass = self
        let plusButton = classAPI.plusButton?() as? CYLPlusButton
        if (self as AnyObject).responds(to: #selector(CYLPlusButtonClassAPI.plusChildViewController)) {
            let plusChildViewController = classAPI.plusChildViewController?()
            registration.plusChildViewController = plusChildViewController
            plusChildViewController?.cyl_context = registration.context
            registration.plusButton = plusButton
            registration.plusButtonWidth = plusButton?.frame.width ?? 0
            if let plusButton {
                cylPlusButtonAddSelectViewControllerTarget(plusButton)
            }
            if let index = classAPI.indexOfPlusButtonInTabBar?() {
                // [EN] Not stored per context: `+indexForTabbarItemsCount:` returns the class's `+indexOfPlusButtonInTabBar`.
                // [CN] 不按 context 保存：`+indexForTabbarItemsCount:` 返回该类的 `+indexOfPlusButtonInTabBar`。
                CYLPlusButtonIndex = UInt(index)
            } else {
                #if DEBUG
                assertionFailure(cylLocalizedString("[DEBUG INFO] 如果你想使用 PlusChildViewController 样式，你必须同时在你自定义的 plusButton 中实现 `+indexOfPlusButtonInTabBar`，来指定 plusButton 的位置。"))
                #endif
            }
        } else {
            registration.plusButton = plusButton
            registration.plusButtonWidth = plusButton?.frame.width ?? 0
        }
        CYLPlusButtonRegistry.shared.withLock { registrations in
            registrations[registration.context] = registration
            cylPlusButtonMirrorLegacyGlobals(registration)
        }
    }

    @objc(cyl_plusButtonRemove)
    class func cylPlusButtonRemove() {
        var context: String? = cylPlusButtonMatchedTabBarContext()
        // [EN] `CYLPlusButton` itself has no `+tabBarContext`: remove the plus button the globals point at.
        // [CN] `CYLPlusButton` 本身没有 `+tabBarContext`：移除全局变量指向的 PlusButton。
        let latestContext = CYLPlusButtonRegistry.shared.latestContext
        if CYLPlusButtonRegistry.shared.registration(for: context) == nil && self == CYLPlusButton.self && latestContext != nil {
            context = latestContext
        }
        cylPlusButtonRemove(forTabBarContext: context)
    }

    @objc(cyl_plusButtonRemoveForTabBarContext:)
    class func cylPlusButtonRemove(forTabBarContext tabBarContext: String?) {
        guard let tabBarContext else { return }
        let registry = CYLPlusButtonRegistry.shared
        let removedRegistration: CYLPlusButtonRegistration? = registry.withLock { registrations in
            guard let registration = registrations.removeValue(forKey: tabBarContext) else { return nil }
            if registry.latestContext == tabBarContext {
                cylPlusButtonMirrorLegacyGlobals(nil)
            }
            return registration
        }
        guard let registration = removedRegistration else { return }
        // [EN] The registered instances, and the copies made for the other tab bar controllers of this context.
        // [CN] 已注册的实例，以及为该 context 其他 TabBarController 创建的副本。
        var removed = registration.boundCopies.allObjects
        if let plusButton = registration.plusButton {
            removed.append(plusButton)
        }
        if let plusChildViewController = registration.plusChildViewController {
            removed.append(plusChildViewController)
        }
        for object in removed {
            if let view = object as? UIView {
                view.removeFromSuperview()
            } else if let plusChildViewController = object as? UIViewController {
                plusChildViewController.willMove(toParent: nil)
                plusChildViewController.view.removeFromSuperview()
                plusChildViewController.removeFromParent()
                plusChildViewController.cyl_plusViewControllerEverAdded = false
            }
        }
    }

    /**
     * [EN] The tap on a plus button with a plus child view controller: selects that page in the tab bar controller the button is
     *      in, else the most recently active one with its context, in any style (#650).
     * [CN] 点击带子控制器的 PlusButton：在按钮所在的 TabBarController（否则为该 context 最近活跃的那个）中选中该页面，任意样式（#650）。
     */
    @objc(cyl_plusButtonPlusChildViewControllerButtonClicked:)
    func cylPlusButtonPlusChildViewControllerButtonClicked(_ sender: UIButton) {
        if let shouldSelect = cylClass.shouldSelectPlusChildViewController?(), !shouldSelect {
            return
        }
        let context = CYLPlusButton.cylPlusButtonTabBarContext(forOwner: sender)
        var tabBarController = sender.cylOwningTabBarController()
        if tabBarController?.cyl_context != context {
            tabBarController = CYLTabBarController.cylTabBarController(forContext: context)
        }
        // [EN] That controller's own plus child view controller. [CN] 该控制器自己的 PlusButton 子控制器。
        guard let tabBarController,
              let plusChildViewController = CYLPlusButton.cylPlusChildViewControllerValue(forOwner: tabBarController),
              let index = tabBarController.viewControllers?.firstIndex(of: plusChildViewController) else {
            return
        }
        if let flatDesignTabBarClass = NSClassFromString("CYLFlatDesignTabBar"), let flatDesignTabBar = tabBarController.cyl_tabBar,
           flatDesignTabBar.isKind(of: flatDesignTabBarClass) {
            // FIX: issue #610 reported through `tabBarController:didSelectControl:` like the other styles, before selecting.
            // [CN] 与其他样式一样回调 `tabBarController:didSelectControl:`，先回调再选中。
            tabBarController.cylPrivate.cylFlatDesignReportDidSelectControl?(sender)
            unsafeBitCast(flatDesignTabBar as AnyObject, to: CYLPlusButtonFlatDesignTabBarAPI.self).setSelectedIndex(UInt(index))
            tabBarController.selectedViewController = plusChildViewController
            return
        }
        tabBarController.selectedIndex = index
        // FIX: issue #594
        // [EN] `-setSelectedIndex:` already selected the plus button and reported it when the tab bar controller has a plus button
        //      with a child view controller; reporting again would report every tap twice.
        // [CN] TabBarController 有带子控制器的 PlusButton 时，`-setSelectedIndex:` 已经选中并上报了 PlusButton；再次上报会让每次点击上报两次。
        let selectedBySetSelectedIndex = tabBarController.cylPlusButtonControlIfSelectingPlusChildViewController(plusChildViewController) === sender
        if !selectedBySetSelectedIndex && cylControlReportsTapsEntryPoint(sender) {
            sender.isSelected = true
            tabBarController.tabChanged(to: sender)
        }
    }

    @objc(cyl_plusButtonAddSelectViewControllerTarget:)
    class func cylPlusButtonAddSelectViewControllerTarget(_ plusButton: UIButton) {
        var target: AnyObject = self
        var selectorNames = plusButton.actions(forTarget: target, forControlEvent: .touchUpInside) ?? []
        if selectorNames.isEmpty {
            target = plusButton
            selectorNames = plusButton.actions(forTarget: target, forControlEvent: .touchUpInside) ?? []
        }
        // [EN] FIX: issue #152 — keep the tab bar item gesture action. [CN] 保留 TabBarItem 手势的事件。
        for name in selectorNames where name != "cyl_tabBarItemGestureTouchUpInside" {
            plusButton.removeTarget(target, action: NSSelectorFromString(name), for: .touchUpInside)
        }
        plusButton.addTarget(plusButton, action: NSSelectorFromString("plusChildViewControllerButtonClicked:"), for: .touchUpInside)
    }

    // MARK: Position in the tab bar

    @objc(isLayoutCentered)
    func cylIsLayoutCentered() -> Bool {
        cylConstantOfPlusButtonCenterYOffset(forTabBarHeight: cylTabBarController?.tabBar.cylBoundsSize().height ?? 0) == 0 &&
            cylMultiplierOfTabBarHeight(cylTabBarController?.tabBar.cylBoundsSize().height ?? 0, plusButtonHeight: frame.height) == 0.5
    }

    @objc(cyl_plusButtonMultiplierOfTabBarHeight:)
    func cylPlusButtonMultiplierOfTabBarHeight(_ tabBarHeight: CGFloat) -> CGFloat {
        cylMultiplierOfTabBarHeight(tabBarHeight, plusButtonHeight: frame.height)
    }

    /** [EN] Liquid Glass and no title: the plus button replaces the whole tab item. [CN] 液态玻璃下没有标题：PlusButton 替换整个 TabBarItem。 */
    private func cylHasNoTitleInLiquidGlass() -> Bool {
        guard CYLConstants.isLiquidGlassActive() else { return false }
        return (cylPlusButtonStorage.movedTitle ?? "").isEmpty && (currentTitle ?? "").isEmpty && (currentAttributedTitle?.length ?? 0) == 0
    }

    @objc(cyl_plusButtonAppliesCenterYOffsetWithoutTitle)
    func cylPlusButtonAppliesCenterYOffsetWithoutTitle() -> Bool {
        cylPlusButtonStorage.appliesCenterYOffsetWithoutTitle
    }

    @objc(cyl_plusButtonSetAppliesCenterYOffsetWithoutTitle:)
    func cylPlusButtonSetAppliesCenterYOffsetWithoutTitle(_ appliesCenterYOffsetWithoutTitle: Bool) {
        cylPlusButtonStorage.appliesCenterYOffsetWithoutTitle = appliesCenterYOffsetWithoutTitle
        superview?.setNeedsLayout()
    }

    /**
     * [EN] Centered on the tab item, the height methods ignored (see `cyl_appliesCenterYOffsetWithoutTitle`).
     * [CN] 居中于 TabBarItem，忽略高度相关的代理方法（见 `cyl_appliesCenterYOffsetWithoutTitle`）。
     */
    @objc(cyl_isCenteredWithoutTitle)
    func cylIsCenteredWithoutTitle() -> Bool {
        cylHasNoTitleInLiquidGlass() && !cylPlusButtonStorage.appliesCenterYOffsetWithoutTitle
    }

    private func cylMultiplierOfTabBarHeight(_ tabBarHeight: CGFloat, plusButtonHeight: CGFloat) -> CGFloat {
        if cylIsCenteredWithoutTitle() {
            return 0.5
        }
        if let multiplier = cylClass.multiplierOfTabBarHeight?(tabBarHeight) {
            return multiplier
        }
        if let multiplier = cylClass.multiplerInCenterY?() {
            return multiplier
        }
        if !CYLConstants.isLiquidGlassActive() {
            // [EN] The system tab bar (iOS 25 and earlier, and UI compatibility mode): center the plus button on the tab items, as the
            //      Flat style does. `cyl_boundsSize` already excludes the bottom safe area.
            // [CN] 系统 TabBar（iOS 25 及更早，以及 UI 兼容模式）：与扁平样式一样把 PlusButton 居中于 Tab item。`cyl_boundsSize` 已不含底部安全区。
            return 0.5
        }
        let heightDifference = plusButtonHeight - tabBarHeight
        if heightDifference < 0 {
            return 0.5
        }
        return (tabBarHeight * 0.5 - heightDifference * 0.5) / tabBarHeight
    }

    @objc(cyl_plusButtonConstantOfPlusButtonCenterYOffsetForTabBarHeight:)
    func cylConstantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        if cylIsCenteredWithoutTitle() {
            return 0
        }
        return cylClass.constantOfPlusButtonCenterYOffset?(forTabBarHeight: tabBarHeight) ?? 0
    }

    // MARK: Touchable area (issue #91, #202)

    @objc(touchableRect)
    func cylTouchableRect() -> CGRect {
        var rect = frame
        let scale = max(cylPlusButtonStorage.touchableAreaScale, 1)   // 0 (never set) and values below 1 count as 1
        if scale > 1 {
            rect = rect.insetBy(dx: -rect.width * (scale - 1) / 2, dy: -rect.height * (scale - 1) / 2)
        }
        let outsets = cylPlusButtonStorage.touchableAreaOutsets
        return rect.inset(by: UIEdgeInsets(top: -outsets.top, left: -outsets.left, bottom: -outsets.bottom, right: -outsets.right))
    }

    @objc(cyl_plusButtonHitTestInteractiveSubview:withEvent:)
    func cylPlusButtonHitTestInteractiveSubview(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || alpha < 0.01 || !isUserInteractionEnabled {
            return nil
        }
        // [EN] Front to back; each subview hit-tests in its own bounds. [CN] 从前往后；每个子视图在自身范围内做 hitTest。
        for subview in subviews.reversed() {
            if let hitView = subview.hitTest(subview.convert(point, from: self), with: event),
               cylPlusButtonSubviewTakesTouches(hitView, self) {
                return hitView
            }
        }
        return nil
    }

    @objc(cyl_plusButtonTouchableRectInView:)
    func cylPlusButtonTouchableRect(in view: UIView?) -> CGRect {
        let rect = cylTouchableRect()
        guard let view, let superview, superview !== view else { return rect }
        return superview.convert(rect, to: view)
    }

    /**
     * [EN] Called by `-pointInside:withEvent:` when super says NO: the whole touchable area counts as inside, or a tap in the extra
     *      area ended as `TouchUpOutside`.
     * [CN] 由 `-pointInside:withEvent:` 在 super 返回 NO 时调用：整个可点击区域都算作按钮内部，否则点在扩展区域内会变成 `TouchUpOutside`。
     */
    @objc(cyl_plusButtonTouchableAreaContainsPoint:)
    func cylPlusButtonTouchableAreaContains(_ point: CGPoint) -> Bool {
        guard let superview else { return false }
        return convert(cylTouchableRect(), from: superview).contains(point)
    }

    @objc(cyl_plusButtonReportsTapsToDelegate)
    func cylPlusButtonReportsTapsToDelegate() -> Bool {
        cylPlusButtonStorage.reportsTapsToDelegate ?? !cylControlIsSelectionLockedEntryPoint(self)
    }

    @objc(cyl_plusButtonSetReportsTapsToDelegate:)
    func cylPlusButtonSetReportsTapsToDelegate(_ reportsTapsToDelegate: Bool) {
        cylPlusButtonStorage.reportsTapsToDelegate = reportsTapsToDelegate
    }

    @objc(cyl_plusButtonTouchableAreaOutsets)
    func cylPlusButtonTouchableAreaOutsets() -> UIEdgeInsets {
        cylPlusButtonStorage.touchableAreaOutsets
    }

    @objc(cyl_plusButtonSetTouchableAreaOutsets:)
    func cylPlusButtonSetTouchableAreaOutsets(_ touchableAreaOutsets: UIEdgeInsets) {
        cylPlusButtonStorage.touchableAreaOutsets = touchableAreaOutsets
        cylUpdateTouchableAreaView()
    }

    @objc(cyl_plusButtonTouchableAreaScale)
    func cylPlusButtonTouchableAreaScale() -> CGFloat {
        max(cylPlusButtonStorage.touchableAreaScale, 1)
    }

    @objc(cyl_plusButtonSetTouchableAreaScale:)
    func cylPlusButtonSetTouchableAreaScale(_ touchableAreaScale: CGFloat) {
        cylPlusButtonStorage.touchableAreaScale = max(touchableAreaScale, 1)
        cylUpdateTouchableAreaView()
    }

    @objc(cyl_plusButtonShowsTouchableArea)
    func cylPlusButtonShowsTouchableArea() -> Bool {
        cylPlusButtonStorage.showsTouchableArea
    }

    @objc(cyl_plusButtonSetShowsTouchableArea:)
    func cylPlusButtonSetShowsTouchableArea(_ showsTouchableArea: Bool) {
        cylPlusButtonStorage.showsTouchableArea = showsTouchableArea
        cylUpdateTouchableAreaView()
    }

    @objc(cyl_plusButtonTouchableAreaColor)
    func cylPlusButtonTouchableAreaColor() -> UIColor? {
        cylPlusButtonStorage.touchableAreaColor
    }

    @objc(cyl_plusButtonSetTouchableAreaColor:)
    func cylPlusButtonSetTouchableAreaColor(_ touchableAreaColor: UIColor?) {
        cylPlusButtonStorage.touchableAreaColor = touchableAreaColor
        cylUpdateTouchableAreaView()
    }

    /**
     * [EN] Adds, moves or removes the overlay so it always covers `-touchableRect`.
     * [CN] 添加、移动或移除覆盖层，使其始终覆盖可点击区域。
     */
    private func cylUpdateTouchableAreaView() {
        let storage = cylPlusButtonStorage
        guard storage.showsTouchableArea, let superview else {
            storage.touchableAreaView?.removeFromSuperview()
            storage.touchableAreaView = nil
            return
        }
        let areaView = storage.touchableAreaView ?? {
            let view = UIView()
            view.isUserInteractionEnabled = false   // never takes a touch 不响应点击
            view.layer.borderWidth = 1
            view.accessibilityElementsHidden = true
            storage.touchableAreaView = view
            return view
        }()
        let color = storage.touchableAreaColor ?? UIColor.systemRed.withAlphaComponent(0.3)
        areaView.backgroundColor = color
        areaView.layer.borderColor = color.withAlphaComponent(1).cgColor
        if areaView.superview !== superview {
            areaView.removeFromSuperview()
            superview.insertSubview(areaView, belowSubview: self)
        }
        areaView.frame = cylTouchableRect()
        areaView.isHidden = isHidden || alpha < 0.01
    }

    /** [EN] Called by `-didMoveToSuperview` after super. [CN] 由 `-didMoveToSuperview` 在 super 之后调用。 */
    @objc(cyl_plusButtonDidMoveToSuperview)
    func cylPlusButtonDidMoveToSuperview() {
        cylUpdateTouchableAreaView()
        cylInstallLargeContentViewerInteractionIfNeeded()
        cylAddTabBarItemGestureTargetsIfNeeded()
    }

    /** [EN] Called by `-removeFromSuperview` before super. [CN] 由 `-removeFromSuperview` 在 super 之前调用。 */
    @objc(cyl_plusButtonWillRemoveFromSuperview)
    func cylPlusButtonWillRemoveFromSuperview() {
        cylPlusButtonStorage.touchableAreaView?.removeFromSuperview()
    }

    // MARK: Tab bar item gestures (issue #152)

    /**
     * [EN] Issue #152: the plus button reports its taps for the tab bar item gestures itself, the same way in every style. The
     *      actions only record and forward, and are added once.
     * [CN] Issue #152：PlusButton 自己为 TabBarItem 手势上报点击，所有样式方式一致。这些事件只记录与转发，只添加一次。
     */
    private func cylAddTabBarItemGestureTargetsIfNeeded() {
        if actions(forTarget: self, forControlEvent: .touchUpInside)?.contains("cyl_tabBarItemGestureTouchUpInside") == true {
            return
        }
        addTarget(self, action: #selector(cylTabBarItemGestureTouchDown), for: .touchDown)
        addTarget(self, action: #selector(cylTabBarItemGestureTouchUpInside), for: .touchUpInside)
        // [EN] The pressed animation (`CYLTabButtonAnimation`), played by the tab bar controller. [CN] 按下动画，由 TabBarController 播放。
        addTarget(self, action: #selector(cylTabButtonHighlightTouchDown), for: .touchDown)
        addTarget(self, action: #selector(cylTabButtonHighlightTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc(cyl_tabButtonHighlightTouchDown)
    func cylTabButtonHighlightTouchDown() {
        cylOwningTabBarController()?.cylTabButtonTouchDown(self)
    }

    @objc(cyl_tabButtonHighlightTouchUp)
    func cylTabButtonHighlightTouchUp() {
        cylOwningTabBarController()?.cylTabButtonTouchUp(self)
    }

    @objc(cyl_tabBarItemGestureTouchDown)
    func cylTabBarItemGestureTouchDown() {
        let storage = cylPlusButtonStorage
        storage.selectedViewControllerAtTouchDown = cylOwningTabBarController()?.selectedViewController
        storage.hasTouchDownForTabBarItemGesture = true
    }

    @objc(cyl_tabBarItemGestureTouchUpInside)
    func cylTabBarItemGestureTouchUpInside() {
        let storage = cylPlusButtonStorage
        let selectedViewController = storage.hasTouchDownForTabBarItemGesture ? storage.selectedViewControllerAtTouchDown : nil
        storage.hasTouchDownForTabBarItemGesture = false
        storage.selectedViewControllerAtTouchDown = nil
        cylOwningTabBarController()?.cylRecognizePlusButtonTap(self, selectedViewControllerAtTouchDown: selectedViewController)
    }

    // MARK: The stand-in in the selected layer

    @objc(getSnapshot)
    func cylGetSnapshot() -> UIImage? {
        let storage = cylPlusButtonStorage
        if let snapshot = storage.snapshot, let cgImage = snapshot.cgImage {
            return UIImage(cgImage: cgImage, scale: snapshot.scale, orientation: snapshot.imageOrientation)
        }
        storage.snapshot = cylTakeSnapshot()
        return storage.snapshot
    }

    /**
     * [EN] `+selectedContentView`: a new plus button of the class. Only the stand-in is shown highlighted (selected would draw the
     *      selected background); the registered plus button stayed highlighted before, and UIKit drew its image darkened.
     * [CN] `+selectedContentView`：该类新建的 PlusButton。只有替身以高亮状态显示（选中会绘制选中背景）；以前已注册的 PlusButton 也一直保持高亮，系统因此
     *      把它的图片画暗。
     */
    @objc(cyl_plusButtonClassSelectedContentView)
    class func cylPlusButtonClassSelectedContentView() -> UIButton? {
        let plusButton = cylPlusButtonClass(self).plusButton?() as? UIButton
        if let plusButton, cylControlReportsTapsEntryPoint(plusButton) {
            plusButton.isHighlighted = true
        }
        return plusButton
    }

    @objc(cyl_plusButtonSelectedContentView)
    func cylPlusButtonSelectedContentView() -> UIButton? {
        let storage = cylPlusButtonStorage
        if let selectedContentView = storage.selectedContentView {
            return selectedContentView
        }
        if let button = cylClass.selectedContentView?() {
            cylPlusButtonDrawImagesAsIs(button)
            cylPlusButtonHideStandInFromAccessibility(self, button)
            storage.selectedContentView = button
            // FIX: the plus button's stand-in kept the original image after a theme
            // [EN] Liquid Glass only. The class makes a new plus button with the app's original images: give it the images set since
            //      then (a theme restored at launch left the stand-in with the old image).
            // [CN] 仅液态玻璃。类方法新建的 PlusButton 使用 App 原来的图片：为它设置之后更新过的图片（启动时恢复的主题曾让替身保持旧图片）。
            if cylStandInShowsNormalImageOnly() {
                cylUpdateSelectedContentViewImage()
            } else if button !== self && cylPlusButtonIsInLiquidGlassTabBar(self) {
                if let image = storage.updatedImage {
                    button.setImage(image, for: .normal)
                    button.setImage(storage.updatedSelectedImage ?? image, for: .highlighted)
                }
                if let selectedImage = storage.updatedSelectedImage {
                    button.setImage(selectedImage, for: .selected)
                    button.setImage(selectedImage, for: .highlighted)
                }
            }
            cylShowRequestedBadgeIfNeeded()
            return button
        }
        let selectedContentView = UIButton(type: .custom)
        let classAPI = cylClass
        selectedContentView.setImage(cylPlusButtonOriginalImage(classAPI.contentImage?() ?? cylPlusButtonContentImage() ?? UIImage()), for: .normal)
        selectedContentView.setImage(cylPlusButtonOriginalImage(classAPI.selectedContentImage?() ?? cylPlusButtonSelectedContentImage() ?? UIImage()),
                                     for: .highlighted)
        selectedContentView.frame.size = bounds.size
        selectedContentView.contentMode = .center
        selectedContentView.imageView?.contentMode = .scaleAspectFit
        // FIX: issue #653 — placed by frame (see `CYLTabButtonLayoutTracker`), not by Auto Layout.
        selectedContentView.translatesAutoresizingMaskIntoConstraints = true
        selectedContentView.isUserInteractionEnabled = false
        selectedContentView.sizeToFit()
        if cylControlReportsTapsEntryPoint(self) {
            // [EN] Not selected, to avoid the selected background. [CN] 不使用 selected 以避免选中背景。
            selectedContentView.isHighlighted = true
        }
        cylPlusButtonHideStandInFromAccessibility(self, selectedContentView)
        storage.selectedContentView = selectedContentView
        cylUpdateSelectedContentViewImage()
        cylShowRequestedBadgeIfNeeded()
        return selectedContentView
    }

    @objc(cyl_plusButtonSetSelectedContentView:)
    func cylPlusButtonSetSelectedContentView(_ selectedContentView: UIButton?) {
        cylPlusButtonStorage.selectedContentView = selectedContentView
    }

    @objc(cyl_plusButtonTitle)
    func cylPlusButtonTitle() -> String? {
        if let movedTitle = cylPlusButtonStorage.movedTitle, !movedTitle.isEmpty {
            return movedTitle
        }
        if let currentTitle, !currentTitle.isEmpty {
            return currentTitle
        }
        return nil
    }

    @objc(cyl_plusButtonUpdateTitle:image:selectedImage:)
    func cylPlusButtonUpdate(title: String?, image: UIImage?, selectedImage: UIImage?) {
        // [EN] Also for the stand-in, which may be a plain UIButton. [CN] 替身可能是普通 UIButton，同样按原图绘制。
        let image = cylPlusButtonOriginalImage(image)
        let selectedImage = cylPlusButtonOriginalImage(selectedImage)
        let storage = cylPlusButtonStorage
        if let title {
            if storage.movedTitle != nil {
                // [EN] Shown by the tab item under the plus button (#636): its title changes, the layout follows (#729).
                // [CN] 由 PlusButton 下方的 TabBarItem 显示（#636）：修改其标题，布局随之更新（#729）。
                storage.movedTitle = title
                cylUpdateTitleInTabBarItem()
            } else {
                let hasSelectedTitle = self.title(for: .selected) != nil
                setTitle(title, for: .normal)
                if hasSelectedTitle {
                    setTitle(title, for: .selected)
                }
                if var configuration = self.configuration {
                    configuration.title = title
                    self.configuration = configuration
                }
                // [EN] A longer title widens the plus button, around the same center. [CN] 标题变长时加宽 PlusButton，中心不变。
                let fittingSize = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
                if fittingSize.width > bounds.width {
                    let center = self.center
                    bounds = CGRect(origin: .zero, size: CGSize(width: fittingSize.width, height: bounds.height))
                    self.center = center
                }
            }
        }
        // [EN] A stand-in that shows the normal image only is updated below. [CN] 只显示普通状态图片的替身在下面更新。
        let standIn = cylStandInShowsNormalImageOnly() ? nil : cylStandIn
        for button in [self] + (standIn.map { [$0] } ?? []) {
            if let image {
                button.setImage(image, for: .normal)
                // [EN] The stand-in is shown highlighted, with the selected look. [CN] 替身以高亮状态显示选中样式。
                button.setImage(button === self ? image : (selectedImage ?? image), for: .highlighted)
            }
            if let selectedImage {
                button.setImage(selectedImage, for: .selected)
                if button !== self {
                    button.setImage(selectedImage, for: .highlighted)
                }
            }
        }
        cylUpdateSelectedContentViewImage()
        if let image {
            storage.contentImage = image
            storage.updatedImage = image
        }
        if let selectedImage {
            storage.selectedContentImage = selectedImage
            storage.updatedSelectedImage = selectedImage
        }
        cylPlusButtonSetNeedsTitleAlignment()
        setNeedsLayout()
        superview?.setNeedsLayout()
    }

    @objc(cyl_plusButtonSetTabLabelHidden:)
    func cylPlusButtonSetTabLabelHidden(_ hidden: Bool) {
        guard CYLConstants.isLiquidGlassActive(),
              let plusButton = CYLPlusButton.cylPlusButton(forOwner: self),   // the plus button of this button's own context
              CYLPlusButton.cylPlusChildViewControllerValue(forOwner: self) != nil,
              !plusButton.cyl_keepShowingPlusButtonLabel,
              let tabLabel = plusButton.cylTabLabel(), !(tabLabel.text ?? "").isEmpty else {
            return
        }
        tabLabel.cylSetHidden(hidden)
        plusButton.cylPlusButtonSelectedContentView()?.cylTabLabel()?.cylSetHidden(!hidden)
    }

    @objc(cyl_plusButtonSelectedContentImage)
    func cylPlusButtonSelectedContentImage() -> UIImage? {
        let storage = cylPlusButtonStorage
        if storage.selectedContentImage == nil {
            storage.selectedContentImage = imageView?.image
        }
        return storage.selectedContentImage
    }

    @objc(cyl_plusButtonSetSelectedContentImage:)
    func cylPlusButtonSetSelectedContentImage(_ image: UIImage?) {
        cylPlusButtonStorage.selectedContentImage = image
    }

    @objc(cyl_plusButtonContentImage)
    func cylPlusButtonContentImage() -> UIImage? {
        let storage = cylPlusButtonStorage
        if storage.contentImage == nil {
            storage.contentImage = imageView?.image
        }
        return storage.contentImage
    }

    @objc(cyl_plusButtonSetContentImage:)
    func cylPlusButtonSetContentImage(_ image: UIImage?) {
        cylPlusButtonStorage.contentImage = image
    }

    // MARK: Plus buttons by context

    @objc(cyl_plusButtonForTabBarContext:)
    class func cylPlusButton(forTabBarContext tabBarContext: String?) -> CYLPlusButton? {
        CYLPlusButtonRegistry.shared.registration(for: tabBarContext)?.plusButton
    }

    @objc(cyl_plusChildViewControllerForTabBarContext:)
    class func cylPlusChildViewControllerValue(forTabBarContext tabBarContext: String?) -> UIViewController? {
        CYLPlusButtonRegistry.shared.registration(for: tabBarContext)?.plusChildViewController
    }

    @objc(cyl_plusButtonWidthForTabBarContext:)
    class func cylPlusButtonWidth(forTabBarContext tabBarContext: String?) -> CGFloat {
        CYLPlusButtonRegistry.shared.registration(for: tabBarContext)?.plusButtonWidth ?? 0
    }

    /**
     * [EN] The registration of `view`: the registered instance itself, else the most specific registered class `view` is a kind of
     *      (a plus button class may inherit from another registered one, and the stand-in `+selectedContentView` makes is not the
     *      registered instance).
     * [CN] `view` 的注册内容：先找已注册的实例本身，否则取 `view` 所属的、最具体的已注册类（一个 PlusButton 类可能继承自另一个已注册的类，
     *      `+selectedContentView` 创建的替身也不是已注册的实例）。
     */
    private class func cylRegistration(ofPlusButtonView view: UIView?) -> CYLPlusButtonRegistration? {
        guard let view else { return nil }
        return CYLPlusButtonRegistry.shared.withLock { registrations in
            var mostSpecific: CYLPlusButtonRegistration?
            for registration in registrations.values {
                if registration.plusButton === view {
                    return registration
                }
                guard let plusButtonClass = registration.plusButtonClass, view.isKind(of: plusButtonClass) else { continue }
                if let mostSpecificClass = mostSpecific?.plusButtonClass {
                    if plusButtonClass.isSubclass(of: mostSpecificClass) {
                        mostSpecific = registration
                    }
                } else {
                    mostSpecific = registration
                }
            }
            return mostSpecific
        }
    }

    @objc(cyl_plusButtonIsPlusButtonView:)
    class func cylPlusButtonIsPlusButtonView(_ view: UIView?) -> Bool {
        cylRegistration(ofPlusButtonView: view) != nil
    }

    private class func cylRegistration(ofPlusChildViewController viewController: UIViewController?) -> CYLPlusButtonRegistration? {
        guard let viewController else { return nil }
        let inner = viewController.cylGetViewControllerInsteadOfNavigation()
        return CYLPlusButtonRegistry.shared.withLock { registrations in
            registrations.values.first { registration in
                guard let child = registration.plusChildViewController else { return false }
                return child === viewController || child === inner
            }
        }
    }

    /**
     * [EN] Which context `owner` belongs to. A plus button and a plus child view controller know their own (the registry); anything
     *      else takes the context of the CYLTabBarController it belongs to (`-cyl_owningTabBarController`, any style). If it is in
     *      none: a tab bar not attached yet uses its own context, anything else the most recently active controller's, and only when
     *      no tab bar controller exists yet the context registered last.
     * [CN] `owner` 属于哪个 context。PlusButton 和 PlusButton 子控制器通过注册表知道自己的 context；其他对象取它所属 CYLTabBarController 的 context
     *      （`-cyl_owningTabBarController`，不限样式）。都不在时：尚未挂上的 TabBar 用自己的 context，其他对象取最近活跃控制器的 context，只有还没有任何
     *      TabBarController 时才取最后注册的 context。
     */
    @objc(cyl_plusButtonTabBarContextForOwner:)
    class func cylPlusButtonTabBarContext(forOwner owner: Any?) -> String? {
        var context: String?
        if let view = owner as? UIView {
            context = cylRegistration(ofPlusButtonView: view)?.context
        } else if let viewController = owner as? UIViewController {
            context = cylRegistration(ofPlusChildViewController: viewController)?.context
        }
        if let context {
            return context
        }
        guard let owner = owner as? NSObject else {
            return CYLTabBarController.cylActive()?.cyl_context ?? CYLPlusButtonRegistry.shared.latestContext
        }
        if let tabBarController = owner.cylOwningTabBarController() {
            return tabBarController.cyl_context
        }
        // [EN] A tab bar that is not attached to its controller yet carries the context the controller copied to it.
        // [CN] 尚未挂到控制器上的 TabBar 带有控制器复制给它的 context。
        let flatDesignTabBarClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBar")
        if owner is UITabBar || (flatDesignTabBarClass.map { owner.isKind(of: $0) } ?? false) {
            return owner.cyl_context
        }
        // [EN] Nothing to go by: the most recently active controller, else the context registered last.
        // [CN] 无从判断：取最近活跃的控制器，否则取最后注册的 context。
        return CYLTabBarController.cylActive()?.cyl_context ?? CYLPlusButtonRegistry.shared.latestContext
    }

    @objc(cyl_plusButtonForOwner:)
    class func cylPlusButton(forOwner owner: Any?) -> CYLPlusButton? {
        if let tabBarController = (owner as? NSObject)?.cylOwningTabBarController() {
            return cylBinding(for: tabBarController)?.plusButton
        }
        return cylPlusButton(forTabBarContext: cylPlusButtonTabBarContext(forOwner: owner))
    }

    @objc(cyl_plusChildViewControllerForOwner:)
    class func cylPlusChildViewControllerValue(forOwner owner: Any?) -> UIViewController? {
        if let tabBarController = (owner as? NSObject)?.cylOwningTabBarController() {
            return cylBinding(for: tabBarController)?.plusChildViewController
        }
        return cylPlusChildViewControllerValue(forTabBarContext: cylPlusButtonTabBarContext(forOwner: owner))
    }

    /**
     * [EN] The plus button `tabBarController` shows: its binding, made the first time it is asked and kept while the registration of
     *      its context is the same class. nil when nothing is registered for its context.
     * [CN] `tabBarController` 展示的 PlusButton：它的绑定，第一次查询时创建，只要其 context 注册的仍是同一个类就保持不变。其 context 没有注册时返回 nil。
     */
    private class func cylBinding(for tabBarController: CYLTabBarController) -> CYLPlusButtonBinding? {
        let context = tabBarController.cyl_context
        guard let registration = CYLPlusButtonRegistry.shared.registration(for: context) else { return nil }
        var binding = objc_getAssociatedObject(tabBarController, &CYLPlusButtonImplementationKeys.binding) as? CYLPlusButtonBinding
        // [EN] Kept across a new `+registerPlusButton` of the same class. [CN] 同一个类再次 `+registerPlusButton` 时保持不变。
        if let binding, binding.context == context, binding.plusButtonClass == registration.plusButtonClass {
            return binding
        }
        // [EN] Its context changed: free the registered instances of the old one. [CN] context 已变化：释放旧 context 的已注册实例。
        if let oldRegistration = binding?.registration, oldRegistration.claimingTabBarController === tabBarController {
            oldRegistration.claimingTabBarController = nil
        }
        let newBinding = CYLPlusButtonBinding()
        newBinding.registration = registration
        newBinding.context = context ?? ""
        newBinding.plusButtonClass = registration.plusButtonClass
        let claimingTabBarController = registration.claimingTabBarController
        if claimingTabBarController == nil || claimingTabBarController === tabBarController {
            registration.claimingTabBarController = tabBarController
            newBinding.plusButton = registration.plusButton
            newBinding.plusChildViewController = registration.plusChildViewController
        } else {
            cylMakeOwnPlusButton(for: newBinding, registration: registration)
        }
        binding = newBinding
        objc_setAssociatedObject(tabBarController, &CYLPlusButtonImplementationKeys.binding, newBinding, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return binding
    }

    /**
     * [EN] Another tab bar controller of the context already uses the registered instances: make this one its own (a `+plusButton`
     *      that returns one shared instance is shared, as before).
     * [CN] 该 context 的另一个 TabBarController 已在使用已注册的实例：为本控制器单独创建（返回同一共享实例的 `+plusButton` 仍然共用）。
     */
    private class func cylMakeOwnPlusButton(for binding: CYLPlusButtonBinding, registration: CYLPlusButtonRegistration) {
        guard let plusButtonClass = registration.plusButtonClass else { return }
        let classAPI = cylPlusButtonClass(plusButtonClass)
        guard let plusButton = classAPI.plusButton?() as? CYLPlusButton, plusButton !== registration.plusButton else {
            binding.plusButton = registration.plusButton
            binding.plusChildViewController = registration.plusChildViewController
            return
        }
        binding.plusButton = plusButton
        registration.boundCopies.add(plusButton)
        guard registration.plusChildViewController != nil else { return }
        if let plusChildViewController = classAPI.plusChildViewController?(), plusChildViewController !== registration.plusChildViewController {
            binding.plusChildViewController = plusChildViewController
            plusChildViewController.cyl_context = registration.context
            registration.boundCopies.add(plusChildViewController)
        } else {
            // [EN] A shared plus child view controller stays shared. [CN] 共用的 PlusButton 子控制器保持共用。
            binding.plusChildViewController = registration.plusChildViewController
        }
        // [EN] By selector, so a class made at run time is the target (Swift's metatype would be the nearest Swift class).
        // [CN] 通过 selector 调用，使运行时创建的类成为 target（Swift 的元类型会是最近的 Swift 类）。
        _ = (plusButtonClass as AnyObject).perform(NSSelectorFromString("cyl_plusButtonAddSelectViewControllerTarget:"), with: plusButton)
    }

    @objc(cyl_plusButtonWidthForOwner:)
    class func cylPlusButtonWidth(forOwner owner: Any?) -> CGFloat {
        cylPlusButtonWidth(forTabBarContext: cylPlusButtonTabBarContext(forOwner: owner))
    }

    @objc(cyl_plusButtonMatchedTabBarContext)
    class func cylPlusButtonMatchedTabBarContext() -> String {
        if let context = cylPlusButtonClass(self).tabBarContext?(), !context.isEmpty {
            return context
        }
        return NSStringFromClass(CYLTabBarController.self)
    }

    @objc(cyl_plusButtonIndexForTabbarItemsCount:)
    class func cylPlusButtonIndex(forTabbarItemsCount tabbarItemsCount: UInt) -> UInt {
        if let index = cylPlusButtonClass(self).indexOfPlusButtonInTabBar?() {
            return index
        }
        if tabbarItemsCount % 2 != 0 {
            #if DEBUG
            assertionFailure(cylLocalizedString("[DEBUG INFO] 如果 CYLTabBarController 的子控制器个数是奇数，你必须在你自定义的 plusButton 中实现 `+indexOfPlusButtonInTabBar`，来指定 plusButton 的位置。"))
            #endif
            return UInt(NSNotFound)
        }
        return tabbarItemsCount / 2
    }
}

// MARK: - A plus button from attributes (CYLTabBarControllerPlusButton)

// [EN] `CYLConfigurationPlusButton` itself stays in CYLPlusButton.m: each configuration makes a runtime subclass of it
//      (`objc_allocateClassPair`) that holds its attributes, action and context, and Swift's `type(of:)` and class methods skip
//      runtime subclasses of a Swift class, which lost every configuration's identifier and action (unit tests
//      `testEachContextKeepsItsOwnPlusButtonAction`, `testThePlusButtonPageIsNotATabAndReportsMinusOne`). The setup of the button
//      is here.
// [CN] `CYLConfigurationPlusButton` 本身保留在 CYLPlusButton.m 中：每份配置在运行时创建它的一个子类（`objc_allocateClassPair`），保存其属性、点击回调与
//      context，而 Swift 的 `type(of:)` 与类方法会跳过 Swift 类的运行时子类，导致每份配置的 identifier 与回调丢失（单元测试
//      `testEachContextKeepsItsOwnPlusButtonAction`、`testThePlusButtonPageIsNotATabAndReportsMinusOne`）。按钮的设置在这里。

/**
 * [EN] `CYLPlusButtonImageSize`: `image` drawn aspect fit in `size`, keeping its rendering mode; `image` itself without a size.
 * [CN] `CYLPlusButtonImageSize`：把 `image` 等比绘制到 `size` 中，保留其渲染模式；没有尺寸时返回 `image` 本身。
 */
private func cylPlusButtonImageFittingSize(_ image: Any, _ size: Any?) -> Any {
    let target = (size as? NSValue)?.cgSizeValue ?? .zero
    guard let source = image as? UIImage, target.width > 0, target.height > 0, source.size.width > 0, source.size.height > 0 else {
        return image
    }
    let scale = min(target.width / source.size.width, target.height / source.size.height)
    let fitted = CGSize(width: (source.size.width * scale).rounded(), height: (source.size.height * scale).rounded())
    let renderer = UIGraphicsImageRenderer(size: fitted, format: UIGraphicsImageRendererFormat.preferred())
    let scaled = renderer.image { _ in source.draw(in: CGRect(origin: .zero, size: fitted)) }
    return scaled.withRenderingMode(source.renderingMode)
}

/**
 * [EN] The plus button of `CYLTabBarControllerPlusButton`. Each registration makes a subclass of its own, which holds that
 *      configuration's attributes, action and context, and gets only the class methods its keys ask for: optional methods such as
 *      `+indexOfPlusButtonInTabBar` change the library's behavior just by being there.
 * [CN] `CYLTabBarControllerPlusButton` 的 PlusButton。每次注册生成一个自己的子类，保存该配置的属性、点击回调与 context，并且只添加其键所需的类方法：
 *      `+indexOfPlusButtonInTabBar` 等可选方法只要存在就会改变库的行为。
 */
extension CYLPlusButton {

    /**
     * [EN] Sets up a new plus button of `CYLTabBarControllerPlusButton` from its attributes (`+[CYLConfigurationPlusButton plusButton]`).
     * [CN] 根据属性设置 `CYLTabBarControllerPlusButton` 新建的 PlusButton（`+[CYLConfigurationPlusButton plusButton]`）。
     */
    @objc(cyl_configurationPlusButtonSetUpWithAttributes:)
    func cylConfigurationPlusButtonSetUp(attributes configurationAttributes: [String: Any]?) {
        var attributes = configurationAttributes ?? [:]
        for key in [cylTabBarItemImage, cylTabBarItemSelectedImage] {
            if let image = attributes[key] {
                attributes[key] = cylPlusButtonImageFittingSize(image, attributes[cylPlusButtonImageSize])
            }
        }
        let title = attributes[cylTabBarItemTitle] as? String ?? ""
        if let backgroundImage = attributes[cylPlusButtonBackgroundImage] as? UIImage {
            // [EN] A title drawn on a background image, the button the size of the image (Example-PAG's "Menu"); the same image when
            //      highlighted, so the button does not darken on touch.
            // [CN] 画在背景图上的标题，按钮与图片同样大小（Example-PAG 的「菜单」）；高亮时使用同一图片，按下时按钮不会变暗。
            setBackgroundImage(backgroundImage, for: .normal)
            setBackgroundImage(backgroundImage, for: .highlighted)
            titleLabel?.textAlignment = .center
            setTitle(title, for: .normal)
            setTitle(attributes[cylTabBarItemSelectedTitle] as? String ?? title, for: .selected)
            sizeToFit()
        } else {
            cylConfigure(attributes: attributes, title: title)
        }
        if let titleColor = attributes[cylTabBarItemTitleColor] as? UIColor {
            setTitleColor(titleColor, for: .normal)
            setTitleColor(attributes[cylTabBarItemSelectedTitleColor] as? UIColor ?? titleColor, for: .selected)
        }
        if let font = attributes[cylTabBarItemTitleFont] as? UIFont, configuration == nil {
            titleLabel?.font = font
        }
        if let size = attributes[cylPlusButtonSize] as? NSValue {
            bounds = CGRect(origin: .zero, size: size.cgSizeValue)
        }
        if (attributes[cylPlusButtonKeepsTitleVisible] as? NSNumber)?.boolValue == true {
            cyl_keepShowingPlusButtonLabel = true
        }
        // [EN] Taps reach `configurationPlusButtonTapped` through the tab bar controller's tap report, once per tap in every style.
        // [CN] 点击通过 TabBarController 的点击上报到达 `configurationPlusButtonTapped`：所有样式下每次点击一次。
    }

    /**
     * [EN] `+alignsTitleWithTabBarItemTitles` of a configuration: `CYLPlusButtonAlignsTitle`, else YES with a title and no background image.
     * [CN] 配置的 `+alignsTitleWithTabBarItemTitles`：`CYLPlusButtonAlignsTitle`；未设置时，有标题且没有背景图片则为 YES。
     */
    @objc(cyl_configurationPlusButtonAlignsTitleWithAttributes:)
    class func cylConfigurationPlusButtonAlignsTitle(attributes: [String: Any]?) -> Bool {
        let attributes = attributes ?? [:]
        if let aligns = attributes[cylPlusButtonAlignsTitle] as? NSNumber {
            return aligns.boolValue
        }
        return !((attributes[cylTabBarItemTitle] as? String) ?? "").isEmpty && attributes[cylPlusButtonBackgroundImage] == nil
    }

    private func cylConfigure(attributes: [String: Any], title: String) {
        let button = self
        let image = attributes[cylTabBarItemImage] as? UIImage
        if let image {
            button.setImage(image, for: .normal)
            button.setImage(image, for: .highlighted)
        }
        if let selectedImage = attributes[cylTabBarItemSelectedImage] as? UIImage {
            button.setImage(selectedImage, for: .selected)
            button.setImage(selectedImage, for: [.selected, .highlighted])
        } else if let image, CYLConstants.isLiquidGlassActive(), !title.isEmpty {
            // [EN] Issue #636: the selected plus button is not dimmed either. [CN] 选中的 PlusButton 也不会变暗。
            button.setImage(image, for: .selected)
            button.setImage(image, for: [.selected, .highlighted])
        }
        let font = attributes[cylTabBarItemTitleFont] as? UIFont ?? UIFont.systemFont(ofSize: 10)
        let normalColor = attributes[cylTabBarItemTitleColor] as? UIColor ?? .gray
        let selectedColor = attributes[cylTabBarItemSelectedTitleColor] as? UIColor ?? .blue
        var configuration = UIButton.Configuration.plain()
        configuration.baseBackgroundColor = .clear
        configuration.imagePlacement = .top
        configuration.imagePadding = 0
        configuration.contentInsets.leading = 0
        configuration.contentInsets.trailing = 0
        configuration.titleLineBreakMode = .byClipping
        button.configuration = configuration
        button.titleLabel?.textAlignment = .center
        button.setTitle(cylLocalizedString(title), for: .normal)
        button.setTitle(cylLocalizedString(attributes[cylTabBarItemSelectedTitle] as? String ?? title), for: .selected)
        // [EN] The font and the state's color on every state change, as `-setTitleColor:forState:` would without a configuration.
        // [CN] 每次状态变化时设置字体与该状态的颜色，与没有 configuration 时 `-setTitleColor:forState:` 的效果相同。
        button.configurationUpdateHandler = { plusButton in
            guard var updated = plusButton.configuration else { return }
            // [EN] The colors of the tab item titles, once the title follows them (`+alignsTitleWithTabBarItemTitles`, kept in `titleStyle`
            //      by `cylApplyTitleFont`, light and dark appearance resolved), win over the configuration's own colors: the update this
            //      configuration change causes ran this handler again and put the default gray back in dark mode.
            // [CN] 标题跟随 Tab 标题（`+alignsTitleWithTabBarItemTitles`）之后，Tab 标题的颜色（由 `cylApplyTitleFont` 保存在 `titleStyle` 中，
            //      已按浅色与深色外观解析）优先于配置自己的颜色：该配置变化触发的更新会再次执行本回调，深色模式下又把默认的灰色放了回去。
            let followedColor = (plusButton as? CYLPlusButton)?.cylPlusButtonStorage.titleStyle?[plusButton.isSelected ? "selected" : "normal"] as? UIColor
            let color = followedColor ?? (plusButton.isSelected ? plusButton.titleColor(for: .selected) : plusButton.titleColor(for: .normal))
                ?? (plusButton.isSelected ? selectedColor : normalColor)
            updated.baseForegroundColor = color
            updated.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { textAttributes in
                var result = textAttributes
                result.font = font
                result.foregroundColor = color
                return result
            }
            plusButton.configuration = updated
            plusButton.tintAdjustmentMode = .normal
            plusButton.imageView?.alpha = 1
        }
        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(selectedColor, for: .selected)
        button.sizeToFit()
    }
}
