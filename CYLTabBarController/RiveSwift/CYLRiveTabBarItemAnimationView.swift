//
//  CYLRiveTabBarItemAnimationView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The Swift bridge of the `Rive` subspec: Rive's runtime (`RiveRuntime`, 6.29+) is a Swift API, so this view hosts a
//      `RiveUIView`. It adopts the shared interfaces `CYLTabBarItemAnimationPlayableView` (it plays itself) and
//      `CYLTabBarItemAnimationViewProviding` (it makes its views), so the shared `CYLTabBarItemViewAnimator` does everything
//      else; it gets its files through `CYLRiveTabBarItemAnimationFileProviding`. It uses only Rive's current
//      API (`Worker`, `File`, `Rive`, `RiveUIView`, view model instances), not the deprecated `RiveViewModel`. Compiled
//      only with the Rive runtime.
// [CN] `Rive` 子库的 Swift 桥接：Rive 运行时（`RiveRuntime` 6.29+）是 Swift API，因此本视图承载一个 `RiveUIView`。它遵守共用接口
//      `CYLTabBarItemAnimationPlayableView`（自己播放）与 `CYLTabBarItemAnimationViewProviding`（创建视图），其余工作都由共用的
//      `CYLTabBarItemViewAnimator` 完成；它通过 `CYLRiveTabBarItemAnimationFileProviding` 获取文件。只使用 Rive 当前的 API（`Worker`、`File`、`Rive`、
//      `RiveUIView`、view model 实例），不使用已废弃的 `RiveViewModel`。仅在引入 Rive 运行时时编译。
#if canImport(RiveRuntime)
import UIKit
import RiveRuntime

/*!
 * [EN] Where Rive files come from: the view depends on this interface, not on a cache. The default,
 *      `CYLRiveTabBarItemAnimationFileCache`, shares one `Worker` and loads each .riv file once.
 * [CN] Rive 文件的来源：视图依赖此接口，而不是具体的缓存。默认实现 `CYLRiveTabBarItemAnimationFileCache` 共用一个 `Worker`，每个 .riv 文件只加载一次。
 */
@MainActor
protocol CYLRiveTabBarItemAnimationFileProviding: AnyObject {
    func file(at url: URL) async throws -> RiveRuntime.File
}

/// [EN] What one tab plays, read from its URL's options (`CYLTabBarAnimationOptionRive…`). [CN] 一个 Tab 播放的内容，从其 URL 的选项中读取。
struct CYLRiveTabBarItemAnimationConfiguration {
    let fileURL: URL
    let artboardName: String?
    let stateMachineName: String?
    let activePropertyPath: String
    let activeDuration: TimeInterval
    let triggerPropertyPath: String?
    let lightColor: UIColor?
    /// [EN] Legacy runtime (files without a view model): a state machine input, a trigger input, or a linear animation.
    /// [CN] 旧版运行时（没有 view model 的文件）：状态机布尔输入、trigger 输入或线性动画。
    let stateMachineInput: String?
    let triggerInput: String?
    let animationName: String?
    /// [EN] A state machine number input set to the next value on each play (house.riv: `Rooms`).
    /// [CN] 每次播放设为下一个值的状态机数字输入（house.riv：`Rooms`）。
    let numberInput: String?
    /// [EN] `tint` = "title": the tab's title color, as a template image. [CN] `tint` 为 "title"：Tab 的标题颜色，与模板图片相同。
    let tintFollowsTitle: Bool
    /// [EN] `tint` = "#RRGGBB(AA)": a fixed color; with `darkTint`, a dynamic color that switches in Dark Mode.
    /// [CN] `tint` 为 "#RRGGBB(AA)"：固定颜色；同时有 `darkTint` 时为深色模式下切换的动态颜色。
    let fixedTintColor: UIColor?
    /// [EN] Rive's theme pattern: the view model instance used in light mode (nil: the default instance) and in Dark Mode.
    /// [CN] Rive 的主题方式：浅色模式下使用的 view model 实例（nil 表示默认实例）与深色模式下使用的实例。
    let viewModelInstanceName: String?
    let darkViewModelInstanceName: String?
    /// [EN] The values the number input steps through; empty: +1. [CN] 数字输入依次使用的值；为空时 +1。
    let numberValues: [Float]
    /// [EN] Played through the legacy runtime even with none of the three above. [CN] 即使没有以上三项，也通过旧版运行时播放。
    let forcesLegacyRuntime: Bool

    /// [EN] Seconds of a loop pass when the file gives none. [CN] 文件未给出时一次循环的秒数。
    static let loopSeconds: TimeInterval = 1.5
    /// [EN] The pause after an input goes back to false, before the next pass. [CN] 输入恢复为 false 后、下一次播放前的停顿。
    static let loopPauseSeconds: TimeInterval = 0.4

