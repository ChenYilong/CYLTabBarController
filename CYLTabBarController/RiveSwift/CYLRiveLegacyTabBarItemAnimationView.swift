//
//  CYLRiveLegacyTabBarItemAnimationView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Rive files made before data binding have no view model: they are played through state machine inputs or linear
//      animations, which Rive (6.29+) keeps only in its legacy, deprecated API. This view is a second implementation of
//      the same shared interfaces (`CYLTabBarItemAnimationPlayableView`, `CYLTabBarItemAnimationViewProviding`), chosen
//      by `CYLRiveTabBarItemAnimationView` when a tab's options name an input or an animation. The class is deprecated
//      together with the API it wraps, so its uses of that API add no warning, and no other code names it (it is
//      resolved by its Objective-C name). Compiled only with the Rive runtime.
// [CN] 数据绑定出现之前制作的 Rive 文件没有 view model：它们通过状态机输入或线性动画播放，而 Rive（6.29+）只在旧版、已废弃的 API 中
//      保留了这些功能。本视图是同一组共用接口（`CYLTabBarItemAnimationPlayableView`、`CYLTabBarItemAnimationViewProviding`）的第二个实现，
//      当 Tab 的选项指定了输入或动画时，由 `CYLRiveTabBarItemAnimationView` 选用。该类与其包装的 API 一起标记为废弃，因此使用该 API 不会产生
//      警告，且没有其他代码直接引用它（按其 Objective-C 名称解析）。仅在引入 Rive 运行时时编译。
#if canImport(RiveRuntime)
import UIKit
import RiveRuntime

@available(*, deprecated, message: "Wraps Rive's legacy API for .riv files without a view model; created only through CYLTabBarItemAnimationViewProviding.")
@objc(CYLRiveLegacyTabBarItemAnimationView)
public final class CYLRiveLegacyTabBarItemAnimationView: UIView, CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding, CYLRiveFileInspecting {

    private let configuration: CYLRiveTabBarItemAnimationConfiguration
    private let viewModel: RiveViewModel
    private var deactivateTask: Task<Void, Never>?
    /// [EN] Plays again after each pass (`cyl_setAnimationViewLoops:`). [CN] 每次播放后再次播放（`cyl_setAnimationViewLoops:`）。
    private var loops = false
    private var loopTask: Task<Void, Never>?

    // MARK: - [EN] CYLRiveFileInspecting [CN] 文件检查接口

    /// [EN] A local file without a view model: `CYLRiveTabBarItemAnimationView` plays it here (house.riv), not through data binding.
    /// [CN] 没有 view model 的本地文件：由 `CYLRiveTabBarItemAnimationView` 交给本视图播放（house.riv），而不是通过数据绑定。
    public static func cylFileHasNoViewModel(_ fileURL: URL) -> Bool {
        guard fileURL.isFileURL, let data = try? Data(contentsOf: fileURL),
              let file = try? RiveFile(data: data, loadCdn: false) else {
            return false
        }
        return file.viewModelCount == 0
    }

    // MARK: - [EN] CYLTabBarItemAnimationViewProviding [CN] 视图工厂接口

    public static func makeAnimationView(fileURL: URL, options: [String: String], contentMode: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)? {
        let configuration = CYLRiveTabBarItemAnimationConfiguration(fileURL: fileURL, options: options)
        guard fileURL.isFileURL,
              let data = try? Data(contentsOf: fileURL),
              let file = try? RiveFile(data: data, loadCdn: false),
              isValid(configuration, in: file) else {
            #if DEBUG
            print("[CYLTabBarController] Could not load the Rive tab animation \(fileURL.lastPathComponent) with \(options)")
            #endif
            return nil
        }
        let view = CYLRiveLegacyTabBarItemAnimationView(configuration: configuration, file: file)
        view.contentMode = contentMode
        return view
    }

    /// [EN] `RiveViewModel` traps on a wrong name, so the names are checked first. [CN] `RiveViewModel` 遇到错误的名称会崩溃，因此先检查名称。
    private static func isValid(_ configuration: CYLRiveTabBarItemAnimationConfiguration, in file: RiveFile) -> Bool {
        guard let artboard = try? (configuration.artboardName.map { try file.artboard(fromName: $0) } ?? file.artboard()) else {
            return false
        }
        if let animationName = configuration.animationName {
            return (try? artboard.animation(fromName: animationName)) != nil
        }
        if let stateMachineName = configuration.stateMachineName {
            return (try? artboard.stateMachine(fromName: stateMachineName)) != nil
        }
        return true
    }

