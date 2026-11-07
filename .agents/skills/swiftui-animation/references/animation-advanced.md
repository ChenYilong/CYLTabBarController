# SwiftUI Animation Advanced Reference

Detailed API reference for SwiftUI animation types, protocols, and patterns.
Covers material beyond the SKILL.md summary.

## Contents

- [CustomAnimation Protocol (iOS 17+)](#customanimation-protocol-ios-17)
- [Spring Type -- All Initializer Variants](#spring-type-all-initializer-variants)
- [UnitCurve Types (iOS 17+)](#unitcurve-types-ios-17)
- [PhaseAnimator Deep Patterns](#phaseanimator-deep-patterns)
- [KeyframeAnimator Multi-Track Examples](#keyframeanimator-multi-track-examples)
- [Transaction and TransactionKey](#transaction-and-transactionkey)
- [Scoped Implicit Animation](#scoped-implicit-animation)
- [All Transition Types (iOS 17+)](#all-transition-types-ios-17)
- [All Symbol Effect Types](#all-symbol-effect-types)
- [Reduce Motion Implementation Patterns](#reduce-motion-implementation-patterns)
- [Animation Performance Tips](#animation-performance-tips)

## CustomAnimation Protocol (iOS 17+)

Create entirely custom animation curves by conforming to `CustomAnimation`.

```swift
@preconcurrency protocol CustomAnimation: Hashable, Sendable
```

### Required Method

```swift
func animate<V: VectorArithmetic>(
    value: V,
    time: TimeInterval,
    context: inout AnimationContext<V>
) -> V?
```

Return the interpolated value at the given time. Return `nil` when the
animation is complete.

### Optional Methods

```swift
func velocity<V: VectorArithmetic>(
    value: V,
    time: TimeInterval,
    context: AnimationContext<V>
) -> V?

func shouldMerge<V: VectorArithmetic>(
    previous: Animation,
    value: V,
    time: TimeInterval,
    context: inout AnimationContext<V>
) -> Bool
```

### Full Example: Elastic Ease-In-Out

```swift
struct ElasticAnimation: CustomAnimation {
    let duration: TimeInterval

    func animate<V: VectorArithmetic>(
        value: V,
        time: TimeInterval,
        context: inout AnimationContext<V>
    ) -> V? {
        guard time <= duration else { return nil }
        let p = time / duration
        let s = sin((20 * p - 11.125) * ((2 * .pi) / 4.5))
        let progress: Double
        if p < 0.5 {
            progress = -(pow(2, 20 * p - 10) * s) / 2
        } else {
            progress = (pow(2, -20 * p + 10) * s) / 2 + 1
        }
        return value.scaled(by: progress)
    }
}
```

### Ergonomic Extension Pattern

Expose custom animations as static members on `Animation`.

```swift
extension Animation {
    static var elastic: Animation {
        elastic(duration: 0.35)
    }

    static func elastic(duration: TimeInterval) -> Animation {
        Animation(ElasticAnimation(duration: duration))
    }
}

// Usage
withAnimation(.elastic(duration: 0.5)) { isActive.toggle() }
```

### Supporting Types

| Type | Role |
|---|---|
| `AnimationContext<V>` | Carries environment and per-animation state |
| `AnimationState` | Key-value storage for persisted state |
| `AnimationStateKey` | Protocol for defining custom state keys |

## Spring Type -- All Initializer Variants

### Perceptual (Preferred)

```swift
Spring(duration: 0.5, bounce: 0.0)
```

- `duration` -- Perceptual duration controlling pace. Default `0.5`.
- `bounce` -- Bounciness. `0.0` = no bounce, `1.0` = undamped. Negative values
  produce overdamped springs. Default `0.0`.

### Physical Parameters

```swift
Spring(mass: 1.0, stiffness: 100.0, damping: 10.0, allowOverDamping: false)
```

- `mass` -- Mass at end of spring. Default `1.0`.
- `stiffness` -- Spring stiffness coefficient.
- `damping` -- Friction-like drag force.
- `allowOverDamping` -- Permit damping ratio > 1. Default `false`.

### Response-Based

```swift
Spring(response: 0.5, dampingRatio: 0.7)
```

- `response` -- Stiffness expressed as approximate duration in seconds.
- `dampingRatio` -- Fraction of critical damping. `1.0` = critically damped.

### Settling-Based

```swift
Spring(settlingDuration: 1.0, dampingRatio: 0.8, epsilon: 0.001)
```

- `settlingDuration` -- Estimated time to come to rest.
- `dampingRatio` -- Fraction of critical damping.
- `epsilon` -- Threshold for considering the spring at rest. Default `0.001`.

### Presets

```swift
Spring.smooth                                  // no bounce
Spring.smooth(duration: 0.5, extraBounce: 0.0)
Spring.snappy                                  // small bounce
Spring.snappy(duration: 0.4, extraBounce: 0.1)
Spring.bouncy                                  // visible bounce
Spring.bouncy(duration: 0.5, extraBounce: 0.2)
```

### Querying State

```swift
let spring = Spring(duration: 0.5, bounce: 0.3)
let v = spring.value(target: 1.0, initialVelocity: 0.0, time: 0.25)
let vel = spring.velocity(target: 1.0, initialVelocity: 0.0, time: 0.25)
let settle = spring.settlingDuration(target: 1.0, initialVelocity: 0.0, epsilon: 0.001)
```

### Parameter Conversion

```swift
let spring = Spring(duration: 0.5, bounce: 0.3)
// Access physical equivalents:
spring.mass       // 1.0
spring.stiffness  // 157.9
spring.damping    // 17.6
spring.response
spring.dampingRatio
spring.settlingDuration
```

## UnitCurve Types (iOS 17+)

Map input progress [0,1] to output progress [0,1]. Used with
`.timingCurve(_:duration:)`.

### Built-in Curves

```swift
UnitCurve.linear
UnitCurve.easeIn
UnitCurve.easeOut
UnitCurve.easeInOut
UnitCurve.circularEaseIn
UnitCurve.circularEaseOut
UnitCurve.circularEaseInOut
```

### Custom Bezier Curve

```swift
UnitCurve.bezier(
    startControlPoint: UnitPoint(x: 0.42, y: 0.0),
    endControlPoint: UnitPoint(x: 0.58, y: 1.0)
)
```

### Instance Members

```swift
let curve = UnitCurve.easeInOut
curve.value(at: 0.5)    // output progress at midpoint
curve.velocity(at: 0.5) // rate of change at midpoint
curve.inverse            // swaps x and y components
```

### Usage with Animation

```swift
.animation(.timingCurve(UnitCurve.circularEaseIn, duration: 0.4), value: x)

// Cubic bezier control points
.animation(.timingCurve(0.68, -0.55, 0.27, 1.55, duration: 0.5), value: x)
```

## PhaseAnimator Deep Patterns

### Multi-Phase with Complex State

```swift
enum LoadPhase: CaseIterable {
    case ready, loading, spinning, complete

    var scale: Double {
        switch self {
        case .ready: 1.0
        case .loading: 0.9
        case .spinning: 1.0
        case .complete: 1.1
        }
    }

    var rotation: Angle {
        switch self {
        case .spinning: .degrees(360)
        default: .zero
        }
    }

    var opacity: Double {
        self == .loading ? 0.7 : 1.0
    }
}

struct LoadingIndicator: View {
    var body: some View {
        PhaseAnimator(LoadPhase.allCases) { phase in
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title)
                .scaleEffect(phase.scale)
                .rotationEffect(phase.rotation)
                .opacity(phase.opacity)
        } animation: { phase in
            switch phase {
            case .ready: .smooth(duration: 0.2)
            case .loading: .easeIn(duration: 0.15)
            case .spinning: .linear(duration: 0.6)
            case .complete: .spring(duration: 0.3, bounce: 0.4)
            }
        }
    }
}
```

### Trigger-Based Phase Advance

Each trigger change advances to the next phase. It does not run the full phase
array as a one-shot sequence; use `KeyframeAnimator` or explicit phase state
when each tap should play a complete timeline.

```swift
struct FeedbackDot: View {
    @State private var feedbackTrigger = 0

    var body: some View {
        Button { feedbackTrigger += 1 } label: {
            Circle()
                .frame(width: 20, height: 20)
                .phaseAnimator(
                    [false, true],
                    trigger: feedbackTrigger
                ) { content, phase in
                    content.scaleEffect(phase ? 1.5 : 1.0)
                } animation: { _ in
                    .spring(duration: 0.25, bounce: 0.5)
                }
        }
        .buttonStyle(.plain)
    }
}
```

### View Modifier Form

```swift
Text("Hello")
    .phaseAnimator([0.0, 1.0, 0.0]) { content, phase in
        content.opacity(phase)
    } animation: { _ in .easeInOut(duration: 0.8) }
```

## KeyframeAnimator Multi-Track Examples

### Bounce-and-Fade

```swift
struct BounceValues {
    var yOffset: Double = 0
    var scale: Double = 1.0
    var opacity: Double = 1.0
    var rotation: Angle = .zero
}

struct BouncingBadge: View {
    @State private var trigger = false

    var body: some View {
        Button { trigger.toggle() } label: {
            Text("NEW")
                .font(.caption.bold())
                .padding(.horizontal)
                .background(.red, in: Capsule())
                .keyframeAnimator(
                    initialValue: BounceValues(),
                    trigger: trigger
                ) { content, value in
                    content
                        .offset(y: value.yOffset)
                        .scaleEffect(value.scale)
                        .opacity(value.opacity)
                        .rotationEffect(value.rotation)
                } keyframes: { _ in
                    KeyframeTrack(\.yOffset) {
                        SpringKeyframe(-20, duration: 0.2)
                        CubicKeyframe(5, duration: 0.15)
                        SpringKeyframe(0, duration: 0.3)
                    }
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.3, duration: 0.2)
                        CubicKeyframe(0.95, duration: 0.15)
                        SpringKeyframe(1.0, duration: 0.3)
                    }
                    KeyframeTrack(\.rotation) {
                        LinearKeyframe(.degrees(-5), duration: 0.1)
                        LinearKeyframe(.degrees(5), duration: 0.1)
                        SpringKeyframe(.zero, duration: 0.2)
                    }
                    KeyframeTrack(\.opacity) {
                        MoveKeyframe(1.0)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
```

### Repeating Keyframe Animation

```swift
KeyframeAnimator(
    initialValue: PulseValues(),
    repeating: true
) { value in
    Circle()
        .fill(.blue)
        .frame(width: 40, height: 40)
        .scaleEffect(value.scale)
        .opacity(value.opacity)
} keyframes: { _ in
    KeyframeTrack(\.scale) {
        CubicKeyframe(1.3, duration: 0.5)
        CubicKeyframe(1.0, duration: 0.5)
    }
    KeyframeTrack(\.opacity) {
        CubicKeyframe(0.6, duration: 0.5)
        CubicKeyframe(1.0, duration: 0.5)
    }
}
```

### Keyframe Type Reference

| Type | Interpolation | Use case |
|---|---|---|
| `LinearKeyframe(value, duration:)` | Straight line between values | Steady movement |
| `CubicKeyframe(value, duration:)` | Cubic bezier curve | Smooth easing |
| `SpringKeyframe(value, duration:, spring:)` | Spring physics | Natural settle |
| `MoveKeyframe(value)` | Instant jump | Reset to value immediately |

### Swift 6 Sendable Closure Captures

`keyframeAnimator` content and keyframe closures are `@Sendable`. In Swift 6,
avoid direct reads of `@State` or `@Environment` from nested helper closures
inside the modifier; capture plain values in `body` before the modifier or pass
them through the animated value model.

### KeyframeTimeline for Manual Evaluation

```swift
let timeline = KeyframeTimeline(initialValue: AnimValues()) {
    KeyframeTrack(\.scale) {
        CubicKeyframe(1.5, duration: 0.3)
        CubicKeyframe(1.0, duration: 0.4)
    }
}

let totalDuration = timeline.duration
let valueAtHalf = timeline.value(time: totalDuration / 2)
```

## Transaction and TransactionKey

### Transaction Basics

A `Transaction` carries the animation context for a state change. Every
`withAnimation` call creates a transaction internally.

```swift
// Explicit transaction
var transaction = Transaction(animation: .spring)
withTransaction(transaction) {
    isExpanded = true
}
```

### Overriding Animations with Transaction

```swift
// Remove the incoming transaction animation for this scoped content
SomeView()
    .transaction { transaction in
        transaction.animation = nil
    }

// Override the scoped transaction animation when a value changes
SomeView()
    .transaction(value: selectedTab) { transaction in
        transaction.animation = .smooth(duration: 0.3)
    }
```

### Custom TransactionKey

Store custom metadata in transactions.

```swift
struct IsInteractiveKey: TransactionKey {
    static let defaultValue = false
}

extension Transaction {
    var isInteractive: Bool {
        get { self[IsInteractiveKey.self] }
        set { self[IsInteractiveKey.self] = newValue }
    }
}

// Usage
var transaction = Transaction(animation: .interactiveSpring)
transaction.isInteractive = true
withTransaction(transaction) { dragOffset = newOffset }
```

### Scoped Transaction Override

```swift
// Apply transaction only within a body closure
ParentView()
    .transaction { $0.animation = .spring } body: { content in
        content.scaleEffect(scale)
    }
```

### Scoped Implicit Animation

Use `.animation(_:body:)` when only selected modifiers should animate.
Use `.animation(_:value:)` when a single value change should drive the view's
animatable modifiers together. Use `.transaction(_:body:)` when you need to
scope transaction overrides rather than attach one animation.

```swift
CardView(isExpanded: isExpanded)
    .animation(.smooth) { content in
        content
            .scaleEffect(isExpanded ? 1.05 : 1.0)
            .shadow(radius: isExpanded ? 12 : 4)
    }
```

## All Transition Types (iOS 17+)

### Built-in Transitions

| Transition | Description | Example |
|---|---|---|
| `.opacity` | Fade in/out | `.transition(.opacity)` |
| `.slide` | Slide from leading, exit trailing | `.transition(.slide)` |
| `.scale` | Scale from zero | `.transition(.scale)` |
| `.scale(_:anchor:)` | Scale with amount and anchor | `.transition(.scale(0.5, anchor: .bottom))` |
| `.move(edge:)` | Move from specified edge | `.transition(.move(edge: .top))` |
| `.push(from:)` | Push from edge with fade | `.transition(.push(from: .trailing))` |
| `.offset(_:)` | Offset by CGSize | `.transition(.offset(CGSize(width: 0, height: 50)))` |
| `.offset(x:y:)` | Offset by x and y | `.transition(.offset(x: 0, y: -100))` |
| `.identity` | No visual change | `.transition(.identity)` |
| `.blurReplace` | Blur and scale combined | `.transition(.blurReplace)` |
| `.blurReplace(_:)` | Configurable blur replace | `.transition(.blurReplace(.downUp))` |
| `.symbolEffect` | Default symbol effect | `.transition(.symbolEffect)` |
| `.symbolEffect(_:options:)` | Custom symbol effect | `.transition(.symbolEffect(.appear))` |

### Combining Transitions

```swift
// Slide + fade
.transition(.slide.combined(with: .opacity))

// Move from top + scale
.transition(.move(edge: .top).combined(with: .scale))
```

### Asymmetric Transitions

Different animation for insertion vs removal.

```swift
.transition(.asymmetric(
    insertion: .push(from: .bottom).combined(with: .opacity),
    removal: .scale.combined(with: .opacity)
))
```

### Custom Transition

```swift
struct RotateTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotationEffect(phase.isIdentity ? .zero : .degrees(90))
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension AnyTransition {
    static var rotate: AnyTransition {
        .init(RotateTransition())
    }
}
```

### TransitionPhase

```swift
enum TransitionPhase {
    case willAppear   // View is about to be inserted
    case identity     // View is fully presented
    case didDisappear // View is being removed
}

// Check current phase
phase.isIdentity  // true when fully presented
```

### Attaching Animation to Transition

```swift
.transition(
    .move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.spring(duration: 0.4, bounce: 0.2))
)
```

## All Symbol Effect Types

Availability: `.bounce`, `.pulse`, `.variableColor`, `.scale`, `.appear`,
`.disappear`, and `.replace` are iOS 17+. `.wiggle`, `.breathe`, and `.rotate`
are iOS 18+.

### Discrete Effects (trigger with `value:`)

| Effect | Availability | Scope | Direction |
|---|---|---|---|
| `.bounce` | iOS 17+ | `.byLayer`, `.wholeSymbol` | -- |
| `.wiggle` | iOS 18+ | `.byLayer`, `.wholeSymbol` | `.up`, `.down`, `.left`, `.right`, `.forward`, `.backward`, `.clockwise`, `.counterClockwise`, `.custom(angle:)` |

```swift
Image(systemName: "bell.fill")
    .symbolEffect(.bounce.byLayer, value: count)

// iOS 18+
Image(systemName: "arrow.left.arrow.right")
    .symbolEffect(.wiggle.left, value: swapCount)
```

### Indefinite Effects (toggle with `isActive:`)

| Effect | Availability | Scope | Direction |
|---|---|---|---|
| `.pulse` | iOS 17+ | `.byLayer`, `.wholeSymbol` | -- |
| `.variableColor` | iOS 17+ | `.byLayer`, `.wholeSymbol` | Chaining: `.cumulative`/`.iterative`, `.reversing`/`.nonReversing`, `.dimInactiveLayers`/`.hideInactiveLayers` |
| `.scale` | iOS 17+ | `.byLayer`, `.wholeSymbol` | `.up`, `.down` |
| `.breathe` | iOS 18+ | `.byLayer`, `.wholeSymbol` | -- |
| `.rotate` | iOS 18+ | `.byLayer`, `.wholeSymbol` | `.clockwise`, `.counterClockwise` |

```swift
Image(systemName: "wifi")
    .symbolEffect(.pulse.byLayer, isActive: isConnecting)

// iOS 18+
Image(systemName: "gear")
    .symbolEffect(.rotate.clockwise, isActive: isProcessing)

Image(systemName: "speaker.wave.3.fill")
    .symbolEffect(
        .variableColor.cumulative.nonReversing.dimInactiveLayers,
        options: .repeating,
        isActive: isPlaying
    )

Image(systemName: "magnifyingglass")
    .symbolEffect(.scale.up, isActive: isHighlighted)

// iOS 18+
Image(systemName: "heart.fill")
    .symbolEffect(.breathe, isActive: isFavorite)
```

### Transition Effects (appear/disappear)

```swift
Image(systemName: "checkmark.circle.fill")
    .symbolEffect(.appear, isActive: showCheck)

Image(systemName: "xmark.circle")
    .symbolEffect(.disappear, isActive: shouldHide)
```

### Content Transition Effects (replace)

```swift
Image(systemName: isMuted ? "speaker.slash" : "speaker.wave.3")
    .contentTransition(.symbolEffect(.replace.downUp))

// Magic replace (iOS 18+, morphs between symbols)
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp)))
```

Replace directions: `.downUp`, `.offUp`, `.upUp`.

### SymbolEffectOptions

```swift
.symbolEffect(.pulse, options: .default, isActive: true)
.symbolEffect(.bounce, options: .repeating, value: count)
.symbolEffect(.pulse, options: .nonRepeating, isActive: true)
.symbolEffect(.bounce, options: .repeat(3), value: count)
.symbolEffect(.pulse, options: .speed(2.0), isActive: true)

// RepeatBehavior
.symbolEffect(.bounce, options: .repeat(.periodic(3, delay: 0.5)), value: count)
.symbolEffect(.pulse, options: .repeat(.continuous), isActive: true)
```

### Removing Effects

```swift
Image(systemName: "star.fill")
    .symbolEffect(.pulse, isActive: true)
    .symbolEffectsRemoved(reduceMotion)
```

## Reduce Motion Implementation Patterns

### Environment Variable

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

### Pattern 1: Conditional Animation

```swift
withAnimation(reduceMotion ? .none : .bouncy) {
    isExpanded.toggle()
}
```

### Pattern 2: Simplified Animation

Replace bouncy/spring with crossfade when reduce motion is on.

```swift
withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.3)) {
    selectedTab = newTab
}
```

### Pattern 3: Disable Repeating Animations

```swift
// WRONG: Ignores reduce motion
PhaseAnimator(phases) { phase in /* ... */ }

// CORRECT: Use trigger-based or skip entirely
if !reduceMotion {
    PhaseAnimator(phases) { phase in /* ... */ }
} else {
    StaticView()
}
```

### Pattern 4: Symbol Effects

```swift
Image(systemName: "wifi")
    .symbolEffect(.pulse, isActive: isSearching)
    .symbolEffectsRemoved(reduceMotion)
```

### Pattern 5: Reusable Helper

```swift
extension Animation {
    static func adaptive(
        _ animation: Animation,
        reduceMotion: Bool
    ) -> Animation? {
        reduceMotion ? nil : animation
    }
}

// Usage
withAnimation(.adaptive(.bouncy, reduceMotion: reduceMotion)) {
    isVisible = true
}
```

## Animation Performance Tips

### Keep Content Closures Light

The `content` closure in `KeyframeAnimator` and `PhaseAnimator` runs every
frame while animating. Keep it to simple view modifiers.

```swift
// WRONG: Expensive computation per frame
.keyframeAnimator(initialValue: v, trigger: t) { content, value in
    let result = heavyComputation(value.progress)
    return content.opacity(result)
} keyframes: { _ in /* ... */ }

// CORRECT: Only apply view modifiers
.keyframeAnimator(initialValue: v, trigger: t) { content, value in
    content.opacity(value.opacity)
} keyframes: { _ in /* ... */ }
```

### Prefer Modifier-Based Animations

Animating view modifiers (`opacity`, `scaleEffect`, `offset`, `rotationEffect`)
is highly optimized. Avoid animating layout-triggering properties when possible.

### Use drawingGroup for Complex Compositing

```swift
ComplexAnimatedView()
    .drawingGroup()
```

Flattens the view hierarchy into a single Metal-backed layer. Use when
compositing many overlapping animated views.

### Limit Concurrent Animations

Avoid animating dozens of views simultaneously. Use staggered delays.

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemView(item: item)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring.delay(Double(index) * 0.05), value: isVisible)
}
```

### Avoid Re-creating Views During Animation

Ensure animated views maintain stable identity. Use explicit `id()` modifiers
or stable `ForEach` identifiers.

```swift
// WRONG: View identity changes, breaks animation
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ItemView(item: item)
}

// CORRECT: Stable identity from model
ForEach(items) { item in
    ItemView(item: item)
}
```

### Use geometryGroup() for Nested Geometry

Isolate child geometry from parent animations when they conflict.

```swift
ParentView()
    .scaleEffect(parentScale)
    .geometryGroup()  // children see stable geometry
```

### Layout-Driven Height Changes

`transition` describes child insertion/removal, but a `List` row's changing
height may still snap instead of interpolate. Keep this skill focused on the
animation trigger, curve, and Reduce Motion behavior; route custom row-height,
grid, or layout interpolation work to `swiftui-layout-components`.

### Transaction for Selective Animation Override

Override animation for specific subtrees without affecting siblings.

```swift
// Disable animation on one child while parent animates
ChildView()
    .transaction { $0.animation = nil }
```

### Profile with Instruments

Use the Core Animation instrument in Xcode Instruments to verify:
- The chosen sustainable target frame rate has no avoidable dropped frames; refresh rates are system-managed hints, not guarantees.
- No offscreen rendering passes.
- GPU utilization stays reasonable during animations.