    /// [EN] Whether the file is played through Rive's legacy runtime. [CN] 是否通过 Rive 旧版运行时播放该文件。
    var usesLegacyRuntime: Bool {
        return forcesLegacyRuntime || stateMachineInput != nil || triggerInput != nil || animationName != nil || numberInput != nil
    }

    init(fileURL: URL, options: [String: String]) {
        self.fileURL = fileURL
        artboardName = options[CYLTabBarAnimationOption.riveArtboard.rawValue]
        stateMachineName = options[CYLTabBarAnimationOption.riveStateMachine.rawValue]
        activePropertyPath = options[CYLTabBarAnimationOption.riveActiveProperty.rawValue] ?? "active"
        // [EN] 1 second by default, at most a minute; 0 keeps it YES until the animation stops.
        // [CN] 默认 1 秒，最长一分钟；0 表示保持 YES，直到动画停止。
        if let duration = Double(options[CYLTabBarAnimationOption.riveActiveDuration.rawValue] ?? ""), duration >= 0 {
            activeDuration = min(duration, 60)
        } else {
            activeDuration = 1
        }
        triggerPropertyPath = options[CYLTabBarAnimationOption.riveTriggerProperty.rawValue]
        lightColor = options[CYLTabBarAnimationOption.riveColor.rawValue].flatMap(Self.color(hex:))
        stateMachineInput = options[CYLTabBarAnimationOption.riveInput.rawValue]
        triggerInput = options[CYLTabBarAnimationOption.riveTriggerInput.rawValue]
        animationName = options[CYLTabBarAnimationOption.riveAnimation.rawValue]
        forcesLegacyRuntime = options[CYLTabBarAnimationOption.riveLegacyRuntime.rawValue] == "1"
        numberInput = options[CYLTabBarAnimationOption.riveNumberInput.rawValue]
        let tint = options[CYLTabBarAnimationOption.tint.rawValue]?.trimmingCharacters(in: .whitespaces)
        tintFollowsTitle = tint == "title"
        let lightTint = tint.flatMap { $0 == "title" ? nil : Self.color(hex: $0) }
        let darkTint = options[CYLTabBarAnimationOption.darkTint.rawValue].flatMap { Self.color(hex: $0.trimmingCharacters(in: .whitespaces)) }
        fixedTintColor = Self.dynamicColor(light: lightTint, dark: darkTint)
        viewModelInstanceName = options[CYLTabBarAnimationOption.riveViewModelInstance.rawValue].flatMap { $0.isEmpty ? nil : $0 }
        darkViewModelInstanceName = options[CYLTabBarAnimationOption.riveDarkViewModelInstance.rawValue].flatMap { $0.isEmpty ? nil : $0 }
        numberValues = (options[CYLTabBarAnimationOption.riveNumberValues.rawValue] ?? "").split(separator: ",")
            .compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
    }

    /**
     * [EN] The color the icon is drawn in. `tint` "title": the tab's title color. A fixed `tint` (with `darkTint`): drawn on the
     *      unselected tab only; the selected tab takes the title's selected color, as with "title" (user decision,
     *      2026-11-19). `selected` is nil when the caller does not tell the state (`-cyl_applyAnimationViewTintColor:`), then
     *      the fixed color is used in both states, as before.
     * [CN] 图标的绘制颜色。`tint` 为 "title"：Tab 的标题颜色。固定 `tint`（及 `darkTint`）：只用于未选中的 Tab；选中的 Tab 使用标题的选中颜色，
     *      与 "title" 相同（用户决定，2026-11-19）。调用方未告知状态时 `selected` 为 nil（`-cyl_applyAnimationViewTintColor:`），此时两种状态都使用
     *      固定颜色，与以前相同。
     */
    func tintColor(titleColor: UIColor?, selected: Bool?) -> UIColor? {
        if let fixedTintColor {
            return selected == true ? (titleColor ?? fixedTintColor) : fixedTintColor
        }
        return tintFollowsTitle ? titleColor : nil
    }

    /// [EN] The value a play sets on the number input: the one after `current` in `numberValues`, cycling; without values,
    ///      `current + 1`. [CN] 一次播放设置到数字输入的值：`numberValues` 中 `current` 的下一个，循环；没有值时为 `current + 1`。
    func nextNumber(after current: Float) -> Float {
        guard !numberValues.isEmpty else {
            return current + 1
        }
        let index = numberValues.firstIndex(of: current).map { $0 + 1 } ?? 0
        return numberValues[index % numberValues.count]
    }

    /// [EN] `light` in light mode and `dark` in Dark Mode; nil without `light` (a "title" tint has no fixed color, so `dark`
    ///      alone is ignored); `light` alone when `dark` is nil.
    /// [CN] 浅色模式为 `light`、深色模式为 `dark`；没有 `light` 时为 nil（"title" 着色没有固定颜色，单独的 `dark` 被忽略）；`dark` 为 nil 时只用 `light`。
    static func dynamicColor(light: UIColor?, dark: UIColor?) -> UIColor? {
        guard let light else {
            return nil
        }
        guard let dark else {
            return light
        }
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }

