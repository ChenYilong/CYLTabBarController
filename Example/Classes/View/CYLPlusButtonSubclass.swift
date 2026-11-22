//
//  CYLPlusButtonSubclass.swift
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/24.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The demo plus button's width, in points. [CN] Demo PlusButton 的宽度（pt）。
private let cYLDemoPlusButtonWidth: CGFloat = 55

/**
 [EN] The Objective-C example's plus button, ported to Swift (docs/Swift-Migration.md, phase ②;
      docs/Subclassing-In-Swift.md): `CYLPlusButton` becomes an `open` Swift class, which Objective-C cannot subclass. The
      Objective-C files of the example reach these classes through `CYLTabBarControllerDemo-Swift.h`, under the same names.
      A raised plus button (AGENTS.md): its top reaches above the tab bar (`-14` pt center offset).
 [CN] Objective-C 示例的 PlusButton，已改写为 Swift（docs/Swift-Migration.md，第 ② 阶段；docs/Subclassing-In-Swift.md）：`CYLPlusButton`
      将成为 Objective-C 无法继承的 `open` Swift 类。示例的 Objective-C 文件通过 `CYLTabBarControllerDemo-Swift.h` 以相同的类名使用它们。
      凸起的 PlusButton（AGENTS.md）：顶部高出 TabBar（中心偏移 `-14` pt）。
 */