    /// [EN] The template tint (`CYLTabBarAnimationOptionTint`). [CN] 模板着色（`CYLTabBarAnimationOptionTint`）。
    private let tintOverlay = CYLRiveTintOverlay()
    /// [EN] The last title color, kept for a file that loads later. [CN] 最近的标题颜色，供稍后加载的文件使用。
    private var titleTintColor: UIColor?

    private init(configuration: CYLRiveTabBarItemAnimationConfiguration, file: RiveFile) {
        self.configuration = configuration
        let model = RiveModel(riveFile: file)
        if let animationName = configuration.animationName {
            // [EN] A linear animation, played on demand. [CN] 线性动画，按需播放。
            viewModel = RiveViewModel(model, animationName: animationName, fit: .contain, alignment: .center,
                                      autoPlay: false, artboardName: configuration.artboardName)
        } else {
            // [EN] A state machine, resting on its first frame until it is played (docs/Animated-Item.md): a file that moves
            //      by itself (shapes.riv, truck.riv) no longer runs from launch. Every play calls `play()`.
            // [CN] 状态机，在被播放之前停在第一帧：会自行运动的文件（shapes.riv、truck.riv）不再从启动起就运动。每次播放都会调用 `play()`。
            viewModel = RiveViewModel(model, stateMachineName: configuration.stateMachineName, fit: .contain, alignment: .center,
                                      autoPlay: false, artboardName: configuration.artboardName)
        }
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // [EN] The tab button describes itself to VoiceOver. [CN] 由 Tab 按钮向 VoiceOver 描述自己。
        accessibilityElementsHidden = true
        let riveView = viewModel.createRiveView()
        riveView.frame = bounds
        riveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        riveView.isUserInteractionEnabled = false
        riveView.backgroundColor = .clear
        addSubview(riveView)
        tintOverlay.apply(configuration.fixedTintColor, in: self)
    }

    /// [EN] `cyl_applyAnimationViewTintColor:`: the tab's title color, drawn when the `tint` option is "title".
    /// [CN] `cyl_applyAnimationViewTintColor:`：Tab 的标题颜色，`tint` 选项为 "title" 时绘制。
    public func applyAnimationTintColor(_ color: UIColor?) {
        guard configuration.tintFollowsTitle else {
            return
        }
        titleTintColor = color
        tintOverlay.apply(color, in: self)
    }

    /// [EN] Keeps the tint over the Rive view. [CN] 让着色覆盖 Rive 视图。
    override public func layoutSubviews() {
        super.layoutSubviews()
        tintOverlay.layout(in: self)
    }


    /// [EN] Not used from Interface Builder. [CN] 不支持从 Interface Builder 创建。
    public required init?(coder _: NSCoder) {
        return nil
    }

    /// [EN] `tabBarItemAnimationViewContentMode` -> Rive's fit. [CN] `tabBarItemAnimationViewContentMode` 对应 Rive 的 fit。
    override public var contentMode: UIView.ContentMode {
        didSet {
            switch contentMode {
            case .scaleToFill: viewModel.fit = .fill
            case .scaleAspectFill: viewModel.fit = .cover
            default: viewModel.fit = .contain
            }
        }
    }

    // MARK: - [EN] CYLTabBarItemAnimationPlayableView [CN] 可播放视图接口

    /// [EN] Plays from the start (docs/Animated-Item.md, the Rive loop): a linear animation restarts; a trigger fires; an input
    ///      the state machine has goes to NO, then YES on a later frame, so every play is a transition (a held input,
    ///      duration 0, used to play once), and back to NO after the duration; a state machine whose input is missing or
    ///      not named restarts (house.riv, shapes.riv). With looping on, it plays again after each pass.
    /// [CN] 从头播放（docs/Animated-Item.md，Rive 循环）：线性动画重新开始；trigger 触发；状态机中存在的输入先设为 NO，在之后的帧再设为 YES，每次
    ///      播放都是一次状态切换（保持的输入、时长为 0 时以前只播放一次），经过时长后恢复为 NO；缺少或未指定输入的状态机重新开始（house.riv、shapes.riv）。
    ///      开启循环时，每次播放后再次播放。
    public func playAnimation() {
        play(fromLoop: false)
    }