    /// [EN] "#RRGGBB" or "#RRGGBBAA" ("#" optional). [CN] "#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略）。
    static func color(hex: String) -> UIColor? {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6 || digits.count == 8, var value = UInt64(digits, radix: 16) else {
            return nil
        }
        if digits.count == 6 {
            value = (value << 8) | 0xFF
        }
        func component(_ shift: UInt64) -> CGFloat {
            return CGFloat((value >> shift) & 0xFF) / 255
        }
        return UIColor(red: component(24), green: component(16), blue: component(8), alpha: component(0))
    }
}

/**
 * [EN] Answers whether a local .riv file has no view model, so `CYLRiveTabBarItemAnimationView` can play it through the
 *      legacy view instead of showing it still (house.riv, docs/Animated-Item.md). Adopted by the legacy view, which may
 *      use Rive's deprecated API.
 * [CN] 判断本地 .riv 文件是否没有 view model，使 `CYLRiveTabBarItemAnimationView` 可以改用旧版视图播放，而不是静止显示（house.riv，
 *      docs/Animated-Item.md）。由旧版视图遵守，它可以使用 Rive 已废弃的 API。
 */
@MainActor
@objc(CYLRiveFileInspecting)
public protocol CYLRiveFileInspecting: NSObjectProtocol {
    /**
     * [EN] Whether the local file at `fileURL` has no view model (false when it cannot be read).
     * [CN] `fileURL` 处的本地文件是否没有 view model（无法读取时为 false）。
     */
    @objc(cyl_fileHasNoViewModel:)
    static func cylFileHasNoViewModel(_ fileURL: URL) -> Bool
}

/*!
 * [EN] A tab icon that plays a Rive artboard. It loads asynchronously; calls made before it has loaded are applied once
 *      it has. A tab "plays" through the artboard's view model: the boolean `activePropertyPath` is set to true, then back
 *      to false after `activeDuration` seconds, or the trigger `triggerPropertyPath` is fired. An artboard without a view
 *      model is shown but does not play. It takes no touches: the tab button does.
 * [CN] 播放 Rive 画板的 Tab 图标。异步加载；加载完成前的调用会在加载后执行。Tab 通过画板的 view model「播放」：把布尔属性
 *      `activePropertyPath` 设为 true，`activeDuration` 秒后恢复为 false；或触发 trigger 属性 `triggerPropertyPath`。没有 view model 的画板
 *      只显示、不播放。它不接收触摸，由 Tab 按钮接收。
 */
@objc(CYLRiveTabBarItemAnimationView)
public final class CYLRiveTabBarItemAnimationView: UIView, CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding {

    /// [EN] The view model color property set by `lightColor`. [CN] `lightColor` 所设置的 view model 颜色属性。
    private static let colorPropertyPath = "color"

    private let configuration: CYLRiveTabBarItemAnimationConfiguration
    private let fileProvider: CYLRiveTabBarItemAnimationFileProviding

    private var rive: Rive?
    private var riveView: RiveUIView?
    private var viewModelInstance: ViewModelInstance?
    /// [EN] The state machine, kept to rebind the theme instance. [CN] 状态机，保存下来用于重新绑定主题实例。
    private var stateMachine: StateMachine?
    /// [EN] The light and Dark Mode instances (`viewModelInstance` / `darkViewModelInstance` options); nil: no theme switch.
    /// [CN] 浅色与深色模式的实例（`viewModelInstance` / `darkViewModelInstance` 选项）；nil 表示不切换主题。
    private var lightThemeInstance: ViewModelInstance?
    private var darkThemeInstance: ViewModelInstance?
    /// [EN] The selected state, carried over to the other instance on a theme switch. [CN] 选中状态，切换主题时带到另一个实例。
    private var isActive = false
    private var isLoaded = false
    private var playsWhenLoaded = false
    /// [EN] Played at least once: the view is no longer paused on its first frame. [CN] 至少播放过一次：视图不再暂停在第一帧。
    private var hasPlayed = false
    /// [EN] Time for the first frame to be drawn before the view pauses. [CN] 视图暂停前绘制第一帧的时间。
    private static let firstFrameNanoseconds: UInt64 = 100_000_000
    private var deactivateTask: Task<Void, Never>?
    /// [EN] Plays again after each pass (`cyl_setAnimationViewLoops:`). [CN] 每次播放后再次播放（`cyl_setAnimationViewLoops:`）。
    private var loops = false
    private var endHandler: (() -> Void)?
    private var loopTask: Task<Void, Never>?