@objc(CYLPlusButtonSubclass)
class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.textAlignment = .center
        // [EN] A plain configuration whose update handler keeps the image from dimming on highlight.
        // [CN] 使用 plain 配置，其更新回调保证高亮时图片不变暗。
        configuration = .plain()
        configurationUpdateHandler = { [weak self] button in
            button.tintAdjustmentMode = .normal
            button.imageView?.alpha = 1
            self?.titleLabel?.textAlignment = .center
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Title and images 标题与图片

    /**
     [EN] The title under the icon. `CYLSecondPlusButtonSubclass` overrides it.
     [CN] 图标下方的标题。`CYLSecondPlusButtonSubclass` 重写了它。
     */
    @objc class func plusButtonTitle() -> String {
        cylDemoLocalizedString("发布")
    }

    /**
     [EN] The normal image. [CN] 普通状态的图片。
     */
    @objc class func contentImage() -> UIImage {
        UIImage(named: "post_normal") ?? UIImage()
    }

    /**
     [EN] The selected image. [CN] 选中状态的图片。
     */
    @objc class func selectedContentImage() -> UIImage {
        UIImage(named: "post_highlight") ?? UIImage()
    }

    /// [EN] 9.5 pt, or smaller when the localized title is wider than `width` (e.g. German, Russian), so it stays on one line.
    /// [CN] 9.5 pt；本地化标题比 `width` 宽时（如德语、俄语）缩小字号，保证单行显示。
    class func titleFont(fittingWidth width: CGFloat) -> UIFont {
        let fontSize: CGFloat = 9.5
        let titleWidth = (plusButtonTitle() as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: fontSize)]).width
        if titleWidth <= width {
            return .systemFont(ofSize: fontSize)
        }
        return .systemFont(ofSize: max(7, floor(fontSize * width / titleWidth * 10) / 10))
    }

    // MARK: - CYLPlusButtonSubclassing

    static func plusButton() -> Any {
        makePlusButton()
    }

    /// [EN] `self`, not `CYLPlusButtonSubclass`: a subclass gets its own instance, icon and title.
    /// [CN] 使用 `self` 而不是 `CYLPlusButtonSubclass`：子类得到自己的实例、图标与标题。
    class func makePlusButton() -> CYLPlusButtonSubclass {
        // [EN] `-init` through the runtime: a class method cannot call a non-required initializer on `self`.
        // [CN] 通过运行时调用 `-init`：类方法不能对 `self` 调用非 required 的初始化方法。
        guard let button = (self as NSObject.Type).init() as? CYLPlusButtonSubclass else { return CYLPlusButtonSubclass() }
        button.setImage(contentImage(), for: .normal)
        button.setImage(selectedContentImage(), for: [.highlighted, .selected])
        button.contentMode = .center
        button.imageView?.contentMode = .scaleAspectFit

        // [EN] The title color when selected and pressed. The plus button of THIS class's context: with several plus buttons
        //      `CYLExternPlusButton` is only the one registered last.
        // [CN] 选中后再按下时的标题颜色。取本类 context 的 PlusButton：有多个 PlusButton 时 `CYLExternPlusButton` 只是最后注册的那个。
        let selectedHighlightedTitleColor = UIColor.cyl_systemGreen
        let registeredPlusButton = CYLPlusButton(forTabBarContext: matchedTabBarContext())
        let isSelectedAndHighlighted = button.isSelected || button.isHighlighted
            || (registeredPlusButton?.isSelected ?? false) || (registeredPlusButton?.isHighlighted ?? false)
        let titleColor = isSelectedAndHighlighted ? selectedHighlightedTitleColor : UIColor.label

        var configuration = UIButton.Configuration.plain()
        configuration.baseBackgroundColor = .clear
        configuration.baseForegroundColor = titleColor
        // [EN] The image on top, the title below. [CN] 图片在上，文字在下。
        configuration.imagePlacement = .top
        // [EN] `-setTitleColor:forState:` does nothing with a configuration: the color is fixed in the transformer.
        // [CN] 使用 configuration 时 `-setTitleColor:forState:` 不生效：颜色在 transformer 中给定。
        let font = titleFont(fittingWidth: cYLDemoPlusButtonWidth)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = font
            attributes.foregroundColor = titleColor
            return attributes
        }
        // [EN] The title gets the whole width (the plain configuration adds leading / trailing insets).
        // [CN] 标题使用整个宽度（plain 配置会添加左右内边距）。
        configuration.contentInsets.leading = 0
        configuration.contentInsets.trailing = 0
        configuration.titleLineBreakMode = .byClipping
        button.configuration = configuration
        // [EN] No dimming on highlight. [CN] 高亮时不变暗。
        button.configurationUpdateHandler = { button in
            button.tintAdjustmentMode = .normal
            button.imageView?.alpha = 1
        }

        button.setTitle(plusButtonTitle(), for: .normal)
        button.setTitle(plusButtonTitle(), for: [.selected, .highlighted])
        button.setTitleColor(selectedHighlightedTitleColor, for: [.selected, .highlighted])
        button.bounds = CGRect(x: 0, y: 0, width: cYLDemoPlusButtonWidth, height: 80)

        // [EN] With `+plusChildViewController`, do not add a target to the plus button.
        // [CN] 使用 `+plusChildViewController` 时，不要给 PlusButton 添加 target。
        let action = #selector(clickPublish)
        button.removeTarget(self, action: action, for: .touchUpInside)
        button.addTarget(button, action: action, for: .touchUpInside)
        // [EN] Every tap reaches `tabBarController:didSelectControl:`, which bumps the plus button's badge (#535).
        // [CN] 每次点击都会到达 `tabBarController:didSelectControl:`，并增加 PlusButton 的角标（#535）。
        button.reportsTapsToDelegate = true
        // [EN] Issue #91: a larger touchable area without changing the frame (the gap below a raised plus button).
        // [CN] Issue #91：不改变 frame 即可扩大点击范围（凸起 PlusButton 下方的间隙）。
        button.touchableAreaOutsets = UIEdgeInsets(top: 0, left: 8, bottom: 12, right: 8)
        return button
    }

    static func plusChildViewController() -> UIViewController {
        let plusChildViewController = UIViewController()
        // [EN] The navigation bar title is the plus button's title, also after it changes.
        // [CN] 导航栏标题即 PlusButton 的标题，标题变化后也会同步。
        plusChildViewController.cyl_navigationTitleFollowsTabBarItemTitle = true
        let navigationController = UINavigationController(rootViewController: plusChildViewController)
        navigationController.title = cylDemoLocalizedString("发布")
        return navigationController
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        2
    }

    /// [EN] The title stays on the same center line as the tab titles, in every style. [CN] 各样式下标题与 Tab 标题在同一中线上。
    static func alignsTitleWithTabBarItemTitles() -> Bool {
        true
    }

    /// [EN] #408: read as `control.cyl_tabBarItemIdentifier` in `-tabBarController:didSelectControl:`.
    /// [CN] #408：在 `-tabBarController:didSelectControl:` 中通过 `control.cyl_tabBarItemIdentifier` 读取。
    @objc class func tabBarItemIdentifier() -> String {
        "plus"
    }

    static func shouldSelectPlusChildViewController() -> Bool {
        true
    }

    static func constantOfPlusButtonCenterYOffset(forTabBarHeight _: CGFloat) -> CGFloat {
        -14
    }

    /**
     [EN] The plus button class the NEXT tab bar controller should use: the other one of the demo's two plus buttons, i.e.
          not the one of the tab bar controller `owner` belongs to. Both stay registered, each for its own context.
     [CN] 下一个 TabBarController 应该使用的 PlusButton 类：Demo 两个 PlusButton 中的另一个，即不是 `owner` 所属 TabBarController 使用的那个。
          两个都保持注册（各自一个 context）。
     */
    @objc(alternatePlusButtonClassForOwner:)
    class func alternatePlusButtonClass(forOwner owner: Any?) -> AnyClass {
        let isSecond = CYLPlusButton(forOwner: owner) is CYLSecondPlusButtonSubclass
        return isSecond ? CYLPlusButtonSubclass.self : CYLSecondPlusButtonSubclass.self
    }

    // MARK: - Event response 事件响应

    @objc func clickPublish() {
        guard let viewController = cylGetRootViewController() else { return }
        // [EN] The new tab bar controller shows the OTHER plus button (another context): the title tells which.
        // [CN] 新的 TabBarController 显示另一个 PlusButton（另一个 context），标题会说明是哪一个。
        let nextClass: AnyClass = CYLPlusButtonSubclass.alternatePlusButtonClass(forOwner: self)
        let nextTitle = (nextClass as? CYLPlusButtonSubclass.Type)?.plusButtonTitle() ?? ""
        let actionSheet = UIAlertController(title: cylDemoLocalizedString("Switch Style 切换样式"),
                                            message: String(format: cylDemoLocalizedString("PlusButton → 「%@」"), nextTitle),
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: cylDemoLocalizedString("Liquid Glass液态玻璃"), style: .default) { _ in
            CYLMainRootViewController.current()?.createLiquidGlassTabBar(withPlusButtonClass: nextClass)
        })
        actionSheet.addAction(UIAlertAction(title: cylDemoLocalizedString("FlatDesign扁平设计样式"), style: .default) { _ in
            CYLMainRootViewController.current()?.createFlatDesignTabBar(withPlusButtonClass: nextClass)
        })
        actionSheet.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel))
        // [EN] iPad: anchored to the bottom of the screen, no arrow. [CN] iPad：锚定在屏幕底部，没有箭头。
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.width / 2, y: viewController.view.bounds.height, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        viewController.present(actionSheet, animated: true)
        addScaleAnimation(on: imageView, repeatCount: 1)
    }

    /// [EN] A scale animation; none with Liquid Glass, which allows only the system glass effect.
    /// [CN] 缩放动画；液态玻璃下不使用（只能使用系统的玻璃效果）。
    func addScaleAnimation(on animationView: UIView?, repeatCount: Float) {
        guard let animationView, !CYLConstants.isLiquidGlassActive() else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.1, 0.9, 1.15, 0.95, 1.02, 1.0]
        animation.duration = 1
        animation.repeatCount = repeatCount
        animation.calculationMode = .cubic
        animationView.layer.add(animation, forKey: nil)
    }
}

