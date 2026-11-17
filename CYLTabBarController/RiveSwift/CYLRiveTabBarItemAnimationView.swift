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
        numberValues = (options[CYLTabBarAnimationOption.riveNumberValues.rawValue] ?? "").split(separator: ",")
            .compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
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

    /// [EN] "#RRGGBB" or "#RRGGBBAA" ("#" optional). [CN] "#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略）。
    private static func color(hex: String) -> UIColor? {
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
    private var isLoaded = false
    private var playsWhenLoaded = false
    private var deactivateTask: Task<Void, Never>?
    /// [EN] Plays again after each pass (`cyl_setAnimationViewLoops:`). [CN] 每次播放后再次播放（`cyl_setAnimationViewLoops:`）。
    private var loops = false
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
    init(configuration: CYLRiveTabBarItemAnimationConfiguration, fileProvider: CYLRiveTabBarItemAnimationFileProviding) {
        self.configuration = configuration
        self.fileProvider = fileProvider
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // [EN] The tab button describes itself to VoiceOver. [CN] 由 Tab 按钮向 VoiceOver 描述自己。
        accessibilityElementsHidden = true
        load()
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
                guard duration > 0 else {
                    // [EN] Held until the animation stops. [CN] 保持到动画停止。
                    return
                }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else {
                    return
                }
                instance.setValue(of: property, to: false)
            }
        }
        scheduleLoop()
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
                let instance = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
                let stateMachine = try await artboard.createStateMachine(configuration.stateMachineName, binding: instance)
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