    /// [EN] The colors asked for last (nil: the light colors), applied in order. [CN] 最近一次请求的颜色（nil 表示浅色颜色），按顺序应用。
    private var requestedColors: [String: UIColor]?
    private var colorTask: Task<Void, Never>?
    /// [EN] Each overridden property's color before it was overridden. [CN] 每个被覆盖的属性在覆盖前的颜色。
    private var originalColors: [String: RiveRuntime.Color] = [:]
    private var overriddenColorPaths: Set<String> = []

    // MARK: - [EN] CYLTabBarItemAnimationViewProviding [CN] 视图工厂接口

    /// [EN] The renderer for `legacy` options (another strategy of the same interface), a class adopting
    ///      `CYLTabBarItemAnimationViewProviding`. Injected by the composition root, `CYLRiveTabBarItemAnimator`, which
    ///      passes `CYLRiveLegacyTabBarItemAnimationView`; nil: `legacy` options show nothing.
    /// [CN] `legacy` 选项使用的渲染器（同一接口的另一个策略），为遵守 `CYLTabBarItemAnimationViewProviding` 的类。由组合根
    ///      `CYLRiveTabBarItemAnimator` 注入（传入 `CYLRiveLegacyTabBarItemAnimationView`）；nil 表示 `legacy` 选项不显示内容。
    @objc public static var legacyViewProvider: AnyClass?

    /// [EN] Where the views made by `makeAnimationView` load their files; injectable (e.g. a bundle or a download).
    /// [CN] `makeAnimationView` 创建的视图从哪里加载文件；可注入（例如 bundle 或下载）。
    static var fileProvider: CYLRiveTabBarItemAnimationFileProviding = CYLRiveTabBarItemAnimationFileCache.shared

    public static func makeAnimationView(fileURL: URL, options: [String: String], contentMode: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)? {
        let configuration = CYLRiveTabBarItemAnimationConfiguration(fileURL: fileURL, options: options)
        // [EN] A local file without a view model has nothing to bind: the legacy view plays its state machine (house.riv).
        // [CN] 没有 view model 的本地文件无可绑定：由旧版视图播放其状态机（house.riv）。
        let fileHasNoViewModel = !configuration.usesLegacyRuntime
            && ((legacyViewProvider as? CYLRiveFileInspecting.Type)?.cylFileHasNoViewModel(fileURL) ?? false)
        if configuration.usesLegacyRuntime || fileHasNoViewModel {
            // [EN] Another implementation of the same interface (strategy), chosen by the options.
            // [CN] 同一接口的另一个实现（策略），根据选项选择。
            let legacyProvider = legacyViewProvider as? CYLTabBarItemAnimationViewProviding.Type
            return legacyProvider?.makeAnimationView(fileURL: fileURL, options: options, contentMode: contentMode)
        }
        let view = CYLRiveTabBarItemAnimationView(configuration: configuration, fileProvider: fileProvider)
        view.contentMode = contentMode
        return view
    }

    /// [EN] `fileProvider` is injected, so the view does not depend on where files come from.
    /// [CN] `fileProvider` 由外部注入，因此视图不依赖文件的来源。
    /// [EN] The template tint (`CYLTabBarAnimationOptionTint`). [CN] 模板着色（`CYLTabBarAnimationOptionTint`）。
    private let tintOverlay = CYLRiveTintOverlay()
    /// [EN] The last title color, kept for a file that loads later. [CN] 最近的标题颜色，供稍后加载的文件使用。
    private var titleTintColor: UIColor?
    /// [EN] The tab's selected state, nil until a caller tells it. [CN] Tab 的选中状态，调用方告知之前为 nil。
    private var tintSelected: Bool?

    /// [EN] The tint for the current title color and state. [CN] 当前标题颜色与状态下的着色。
    private var currentTintColor: UIColor? {
        if hasResolvedTint { return resolvedTintColor }
        return configuration.tintColor(titleColor: titleTintColor, selected: tintSelected)
    }

    /// [EN] Set once a `CYLAnimatedItemView` hands over its final color: it already applied `animationTint` / `animationDarkTint`, the URL
    ///      options and the truth table, so this view stops resolving its own. [CN] 当 `CYLAnimatedItemView` 交来最终颜色后设置：条目已应用
    ///      `animationTint` / `animationDarkTint`、URL 选项与真值表，本视图不再自行解析。
    private var hasResolvedTint = false
    private var resolvedTintColor: UIColor?

    /// [EN] `cyl_applyAnimationViewResolvedTintColor:`: the final color (nil: no tint), from `CYLAnimatedItemView`. [CN] 来自 `CYLAnimatedItemView` 的最终颜色（nil 表示不着色）。
    @objc(cyl_applyAnimationViewResolvedTintColor:)
    public func applyResolvedAnimationTintColor(_ color: UIColor?) {
        hasResolvedTint = true
        resolvedTintColor = color
        if isLoaded {
            tintOverlay.apply(color, in: self)
        }
    }

