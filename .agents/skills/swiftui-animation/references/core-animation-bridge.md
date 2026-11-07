# Core Animation Bridge

Patterns for bridging Core Animation (QuartzCore) with SwiftUI. Use when SwiftUI's built-in animation system is insufficient -- typically for performance-critical layer animations, layer-only properties, additive animations, or direct CALayer manipulation. Overflow reference for the `swiftui-animation` skill.

## Contents

- [When to Drop Below SwiftUI Animations](#when-to-drop-below-swiftui-animations)
- [CABasicAnimation](#cabasicanimation)
- [CAKeyframeAnimation](#cakeyframeanimation)
- [CASpringAnimation](#caspringanimation)
- [CAAnimationGroup](#caanimationgroup)
- [CADisplayLink](#cadisplaylink)
- [UIViewRepresentable Wrapper for CA Layers](#uiviewrepresentable-wrapper-for-ca-layers)
- [Bridging CA Animations with SwiftUI State](#bridging-ca-animations-with-swiftui-state)
- [Performance Considerations](#performance-considerations)

## When to Drop Below SwiftUI Animations

SwiftUI's animation system covers most use cases. Drop to Core Animation only when:

| Scenario | Why CA Is Needed |
|----------|-----------------|
| **CALayer-specific timing** | `CAMediaTimingFunction` keeps timing attached to direct layer animations |
| **Layer-specific properties** (shadowPath, borderWidth, etc.) | SwiftUI does not expose all CALayer animatable properties |
| **Additive animations** | CA supports additive blending of multiple concurrent animations on the same property |
| **Frame-synchronized drawing** | `CADisplayLink` provides precise frame timing for custom rendering |
| **Performance-critical particle/effects** | Direct layer manipulation avoids SwiftUI's diffing overhead |
| **Animation along a path** | `CAKeyframeAnimation` supports `CGPath`-based animation paths |

Do not drop to Core Animation just for a cubic Bezier timing curve: SwiftUI has
`UnitCurve.bezier(startControlPoint:endControlPoint:)` and
`Animation.timingCurve(_:duration:)`. If SwiftUI's `withAnimation`,
`PhaseAnimator`, or `KeyframeAnimator` can achieve the effect, prefer them.
Core Animation bridging adds complexity and requires explicit
`UIViewRepresentable` wrappers.

## CABasicAnimation

[`CABasicAnimation`](https://sosumi.ai/documentation/quartzcore/cabasicanimation) interpolates a single layer property between two values.

### Basic Usage

```swift
import QuartzCore

let animation = CABasicAnimation(keyPath: "opacity")
animation.fromValue = 0.0
animation.toValue = 1.0
animation.duration = 0.3
animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

// Apply to a layer
layer.add(animation, forKey: "fadeIn")
layer.opacity = 1.0 // Set the final model value
```

### Custom Bezier Timing

For SwiftUI view animations, prefer
`Animation.timingCurve(.bezier(startControlPoint:endControlPoint:), duration:)`.
Use `CAMediaTimingFunction` when you are already animating a `CALayer`
property directly.

```swift
let timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0)

let animation = CABasicAnimation(keyPath: "position.y")
animation.fromValue = layer.position.y
animation.toValue = layer.position.y - 100
animation.duration = 0.5
animation.timingFunction = timingFunction
animation.fillMode = .forwards
animation.isRemovedOnCompletion = false

layer.add(animation, forKey: "customBezier")
```

### Shadow Path Animation

```swift
// Animate shadowPath -- not possible in pure SwiftUI
let animation = CABasicAnimation(keyPath: "shadowPath")
animation.fromValue = layer.shadowPath
animation.toValue = UIBezierPath(roundedRect: newBounds, cornerRadius: 16).cgPath
animation.duration = 0.3
animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

layer.shadowPath = UIBezierPath(roundedRect: newBounds, cornerRadius: 16).cgPath
layer.add(animation, forKey: "shadowPath")
```

**Important:** Always set the model value (the property on the layer itself) to the final state. Core Animation operates on a separate presentation layer -- without setting the model value, the layer snaps back when the animation completes.

> **Docs:** [CABasicAnimation](https://sosumi.ai/documentation/quartzcore/cabasicanimation) | [CAMediaTimingFunction](https://sosumi.ai/documentation/quartzcore/camediatimingfunction) | [UnitCurve.bezier](https://sosumi.ai/documentation/swiftui/unitcurve/bezier(startcontrolpoint:endcontrolpoint:)) | [Animation.timingCurve(_:duration:)](https://sosumi.ai/documentation/swiftui/animation/timingcurve(_:duration:))

## CAKeyframeAnimation

[`CAKeyframeAnimation`](https://sosumi.ai/documentation/quartzcore/cakeyframeanimation) animates a property through a sequence of values or along a path.

### Value-Based Keyframes

```swift
let animation = CAKeyframeAnimation(keyPath: "transform.scale")
animation.values = [1.0, 1.3, 0.9, 1.05, 1.0]
animation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0] // Normalized [0..1]
animation.duration = 0.6
animation.timingFunctions = [
    CAMediaTimingFunction(name: .easeOut),
    CAMediaTimingFunction(name: .easeIn),
    CAMediaTimingFunction(name: .easeOut),
    CAMediaTimingFunction(name: .easeInEaseOut)
]

layer.add(animation, forKey: "bounceScale")
```

### Path-Based Animation

```swift
// Animate position along a CGPath -- unique to CAKeyframeAnimation
let path = CGMutablePath()
path.move(to: CGPoint(x: 50, y: 300))
path.addCurve(
    to: CGPoint(x: 300, y: 50),
    control1: CGPoint(x: 100, y: 50),
    control2: CGPoint(x: 250, y: 300)
)

let animation = CAKeyframeAnimation(keyPath: "position")
animation.path = path
animation.duration = 1.5
animation.rotationMode = .rotateAuto // Rotate along the tangent
animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

layer.add(animation, forKey: "pathAnimation")
layer.position = CGPoint(x: 300, y: 50)
```

### Shake Animation (Discrete Keyframes)

```swift
func shakeAnimation() -> CAKeyframeAnimation {
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.values = [0, -10, 10, -8, 8, -5, 5, 0]
    animation.keyTimes = [0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 1.0]
    animation.duration = 0.5
    animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
    return animation
}
```

> **Docs:** [CAKeyframeAnimation](https://sosumi.ai/documentation/quartzcore/cakeyframeanimation)

## CASpringAnimation

[`CASpringAnimation`](https://sosumi.ai/documentation/quartzcore/caspringanimation) applies spring physics to a layer property. It extends `CABasicAnimation` with physical spring attributes.

### Physical Spring Parameters

```swift
let spring = CASpringAnimation(keyPath: "transform.scale")
spring.fromValue = 0.0
spring.toValue = 1.0
spring.mass = 1.0
spring.stiffness = 200.0
spring.damping = 10.0
spring.initialVelocity = 0.0
spring.duration = spring.settlingDuration // Use the physics-calculated duration

layer.add(spring, forKey: "springScale")
layer.transform = CATransform3DIdentity
```

### Perceptual Spring (iOS 17+)

```swift
let spring = CASpringAnimation(perceptualDuration: 0.5, bounce: 0.3)
spring.keyPath = "position.y"
spring.fromValue = layer.position.y
spring.toValue = layer.position.y - 100

layer.add(spring, forKey: "perceptualSpring")
layer.position.y -= 100
```

The `perceptualDuration` and `bounce` initializer matches SwiftUI's `Spring(duration:bounce:)`, making it easier to keep CA and SwiftUI spring behaviors consistent.

### Matching SwiftUI Spring Presets

| SwiftUI Preset | CA Equivalent |
|---------------|---------------|
| `.smooth` | `CASpringAnimation(perceptualDuration: 0.5, bounce: 0.0)` |
| `.snappy` | `CASpringAnimation(perceptualDuration: 0.4, bounce: 0.15)` |
| `.bouncy` | `CASpringAnimation(perceptualDuration: 0.5, bounce: 0.3)` |

> **Docs:** [CASpringAnimation](https://sosumi.ai/documentation/quartzcore/caspringanimation)

## CAAnimationGroup

[`CAAnimationGroup`](https://sosumi.ai/documentation/quartzcore/caanimationgroup) runs multiple animations concurrently on the same layer.

```swift
let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
scaleAnim.fromValue = 0.5
scaleAnim.toValue = 1.0

let opacityAnim = CABasicAnimation(keyPath: "opacity")
opacityAnim.fromValue = 0.0
opacityAnim.toValue = 1.0

let group = CAAnimationGroup()
group.animations = [scaleAnim, opacityAnim]
group.duration = 0.4
group.timingFunction = CAMediaTimingFunction(name: .easeOut)

layer.add(group, forKey: "appearGroup")
layer.transform = CATransform3DIdentity
layer.opacity = 1.0
```

> **Docs:** [CAAnimationGroup](https://sosumi.ai/documentation/quartzcore/caanimationgroup)

## CADisplayLink

[`CADisplayLink`](https://sosumi.ai/documentation/quartzcore/cadisplaylink) is a timer synchronized to the display's refresh rate. Use it for frame-accurate custom drawing, particle systems, or manual animation loops.

### Basic Display Link

```swift
import QuartzCore

final class FrameAnimator {
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(onFrame))
        displayLink?.add(to: .main, forMode: .common)
        startTime = CACurrentMediaTime()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func onFrame(_ link: CADisplayLink) {
        let elapsed = link.timestamp - startTime
        let progress = min(elapsed / 2.0, 1.0) // 2-second animation

        // Update rendering based on progress
        updateAnimation(progress: progress)

        if progress >= 1.0 {
            stop()
        }
    }

    private func updateAnimation(progress: Double) {
        // Custom per-frame rendering logic
    }
}
```

### ProMotion Frame Rate Hints

On ProMotion displays, use `preferredFrameRateRange` to request a sustainable refresh-rate range that balances smoothness and power. Treat the values as hints: the system can choose different rates based on hardware, power, thermal state, and other onscreen animation.

```swift
displayLink?.preferredFrameRateRange = CAFrameRateRange(
    minimum: 30,
    maximum: 120,
    preferred: 60
)
```

| Hint | Use Case |
|-------|----------|
| `preferred: 120` | Short, high-impact motion when the app can sustain it |
| `preferred: 60` | Standard interactive animations |
| `preferred: 30` | Ambient/slow animations, power saving |

**Important:** Always call `invalidate()` when done. A running `CADisplayLink` prevents the CPU from idling and drains battery. Drive custom animation from `targetTimestamp`, and scale rendering detail or work per frame to the refresh rate the system actually selects.

> **Docs:** [CADisplayLink](https://sosumi.ai/documentation/quartzcore/cadisplaylink) | [Optimizing ProMotion refresh rates](https://sosumi.ai/documentation/quartzcore/optimizing-promotion-refresh-rates-for-iphone-13-pro-and-ipad-pro)

## UIViewRepresentable Wrapper for CA Layers

To use Core Animation layers inside SwiftUI, wrap them in a `UIViewRepresentable`.

### Animated Layer View

```swift
import SwiftUI
import QuartzCore

struct AnimatedLayerView: UIViewRepresentable {
    var isAnimating: Bool
    var color: Color

    func makeUIView(context: Context) -> AnimatedLayerUIView {
        let view = AnimatedLayerUIView()
        return view
    }

    func updateUIView(_ uiView: AnimatedLayerUIView, context: Context) {
        uiView.updateColor(UIColor(color))

        if isAnimating {
            uiView.startAnimation()
        } else {
            uiView.stopAnimation()
        }
    }

    static func dismantleUIView(_ uiView: AnimatedLayerUIView, coordinator: ()) {
        uiView.stopAnimation()
    }
}
```

### The Backing UIView

```swift
final class AnimatedLayerUIView: UIView {
    private let animationLayer = CAShapeLayer()
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        animationLayer.fillColor = UIColor.systemBlue.cgColor
        animationLayer.strokeColor = nil
        layer.addSublayer(animationLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        animationLayer.frame = bounds
        updatePath()
    }

    func updateColor(_ color: UIColor) {
        // Animate color change at the CA layer level
        let animation = CABasicAnimation(keyPath: "fillColor")
        animation.fromValue = animationLayer.fillColor
        animation.toValue = color.cgColor
        animation.duration = 0.3

        animationLayer.fillColor = color.cgColor
        animationLayer.add(animation, forKey: "colorChange")
    }

    func startAnimation() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(
            minimum: 30, maximum: 60, preferred: 60
        )
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        phase += 0.05
        updatePath()
    }

    private func updatePath() {
        let path = CGMutablePath()
        let width = bounds.width
        let height = bounds.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, to: width, by: 2) {
            let relativeX = x / width
            let y = midY + sin((relativeX * .pi * 4) + phase) * (height * 0.3)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        animationLayer.path = path
    }
}
```

### SwiftUI Usage

```swift
struct WaveView: View {
    @State private var isAnimating = true

    var body: some View {
        Button { isAnimating.toggle() } label: {
            AnimatedLayerView(isAnimating: isAnimating, color: .blue)
                .frame(height: 200)
                .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
```

### Key Rules for CA-in-SwiftUI Wrappers

1. **Create layers in `makeUIView` or the UIView subclass initializer**, not in `updateUIView`.
2. **Stop display links in `dismantleUIView`** to prevent leaks and background CPU usage.
3. **Guard against redundant animation starts** in `updateUIView` -- it runs on every SwiftUI state change.
4. **Set model values alongside CA animations** so the layer state is correct after animations complete.

## Bridging CA Animations with SwiftUI State

### Triggering CA Animations from SwiftUI State Changes

```swift
struct PulseButton: UIViewRepresentable {
    var pulseCount: Int // Increment to trigger a pulse

    func makeUIView(context: Context) -> PulseUIView {
        PulseUIView()
    }

    func updateUIView(_ uiView: PulseUIView, context: Context) {
        // Only animate when pulseCount changes, not on every update
        if context.coordinator.lastPulseCount != pulseCount {
            context.coordinator.lastPulseCount = pulseCount
            uiView.pulse()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastPulseCount = 0
    }
}

final class PulseUIView: UIView {
    private let pulseLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        pulseLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        layer.addSublayer(pulseLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = min(bounds.width, bounds.height)
        let rect = CGRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size
        )
        pulseLayer.path = UIBezierPath(ovalIn: rect).cgPath
    }

    func pulse() {
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 1.5

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 1.0
        opacityAnim.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [scaleAnim, opacityAnim]
        group.duration = 0.6
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)

        pulseLayer.add(group, forKey: "pulse")
    }
}
```

### Reading CA Animation Completion in SwiftUI

Use `CAAnimationDelegate` on the Coordinator to report animation completion back to SwiftUI:

```swift
struct AnimatedBadge: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var isAnimationComplete: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let badge = CAShapeLayer()
        badge.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).cgPath
        badge.fillColor = UIColor.systemRed.cgColor
        badge.name = "badge"
        view.layer.addSublayer(badge)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self

        if isPresented && !context.coordinator.didAnimateIn {
            context.coordinator.didAnimateIn = true
            animateIn(uiView, delegate: context.coordinator)
        } else if !isPresented {
            context.coordinator.didAnimateIn = false
        }
    }

    private func animateIn(_ uiView: UIView, delegate: CAAnimationDelegate) {
        guard let badge = uiView.layer.sublayers?.first(where: { $0.name == "badge" }) else { return }

        let spring = CASpringAnimation(perceptualDuration: 0.5, bounce: 0.3)
        spring.keyPath = "transform.scale"
        spring.fromValue = 0.0
        spring.toValue = 1.0
        spring.delegate = delegate

        badge.add(spring, forKey: "appear")
        badge.transform = CATransform3DIdentity
    }

    final class Coordinator: NSObject, CAAnimationDelegate {
        var parent: AnimatedBadge
        var didAnimateIn = false

        init(_ parent: AnimatedBadge) { self.parent = parent }

        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            if flag {
                parent.isAnimationComplete = true
            }
        }
    }
}
```

## Performance Considerations

### CA vs. SwiftUI Animation Performance

| Aspect | SwiftUI Animation | Core Animation |
|--------|------------------|----------------|
| **Rendering** | View diffing + render tree | Direct layer manipulation |
| **Thread** | Main thread for state, render server for compositing | Same -- render server composites |
| **Overhead** | SwiftUI body re-evaluation per frame (for animatable) | No body re-evaluation |
| **Best for** | Standard UI transitions | Particle effects, wave animations, complex paths |

### Guidelines

- **Avoid mixing CA animations and SwiftUI animations on the same property.** They use separate animation systems and will conflict.
- **Use `CADisplayLink` sparingly.** A running display link prevents the CPU from sleeping. Always invalidate when not needed.
- **Prefer `CAShapeLayer` for path-based animations** over redrawing in `draw(_:)`. Shape layers are GPU-accelerated.
- **Set `shouldRasterize = true`** on complex static sublayer trees to cache them as bitmaps, but disable it during animation (rasterization prevents smooth per-frame updates).
- **Match CA spring parameters to SwiftUI springs** using the `perceptualDuration:bounce:` initializer so animations feel consistent across the bridge boundary.