    /// [EN] `fromLoop`: a loop pass, which leaves a file that is still moving on its own alone (shapes.riv, truck.riv loop by
    ///      themselves; resetting them every pass cut them short). [CN] `fromLoop`：一次循环，不打断仍在自行运动的文件（shapes.riv、truck.riv
    ///      自身循环；每次循环重置会打断它们）。
    private func play(fromLoop: Bool) {
        let usableInput = configuration.stateMachineInput.map(hasInput) ?? false
        if fromLoop, configuration.animationName == nil, configuration.triggerInput == nil, configuration.numberInput == nil, !usableInput,
           viewModel.isPlaying {
            scheduleLoop()
            return
        }
        deactivateTask?.cancel()
        loopTask?.cancel()
        if let animationName = configuration.animationName {
            // [EN] stop() goes back to the start, so a finished one-shot plays again. [CN] stop() 回到开头，播放完毕的单次动画可以再次播放。
            viewModel.stop()
            viewModel.play(animationName: animationName)
        } else if let triggerInput = configuration.triggerInput {
            // [EN] A trigger does nothing once its state machine has reached the end (check.riv stayed on its finished check):
            //      restart the state machine, then fire it a frame later.
            // [CN] 状态机到达结束状态后 trigger 不再起作用（check.riv 停在完成的对勾上）：先重新开始状态机，一帧之后再触发。
            viewModel.reset()
            viewModel.play()
            deactivateTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled, let self else {
                    return
                }
                self.viewModel.triggerInput(triggerInput)
                self.viewModel.play()
            }
        } else if let name = configuration.numberInput, let number = numberInput(name) {
            // [EN] The next value: a state machine that moves only when a number changes (house.riv's Rooms) plays each time.
            // [CN] 下一个值：只在数字变化时运动的状态机（house.riv 的 Rooms）每次都会播放。
            viewModel.setInput(name, value: configuration.nextNumber(after: number.value()))
            viewModel.play()
        } else if let input = configuration.stateMachineInput, usableInput {
            viewModel.setInput(input, value: false)
            let duration = configuration.activeDuration
            deactivateTask = Task { @MainActor [weak self] in
                // [EN] A frame later: the state machine sees NO, then YES. [CN] 一帧之后：状态机先看到 NO，再看到 YES。
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled, let self else {
                    return
                }
                self.viewModel.setInput(input, value: true)
                self.viewModel.play()
                guard duration > 0 else {
                    return
                }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else {
                    return
                }
                self.viewModel.setInput(input, value: false)
            }
        } else {
            viewModel.reset()
            viewModel.play()
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

    /// [EN] The next pass while looping: after the input goes back to NO (plus a pause), the animation's length, or 1.5 s.
    /// [CN] 循环时的下一次播放：输入恢复为 NO 之后（再停顿一下）、动画时长，或 1.5 秒。
    private func scheduleLoop() {
        guard loops else {
            return
        }
        var seconds = CYLRiveTabBarItemAnimationConfiguration.loopSeconds
        if configuration.stateMachineInput != nil, configuration.activeDuration > 0 {
            seconds = configuration.activeDuration + CYLRiveTabBarItemAnimationConfiguration.loopPauseSeconds
        } else if configuration.animationName != nil, let animation = viewModel.riveModel?.animation,
                  animation.effectiveDurationInSeconds() > 0 {
            seconds = TimeInterval(animation.effectiveDurationInSeconds())
        }
        loopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled, let self, self.loops else {
                return
            }
            self.play(fromLoop: true)
        }
    }

    /// [EN] Whether the state machine has the input (RiveRuntime only logs a missing one). [CN] 状态机是否有该输入（RiveRuntime 对不存在的输入只打印日志）。
    private func hasInput(_ name: String) -> Bool {
        guard let stateMachine = viewModel.riveModel?.stateMachine else {
            return false
        }
        return (try? stateMachine.input(fromName: name)) != nil
    }

    /// [EN] The state machine's number input, nil when it has none or it is not a number. [CN] 状态机的数字输入；没有或不是数字时为 nil。
    private func numberInput(_ name: String) -> RiveSMINumber? {
        return (try? viewModel.riveModel?.stateMachine?.input(fromName: name)) as? RiveSMINumber
    }

    /// [EN] The resting state, without playing (#389). [CN] 静止状态，不播放（#389）。
    public func showAnimationLastFrame() {
        stopAnimation()
    }

    /// [EN] The input goes back to NO; an animation stops. [CN] 输入恢复为 NO；动画停止。
    public func stopAnimation() {
        deactivateTask?.cancel()
        deactivateTask = nil
        loopTask?.cancel()
        loopTask = nil
        if configuration.animationName != nil {
            viewModel.stop()
        } else if let input = configuration.stateMachineInput {
            viewModel.setInput(input, value: false)
        }
    }
}
#endif