    /// [EN] `cyl_applyAnimationViewTintColor:`: the tab's title color, without its state. [CN] Tab 的标题颜色，不含状态。
    public func applyAnimationTintColor(_ color: UIColor?) {
        titleTintColor = color
        if isLoaded {
            tintOverlay.apply(currentTintColor, in: self)
        }
    }

    /// [EN] `cyl_applyAnimationViewTintColor:selected:`: the title color and the tab's state; a fixed tint only when unselected.
    /// [CN] `cyl_applyAnimationViewTintColor:selected:`：标题颜色与 Tab 状态；固定着色只用于未选中状态。
    public func applyAnimationTintColor(_ color: UIColor?, selected: Bool) {
        tintSelected = selected
        applyAnimationTintColor(color)
    }

    /// [EN] Keeps the tint over the Rive view. [CN] 让着色覆盖 Rive 视图。
    override public func layoutSubviews() {
        super.layoutSubviews()
        tintOverlay.layout(in: self)
    }

    init(configuration: CYLRiveTabBarItemAnimationConfiguration, fileProvider: CYLRiveTabBarItemAnimationFileProviding) {
        self.configuration = configuration
        self.fileProvider = fileProvider
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // [EN] The tab button describes itself to VoiceOver. [CN] 由 Tab 按钮向 VoiceOver 描述自己。
        accessibilityElementsHidden = true
        load()
        if configuration.darkViewModelInstanceName != nil || configuration.fixedTintColor != nil || configuration.tintFollowsTitle,
           #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: CYLRiveTabBarItemAnimationView, _: UITraitCollection) in
                view.appearanceDidChange()
            }
        }
    }

    /// [EN] Before iOS 17: the light / dark switch. [CN] iOS 17 之前：浅色 / 深色切换。
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 17.0, *) {
            return
        }
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            appearanceDidChange()
        }
    }

    /// [EN] Rebinds the theme instance and resolves a fixed tint again for the current appearance.
    /// [CN] 按当前外观重新绑定主题实例，并重新解析固定着色。
    private func appearanceDidChange() {
        guard isLoaded else {
            return
        }
        // [EN] A dynamic color (a fixed tint with `darkTint`, or the title color), resolved again with the new appearance.
        // [CN] 动态颜色（带 `darkTint` 的固定着色或标题颜色），按新外观重新解析。
        if let tint = currentTintColor {
            tintOverlay.apply(tint, in: self)
        }
        bindThemeInstance()
    }

    /// [EN] Binds the light or the Dark Mode instance (Rive: `StateMachine.bindViewModelInstance`), keeping the selected state.
    /// [CN] 绑定浅色或深色模式的实例（Rive：`StateMachine.bindViewModelInstance`），保持选中状态。
    private func bindThemeInstance() {
        guard let stateMachine, let light = lightThemeInstance, let dark = darkThemeInstance else {
            return
        }
        let instance = traitCollection.userInterfaceStyle == .dark ? dark : light
        guard instance !== viewModelInstance else {
            return
        }
        if configuration.triggerPropertyPath == nil {
            instance.setValue(of: BoolProperty(path: configuration.activePropertyPath), to: isActive)
        }
        viewModelInstance = instance
        originalColors.removeAll()
        overriddenColorPaths.removeAll()
        if let lightColor = configuration.lightColor {
            originalColors[Self.colorPropertyPath] = Self.riveColor(lightColor)
            instance.setValue(of: ColorProperty(path: Self.colorPropertyPath), to: Self.riveColor(lightColor))
        }
        if requestedColors != nil {
            enqueueRequestedColors()
        }
        // [EN] Rive 6.29+: `bindViewModelInstances(main:)` (async) replaces the deprecated `bindViewModelInstance(_:)`. The
        //      values above live on the instance, so they apply once it is bound; the view resumes then, unless a newer
        //      theme switch bound another instance meanwhile.
        // [CN] Rive 6.29+：`bindViewModelInstances(main:)`（异步）取代已废弃的 `bindViewModelInstance(_:)`。上面的值保存在实例上，绑定后即生效；
        //      之后恢复播放，除非期间更新的主题切换绑定了另一个实例。
        Task { @MainActor [weak self] in
            try? await stateMachine.bindViewModelInstances(main: instance)
            guard let self, self.viewModelInstance === instance else {
                return
            }
            self.riveView?.isPaused = false
        }
    }

    /// [EN] Not used from Interface Builder. [CN] 不支持从 Interface Builder 创建。
    public required init?(coder _: NSCoder) {
        return nil
    }

    /// [EN] `tabBarItemAnimationViewContentMode` -> Rive's fit. [CN] `tabBarItemAnimationViewContentMode` 对应 Rive 的 fit。
    override public var contentMode: UIView.ContentMode {
        didSet {
            rive?.fit = Self.fit(for: contentMode)
        }
    }

    // MARK: - [EN] CYLTabBarItemAnimationPlayableView [CN] 可播放视图接口

    /// [EN] Plays from the start: fires the trigger, or sets the boolean to false, then true on a later frame (so a play is
    ///      always a transition, also for a boolean held true), and false after `activeDuration`. With looping on, it plays
    ///      again after each pass (docs/Animated-Item.md, the Rive loop).
    /// [CN] 从头播放：触发 trigger，或先把布尔属性设为 false、在之后的帧设为 true（每次播放都是一次状态切换，保持为 true 的布尔属性也一样），
    ///      `activeDuration` 后设为 false。开启循环时，每次播放后再次播放（docs/Animated-Item.md，Rive 循环）。
    public func playAnimation() {
        guard isLoaded else {
            playsWhenLoaded = true
            return
        }
        guard let instance = viewModelInstance else {
            return
        }
        deactivateTask?.cancel()
        loopTask?.cancel()
        hasPlayed = true
        riveView?.isPaused = false
        if let triggerPropertyPath = configuration.triggerPropertyPath {
            instance.fire(trigger: TriggerProperty(path: triggerPropertyPath))
        } else {
            let property = BoolProperty(path: configuration.activePropertyPath)
            let duration = configuration.activeDuration
            instance.setValue(of: property, to: false)
            deactivateTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled, let self, let instance = self.viewModelInstance else {
                    return
                }
                instance.setValue(of: property, to: true)
                self.isActive = true
                guard duration > 0 else {
                    // [EN] Held until the animation stops. [CN] 保持到动画停止。
                    return
                }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else {
                    return
                }
                instance.setValue(of: property, to: false)
                self.isActive = false
                if !self.loops {
                    self.endHandler?()
                }
            }
        }
        scheduleLoop()
    }

    /// [EN] Called when a pass of a boolean state machine with an `activeDuration` ends and looping is off; a trigger or a
    ///      held boolean (`activeDuration` 0) has no end to tell. [CN] 带 `activeDuration` 的布尔状态机的一遍播放结束且循环关闭时调用；
    ///      trigger 或保持不变的布尔属性（`activeDuration` 为 0）没有可判断的结束。
    public func setAnimationEndHandler(_ handler: (() -> Void)?) {
        endHandler = handler
    }

    /// [EN] Whether the boolean is held true now (a trigger has no state to read). [CN] 布尔属性当前是否保持为 true（trigger 没有可读取的状态）。
    public func isAnimationPlaying() -> Bool {
        isActive
    }

    /// [EN] `cyl_setAnimationViewLoops:`. [CN] `cyl_setAnimationViewLoops:`。
    public func setAnimationLoops(_ loops: Bool) {
        self.loops = loops
        if !loops {
            loopTask?.cancel()
            loopTask = nil
        }
    }

    /// [EN] The next pass while looping: after the boolean goes back to false (plus a pause), else 1.5 s.
    /// [CN] 循环时的下一次播放：布尔属性恢复为 false 之后（再停顿一下），否则 1.5 秒。
    private func scheduleLoop() {
        guard loops else {
            return
        }
        let seconds = (configuration.triggerPropertyPath == nil && configuration.activeDuration > 0)
            ? configuration.activeDuration + CYLRiveTabBarItemAnimationConfiguration.loopPauseSeconds
            : CYLRiveTabBarItemAnimationConfiguration.loopSeconds
        loopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled, let self, self.loops else {
                return
            }
            self.playAnimation()
        }
    }

    /// [EN] A state machine has no last frame: the icon stays in its resting state (the tab selected at launch, #389).
    /// [CN] 状态机没有最后一帧：图标保持静止状态（启动时选中的 Tab，#389）。
    public func showAnimationLastFrame() {
        stopAnimation()
    }

    /// [EN] Stops: the boolean goes back to false. [CN] 停止：布尔属性恢复为 false。
    public func stopAnimation() {
        playsWhenLoaded = false
        deactivateTask?.cancel()
        deactivateTask = nil
        loopTask?.cancel()
        loopTask = nil
        guard configuration.triggerPropertyPath == nil, let instance = viewModelInstance else {
            return
        }
        instance.setValue(of: BoolProperty(path: configuration.activePropertyPath), to: false)
        isActive = false
    }

    /// [EN] Color property path -> color (Dark Mode); nil restores the light colors. [CN] 颜色属性路径 -> 颜色（深色模式）；nil 恢复浅色颜色。
    public func applyAnimationColors(_ colors: [String: UIColor]?) {
        requestedColors = colors
        if isLoaded {
            enqueueRequestedColors()
        }
    }

    // MARK: - [EN] Loading [CN] 加载

    private func load() {
        let configuration = self.configuration
        let fileProvider = self.fileProvider
        if !configuration.fileURL.isFileURL {
            // [EN] A download: the host shows its static image, or its placeholder, until the file is loaded.
            // [CN] 下载中：在文件加载完成之前，宿主显示其静态图片或占位图。
            CYLTabBarItemAnimationMarkLoading(self)
        }
        Task { @MainActor [weak self] in
            do {
                let file = try await fileProvider.file(at: configuration.fileURL)
                guard let self else {
                    return
                }
                let artboard = try await file.createArtboard(configuration.artboardName)
                // [EN] The artboard's default view model instance, kept to play the icon; an artboard may have none.
                // [CN] 画板默认的 view model 实例，保存下来用于播放图标；画板也可能没有。
                // [EN] With `viewModelInstance` / `darkViewModelInstance` (Rive's theme pattern), the named instances; the one
                //      for the current appearance is bound first.
                // [CN] 有 `viewModelInstance` / `darkViewModelInstance`（Rive 的主题方式）时为具名实例；先绑定当前外观对应的实例。
                let source: ViewModelInstanceSource = configuration.viewModelInstanceName
                    .map { .name($0, from: .artboardDefault(artboard)) } ?? .viewModelDefault(from: .artboardDefault(artboard))
                let lightInstance = try? await file.createViewModelInstance(source)
                var darkInstance: ViewModelInstance?
                if let darkName = configuration.darkViewModelInstanceName {
                    darkInstance = try? await file.createViewModelInstance(.name(darkName, from: .artboardDefault(artboard)))
                    #if DEBUG
                    if darkInstance == nil {
                        print("[CYLTabBarController] The Rive file \(configuration.fileURL.lastPathComponent) has no view model instance named \(darkName)")
                    }
                    #endif
                }
                let instance = (self.traitCollection.userInterfaceStyle == .dark ? darkInstance : nil) ?? lightInstance
                let stateMachine = try await artboard.createStateMachine(configuration.stateMachineName, binding: instance)
                self.stateMachine = stateMachine
                if darkInstance != nil {
                    self.lightThemeInstance = lightInstance
                    self.darkThemeInstance = darkInstance
                }
                let rive = try await Rive(file: file,
                                          artboard: artboard,
                                          stateMachine: stateMachine,
                                          fit: Self.fit(for: self.contentMode))
                self.didLoad(rive: rive, viewModelInstance: instance)
                CYLTabBarItemAnimationReportLoaded(self)
            } catch {
                #if DEBUG
                print("[CYLTabBarController] Could not load the Rive tab animation \(configuration.fileURL.lastPathComponent): \(error)")
                #endif
                // [EN] A corrupted file or a failed download: the host shows its image or placeholder.
                // [CN] 文件损坏或下载失败：宿主显示其图片或占位图。
                if let self {
                    CYLTabBarItemAnimationReportFailure(self, error as NSError)
                }
            }
        }
    }

    private func didLoad(rive: Rive, viewModelInstance: ViewModelInstance?) {
        self.rive = rive
        self.viewModelInstance = viewModelInstance
        let riveView = RiveUIView(rive: rive)
        riveView.frame = bounds
        riveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        riveView.isUserInteractionEnabled = false
        riveView.backgroundColor = .clear
        addSubview(riveView)
        self.riveView = riveView
        isLoaded = true
        tintOverlay.apply(currentTintColor, in: self)
        // [EN] Rests on its first frame until it is played (docs/Animated-Item.md): paused once the first frame is drawn.
        // [CN] 在被播放之前停在第一帧：第一帧绘制后暂停。
        Task { @MainActor [weak self, weak riveView] in
            try? await Task.sleep(nanoseconds: Self.firstFrameNanoseconds)
            guard let self, let riveView, self.riveView === riveView, !self.hasPlayed else {
                return
            }
            riveView.isPaused = true
        }
        if let lightColor = configuration.lightColor, let instance = viewModelInstance {
            let path = Self.colorPropertyPath
            let color = Self.riveColor(lightColor)
            // [EN] The light color is the one restored after Dark Mode. [CN] 浅色颜色即退出深色模式后恢复的颜色。
            originalColors[path] = color
            instance.setValue(of: ColorProperty(path: path), to: color)
        }
        if requestedColors != nil {
            enqueueRequestedColors()
        }
        if playsWhenLoaded {
            playsWhenLoaded = false
            playAnimation()
        }
    }

    // MARK: - [EN] Colors [CN] 颜色

    /// [EN] Applies `requestedColors` after the updates already queued, so they keep their order.
    /// [CN] 在已排队的更新之后应用 `requestedColors`，保持顺序。
    private func enqueueRequestedColors() {
        guard let instance = viewModelInstance else {
            return
        }
        let colors = requestedColors
        let previous = colorTask
        colorTask = Task { @MainActor [weak self] in
            await previous?.value
            guard let self else {
                return
            }
            if let colors {
                for (path, color) in colors {
                    let property = ColorProperty(path: path)
                    if self.originalColors[path] == nil, let original = try? await instance.value(of: property) {
                        self.originalColors[path] = original
                    }
                    instance.setValue(of: property, to: Self.riveColor(color))
                    self.overriddenColorPaths.insert(path)
                }
            } else {
                for path in self.overriddenColorPaths {
                    if let original = self.originalColors[path] {
                        instance.setValue(of: ColorProperty(path: path), to: original)
                    }
                }
                self.overriddenColorPaths.removeAll()
            }
        }
    }

    private static func riveColor(_ color: UIColor) -> RiveRuntime.Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            var white: CGFloat = 0
            if color.getWhite(&white, alpha: &alpha) {
                red = white
                green = white
                blue = white
            }
        }
        func byte(_ value: CGFloat) -> UInt8 {
            return UInt8(max(0, min(255, (value * 255).rounded())))
        }
        return RiveRuntime.Color(red: byte(red), green: byte(green), blue: byte(blue), alpha: byte(alpha))
    }

    private static func fit(for contentMode: UIView.ContentMode) -> RiveRuntime.Fit {
        switch contentMode {
        case .scaleToFill:
            return .fill(alignment: .center)
        case .scaleAspectFill:
            return .cover(alignment: .center)
        default:
            return .contain(alignment: .center)
        }
    }
}