/**
 [EN] A second plus button for the demo: only the icon, the title and the context (`+tabBarContext`) differ. A tab bar
      controller with that context shows it, next to others that show `CYLPlusButtonSubclass`. See issues #414, #489.
 [CN] Demo 的第二个 PlusButton：只改了图标、标题和 context（`+tabBarContext`）。context 相同的 TabBarController 显示它，其他的显示
      `CYLPlusButtonSubclass`。见 issue #414、#489。
 */
@objc(CYLSecondPlusButtonSubclass)
class CYLSecondPlusButtonSubclass: CYLPlusButtonSubclass {

    /// [EN] A tab bar controller created with this context shows this plus button. [CN] 用此 context 创建的 TabBarController 显示这个 PlusButton。
    @objc class func tabBarContext() -> String {
        "CYLSecondPlusButtonContext"
    }

    /// [EN] #408: another context, another identifier. [CN] #408：另一个 context，标识也不同。
    override class func tabBarItemIdentifier() -> String {
        "camera"
    }

    override class func plusButtonTitle() -> String {
        cylDemoLocalizedString("拍摄")
    }

    /// [EN] A camera symbol; the other plus button keeps the `post_*` images. [CN] 相机符号；另一个 PlusButton 保留 `post_*` 图片。
    private class func cameraImage(color: UIColor) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        return UIImage(systemName: "camera.circle.fill", withConfiguration: configuration)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    override class func contentImage() -> UIImage {
        cameraImage(color: .systemOrange) ?? super.contentImage()
    }

