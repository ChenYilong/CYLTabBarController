/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */


import Foundation

import Lottie
import UIKit

/// An Objective-C compatible wrapper around Lottie's Animation class.
/// Use in tandem with CompatibleAnimationView when using Lottie in Objective-C
@objc
public final class CompatibleLOTAnimation: NSObject {
    
    // MARK: Lifecycle
    @objc
    public init(
        filepath: String)
    {
        self.filepath = filepath
        super.init()
    }
    
    
    // MARK: Internal
    internal var animation: LottieAnimation? {
        LottieAnimation.filepath(filepath)
    }
    @objc
    public static func hasCache(key:String) -> Bool {
        
        return LottieAnimationCache.shared?.animation(forKey: key) != nil;
    }
    
    // MARK: Private
    private let filepath: String
}


/// An Objective-C compatible wrapper around Lottie's LottieAnimationView.
@objc
public final class CompatibleLOTAnimationView: UIView {
    
    // MARK: Lifecycle
    
    /// Initializes a compatible AnimationView with a given compatible animation. Defaults to using
    /// the rendering engine specified in LottieConfiguration.shared.
    @objc
    public convenience init(compatibleAnimation: CompatibleLOTAnimation) {
        self.init(compatibleAnimation: compatibleAnimation, compatibleRenderingEngineOption: .shared)
    }
    