/*!
 * [EN] The default `CYLRiveTabBarItemAnimationFileProviding`: one `Worker` for every Rive tab icon, and each .riv file
 *      loaded once, so tabs that use the same file (e.g. one artboard each) share it.
 * [CN] 默认的 `CYLRiveTabBarItemAnimationFileProviding`：所有 Rive Tab 图标共用一个 `Worker`，每个 .riv 文件只加载一次，因此使用同一文件的
 *      Tab（例如各用一个画板）共用它。
 */
@MainActor
final class CYLRiveTabBarItemAnimationFileCache: CYLRiveTabBarItemAnimationFileProviding {

    static let shared = CYLRiveTabBarItemAnimationFileCache()

    private var workerTask: Task<RiveRuntime.Worker, Error>?
    private var fileTasks: [URL: Task<RiveRuntime.File, Error>] = [:]

    func file(at url: URL) async throws -> RiveRuntime.File {
        if let task = fileTasks[url] {
            return try await task.value
        }
        let task = Task { @MainActor () async throws -> RiveRuntime.File in
            let worker = try await self.sharedWorker()
            let source: RiveRuntime.Source
            if url.isFileURL {
                source = .data(try Data(contentsOf: url))
            } else {
                source = .url(url)
            }
            return try await RiveRuntime.File(source: source, worker: worker)
        }
        fileTasks[url] = task
        do {
            return try await task.value
        } catch {
            // [EN] Tried again next time. [CN] 下次重新尝试。
            fileTasks[url] = nil
            throw error
        }
    }