    override class func selectedContentImage() -> UIImage {
        cameraImage(color: .systemRed) ?? super.selectedContentImage()
    }
}

/// [EN] Side of the X button, in points. [CN] X 按钮的边长（pt）。
private let cYLCloseSubviewButtonSide: CGFloat = 22
/// [EN] The X button's current color, shared with the copy in the Liquid Glass selected layer. [CN] X 按钮当前的颜色，与液态玻璃选中图层中的副本共用。
private var cYLCloseSubviewCurrentColor: UIColor?

/**
 [EN] Issue #202 demo: a third plus button, with its own context, carrying an X button at its top right. Tapping the X gives
      it a random color and does not trigger the plus button. Opened from the "Message" tab. See
      docs/PlusButton-Subview-Touches.md.
 [CN] Issue #202 演示：第三个 PlusButton，使用自己的 context，右上角有一个 X 按钮。点击 X 时随机改变颜色，不触发 PlusButton。从“消息”页打开。
      见 docs/PlusButton-Subview-Touches.md。
 */
@objc(CYLCloseSubviewPlusButtonSubclass)
class CYLCloseSubviewPlusButtonSubclass: CYLPlusButtonSubclass {

    /// [EN] The X button, a subview of the plus button. [CN] X 按钮，PlusButton 的子视图。
    @objc private(set) var closeButton: UIButton?

    @objc class func tabBarContext() -> String {
        "CYLCloseSubviewPlusButtonContext"
    }

    override class func tabBarItemIdentifier() -> String {
        "closeSubview"
    }

    override class func plusButtonTitle() -> String {
        cylDemoLocalizedString("子控件")
    }

    override class func makePlusButton() -> CYLPlusButtonSubclass {
        let button = super.makePlusButton()
        guard let closeSubviewButton = button as? CYLCloseSubviewPlusButtonSubclass else { return button }
        let configuration = UIImage.SymbolConfiguration(pointSize: cYLCloseSubviewButtonSide, weight: .bold)
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate),
                             for: .normal)
        closeButton.tintColor = cYLCloseSubviewCurrentColor ?? .systemRed
        closeButton.accessibilityLabel = "X"
        // [EN] A UIControl subview: the tab bar hands it its own touches (issue #202).
        // [CN] UIControl 子视图：TabBar 把它自己的触摸交给它（issue #202）。
        closeButton.addTarget(closeSubviewButton, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
        closeSubviewButton.addSubview(closeButton)
        closeSubviewButton.closeButton = closeButton
        // [EN] VoiceOver: the plus button is one element, so its X is a custom action.
        // [CN] VoiceOver：PlusButton 是一个无障碍元素，因此把 X 作为自定义操作提供。
        closeSubviewButton.accessibilityCustomActions = [UIAccessibilityCustomAction(name: "X") { [weak closeSubviewButton] _ in
            guard let closeSubviewButton, let closeButton = closeSubviewButton.closeButton else { return false }
            closeSubviewButton.closeButtonTapped(closeButton)
            return true
        }]
        return closeSubviewButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // [EN] Top right, inside the bounds, above the image and the title. [CN] 右上角，在按钮范围内，位于图片与标题之上。
        guard let closeButton else { return }
        closeButton.frame = CGRect(x: bounds.width - cYLCloseSubviewButtonSide, y: 0,
                                   width: cYLCloseSubviewButtonSide, height: cYLCloseSubviewButtonSide)
        bringSubviewToFront(closeButton)
    }

    @objc func closeButtonTapped(_ sender: UIButton) {
        let color = UIColor(hue: CGFloat.random(in: 0..<1), saturation: 0.85, brightness: 0.9, alpha: 1)
        cYLCloseSubviewCurrentColor = color
        sender.tintColor = color
        // [EN] The Liquid Glass selected layer shows another instance (`selectedContentView`): keep it in step.
        // [CN] 液态玻璃的选中图层显示的是另一个实例（`selectedContentView`）：同步它的颜色。
        let selectedContentView = value(forKey: "selectedContentView") as? CYLCloseSubviewPlusButtonSubclass
        selectedContentView?.closeButton?.tintColor = color
    }
}