    /// Initializes a compatible AnimationView with a given compatible animation and rendering engine
    /// configuration.
    @objc
    public init(
        compatibleAnimation: CompatibleLOTAnimation,
        compatibleRenderingEngineOption: CompatibleRenderingEngineOption)
    {
        animationView = LottieAnimationView(
            animation: compatibleAnimation.animation,
            configuration: CompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption))
        self.compatibleAnimation = compatibleAnimation
        super.init(frame: .zero)
        commonInit()
    }
    
    /// Initializes a compatible AnimationView with the resources asynchronously loaded from a given
    /// URL. Defaults to using the rendering engine specified in LottieConfiguration.shared.
    @objc
    public convenience init(url: URL) {
        self.init(url: url, compatibleRenderingEngineOption: .shared)
    }
    
    /// Initializes a compatible AnimationView with the resources asynchronously loaded from a given
    /// URL using the given rendering engine configuration.
    @objc
    public init(url: URL, compatibleRenderingEngineOption: CompatibleRenderingEngineOption) {
        animationView = LottieAnimationView(
            url: url,
            closure: { _ in },
            configuration: CompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption))
        super.init(frame: .zero)
        commonInit()
    }
    
    /// Initializes a compatible AnimationView from a given Data object specifying the Lottie
    /// animation. Defaults to using the rendering engine specified in LottieConfiguration.shared.
    @objc
    public convenience init(data: Data) {
        self.init(data: data, compatibleRenderingEngineOption: .shared)
    }
    
    /// Initializes a compatible AnimationView from a given Data object specifying the Lottie
    /// animation using the given rendering engine configuration.
    @objc
    public init(data: Data, compatibleRenderingEngineOption: CompatibleRenderingEngineOption) {
        if let animation = try? LottieAnimation.from(data: data) {
            animationView = LottieAnimationView(
                animation: animation,
                configuration: CompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption))
        } else {
            animationView = LottieAnimationView(
                configuration: CompatibleRenderingEngineOption.generateLottieConfiguration(compatibleRenderingEngineOption))
        }
        super.init(frame: .zero)
        commonInit()
    }
    
    @objc
    public override init(frame: CGRect) {
        animationView = LottieAnimationView()
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public
    
    @objc
    public var compatibleAnimation: CompatibleLOTAnimation? {
        didSet {
            animationView.animation = compatibleAnimation?.animation
        }
    }
    
    @objc
    public var loopAnimationCount: CGFloat = 0 {
        didSet {
            animationView.loopMode = loopAnimationCount == -1 ? .loop : .repeat(Float(loopAnimationCount))
        }
    }
    
    @objc
    public override var contentMode: UIView.ContentMode {
        set { animationView.contentMode = newValue }
        get { animationView.contentMode }
    }
    
    @objc
    public var shouldRasterizeWhenIdle: Bool {
        set { animationView.shouldRasterizeWhenIdle = newValue }
        get { animationView.shouldRasterizeWhenIdle }
    }
    
    @objc
    public var currentProgress: CGFloat {
        set { animationView.currentProgress = newValue }
        get { animationView.currentProgress }
    }
    
    @objc
    public var duration: CGFloat {
        animationView.animation?.duration ?? 0.0
    }
    
    @objc
    public var currentTime: TimeInterval {
        set { animationView.currentTime = newValue }
        get { animationView.currentTime }
    }
    
    @objc
    public var currentFrame: CGFloat {
        set { animationView.currentFrame = newValue }
        get { animationView.currentFrame }
    }
    
    @objc
    public var realtimeAnimationFrame: CGFloat {
        animationView.realtimeAnimationFrame
    }
    
    @objc
    public var realtimeAnimationProgress: CGFloat {
        animationView.realtimeAnimationProgress
    }
    
    @objc
    public var animationSpeed: CGFloat {
        set { animationView.animationSpeed = newValue }
        get { animationView.animationSpeed }
    }
    
    @objc
    public var respectAnimationFrameRate: Bool {
        set { animationView.respectAnimationFrameRate = newValue }
        get { animationView.respectAnimationFrameRate }
    }
    
    @objc
    public var isAnimationPlaying: Bool {
        animationView.isAnimationPlaying
    }
    
    @objc
    public func play() {
        play(completion: nil)
    }
    
    @objc
    public func play(completion: ((Bool) -> Void)?) {
        animationView.play(completion: completion)
    }
    
    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromProgress:toProgress:completion which drops the standard "With" naming convention.
    @objc
    public func play(
        fromProgress: CGFloat,
        toProgress: CGFloat,
        completion: ((Bool) -> Void)? = nil)
    {
        animationView.play(
            fromProgress: fromProgress,
            toProgress: toProgress,
            loopMode: nil,
            completion: completion)
    }
    
    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromFrame:toFrame:completion which drops the standard "With" naming convention.
    @objc
    public func play(
        fromFrame: CGFloat,
        toFrame: CGFloat,
        completion: ((Bool) -> Void)? = nil)
    {
        animationView.play(
            fromFrame: fromFrame,
            toFrame: toFrame,
            loopMode: nil,
            completion: completion)
    }
    
    /// Note: When calling this code from Objective-C, the method signature is
    /// playFromMarker:toMarker:completion which drops the standard "With" naming convention.
    @objc
    public func play(
        fromMarker: String,
        toMarker: String,
        completion: ((Bool) -> Void)? = nil)
    {
        animationView.play(
            fromMarker: fromMarker,
            toMarker: toMarker,
            completion: completion)
    }
    
    @objc
    public func play(
        marker: String,
        completion: ((Bool) -> Void)? = nil)
    {
        animationView.play(
            marker: marker,
            completion: completion)
    }
    
    @objc
    public func stop() {
        animationView.stop()
    }
    
    @objc
    public func pause() {
        animationView.pause()
    }
    
    @objc
    public func reloadImages() {
        animationView.reloadImages()
    }
    
    @objc
    public func forceDisplayUpdate() {
        animationView.forceDisplayUpdate()
    }
    
    @objc public func animationProgress(_ progress: CGFloat){
        animationView.currentProgress = progress
    }
    
    @objc
    public func forceDrawingUpdate() {
        animationView.forceDisplayUpdate()
    }
    
    @objc
    public func getValue(
        for keypath: CompatibleAnimationKeypath,
        atFrame: CGFloat)
    -> Any?
    {
        animationView.getValue(
            for: keypath.animationKeypath,
            atFrame: atFrame)
    }
    
    @objc
    public func logHierarchyKeypaths() {
        animationView.logHierarchyKeypaths()
    }
    
    @objc
    public func setColorValue(_ color: UIColor, forKeypath keypath: CompatibleAnimationKeypath) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let colorspace = LottieConfiguration.shared.colorSpace
        
        let convertedColor = color.cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil)
        
        if let components = convertedColor?.components, components.count == 4 {
            red = components[0]
            green = components[1]
            blue = components[2]
            alpha = components[3]
        } else {
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        
        let valueProvider = ColorValueProvider(LottieColor(r: Double(red), g: Double(green), b: Double(blue), a: Double(alpha)))
        animationView.setValueProvider(valueProvider, keypath: keypath.animationKeypath)
    }
    
    @objc
    public func getColorValue(for keypath: CompatibleAnimationKeypath, atFrame: CGFloat) -> UIColor? {
        let value = animationView.getValue(for: keypath.animationKeypath, atFrame: atFrame)
        guard let colorValue = value as? LottieColor else {
            return nil;
        }
        
        return UIColor(
            red: CGFloat(colorValue.r),
            green: CGFloat(colorValue.g),
            blue: CGFloat(colorValue.b),
            alpha: CGFloat(colorValue.a))
    }
    
    @objc
    public func addSubview(
        _ subview: AnimationSubview,
        forLayerAt keypath: CompatibleAnimationKeypath)
    {
        animationView.addSubview(
            subview,
            forLayerAt: keypath.animationKeypath)
    }
    
    @objc
    public func convert(
        rect: CGRect,
        toLayerAt keypath: CompatibleAnimationKeypath?)
    -> CGRect
    {
        animationView.convert(
            rect,
            toLayerAt: keypath?.animationKeypath) ?? .zero
    }
    
    @objc
    public func convert(
        point: CGPoint,
        toLayerAt keypath: CompatibleAnimationKeypath?)
    -> CGPoint
    {
        animationView.convert(
            point,
            toLayerAt: keypath?.animationKeypath) ?? .zero
    }
    
    @objc
    public func progressTime(forMarker named: String) -> CGFloat {
        animationView.progressTime(forMarker: named) ?? 0
    }
    
    @objc
    public func frameTime(forMarker named: String) -> CGFloat {
        animationView.frameTime(forMarker: named) ?? 0
    }
    
    @objc
    public func durationFrameTime(forMarker named: String) -> CGFloat {
        animationView.durationFrameTime(forMarker: named) ?? 0
    }
    
    // MARK: Private
    
    private let animationView: LottieAnimationView
    
    private func commonInit() {
        setUpViews()
    }
    
    private func setUpViews() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animationView)
        animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