    private func sharedWorker() async throws -> RiveRuntime.Worker {
        if let task = workerTask {
            return try await task.value
        }
        let task = Task { @MainActor () async throws -> RiveRuntime.Worker in
            return try await RiveRuntime.Worker()
        }
        workerTask = task
        do {
            return try await task.value
        } catch {
            workerTask = nil
            throw error
        }
    }
}
#endif

/**
 * [EN] Draws a Rive view's icon in one color, like a template image (`CYLTabBarAnimationOptionTint`): a layer of that color
 *      above the Rive view, composited with "sourceAtop", so only the icon's own pixels take the color. Rive draws with
 *      Metal, so the image itself cannot be tinted. Checked on iOS 27.2 (Example-Rive): the icons keep animating.
 * [CN] 像模板图片一样用一种颜色绘制 Rive 视图的图标（`CYLTabBarAnimationOptionTint`）：在 Rive 视图之上放一个该颜色的图层，以 "sourceAtop"
 *      合成，只有图标本身的像素取该颜色。Rive 用 Metal 绘制，无法直接给图像着色。已在 iOS 27.2（Example-Rive）上检查：图标仍会播放。
 */
@MainActor
final class CYLRiveTintOverlay {
    private var layer: CALayer?

    /// [EN] Draws `color` over `host`'s icon, above its subviews; nil removes the tint. [CN] 在 `host` 的图标上绘制 `color`；nil 移除着色。
    func apply(_ color: UIColor?, in host: UIView) {
        guard let color else {
            layer?.removeFromSuperlayer()
            layer = nil
            return
        }
        let overlay = layer ?? CALayer()
        overlay.compositingFilter = "sourceAtop"
        overlay.backgroundColor = color.resolvedColor(with: host.traitCollection).cgColor
        overlay.frame = host.bounds
        host.layer.addSublayer(overlay)
        layer = overlay
    }

    /// [EN] Keeps the tint over the whole view, on top. [CN] 让着色覆盖整个视图并位于最上层。
    func layout(in host: UIView) {
        guard let overlay = layer else {
            return
        }
        overlay.frame = host.bounds
        if host.layer.sublayers?.last !== overlay {
            host.layer.addSublayer(overlay)
        }
    }
}

