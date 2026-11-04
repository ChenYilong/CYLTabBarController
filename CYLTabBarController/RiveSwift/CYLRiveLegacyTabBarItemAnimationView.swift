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
public final class CYLRiveLegacyTabBarItemAnimationView: UIView, CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding {

    private let configuration: CYLRiveTabBarItemAnimationConfiguration
    private let viewModel: RiveViewModel
    private var deactivateTask: Task<Void, Never>?

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

    private init(configuration: CYLRiveTabBarItemAnimationConfiguration, file: RiveFile) {
        self.configuration = configuration
        let model = RiveModel(riveFile: file)
        if let animationName = configuration.animationName {
            // [EN] A linear animation, played on demand. [CN] 线性动画，按需播放。
            viewModel = RiveViewModel(model, animationName: animationName, fit: .contain, alignment: .center,
                                      autoPlay: false, artboardName: configuration.artboardName)
        } else {
            // [EN] A state machine, running from the start (it waits for its inputs). [CN] 状态机，从一开始就运行（等待输入）。
            viewModel = RiveViewModel(model, stateMachineName: configuration.stateMachineName, fit: .contain, alignment: .center,
                                      autoPlay: true, artboardName: configuration.artboardName)
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

    /// [EN] Fires the trigger, sets the input to YES (back to NO after the duration, unless it is 0), or plays the animation.
    /// [CN] 触发 trigger、把输入设为 YES（经过指定时长后恢复为 NO，时长为 0 时保持），或播放动画。
    public func playAnimation() {
        if let animationName = configuration.animationName {
            viewModel.play(animationName: animationName)
            return
        }
        if let triggerInput = configuration.triggerInput {
            viewModel.triggerInput(triggerInput)
            return
        }
        guard let input = configuration.stateMachineInput else {
            return
        }
        deactivateTask?.cancel()
        viewModel.setInput(input, value: true)
        guard configuration.activeDuration > 0 else {
            return
        }
        let nanoseconds = UInt64(configuration.activeDuration * 1_000_000_000)
        deactivateTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled, let self else {
                return
            }
            self.viewModel.setInput(input, value: false)
        }
    }

    /// [EN] The resting state, without playing (#389). [CN] 静止状态，不播放（#389）。
    public func showAnimationLastFrame() {
        stopAnimation()
    }

    /// [EN] The input goes back to NO; an animation stops. [CN] 输入恢复为 NO；动画停止。
    public func stopAnimation() {
        deactivateTask?.cancel()
        deactivateTask = nil
        if configuration.animationName != nil {
            viewModel.stop()
        } else if let input = configuration.stateMachineInput {
            viewModel.setInput(input, value: false)
        }
    }
}
#endif
