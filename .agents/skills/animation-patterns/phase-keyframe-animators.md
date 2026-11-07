# Phase & Keyframe Animators

Multi-step and timeline-based animations using `PhaseAnimator` and `KeyframeAnimator` (iOS 17+).

## PhaseAnimator

Cycles through a sequence of discrete phases, applying different view modifiers at each phase.

### API Shape

```swift
PhaseAnimator(
    _ phases: some Sequence,          // The phases to cycle through
    trigger: some Equatable,          // Optional: triggers one cycle (omit for continuous)
    content: (PlaceholderContentView<Self>, Phase) -> some View,
    animation: (Phase) -> Animation?  // Animation TO this phase
)
```

### Auto-Advancing (Continuous Loop)

Omit `trigger` to loop forever — the **ambient** mode (WWDC23): idle shimmer, pulse, or breathing effects that run for the view's lifetime. With `trigger:` the animator instead runs one full cycle per trigger change. Phases must be `CaseIterable` to use `allCases`.

```swift
enum PulsePhase: CaseIterable {
    case idle, scaled, rotated
}

struct PulsingIcon: View {
    var body: some View {
        PhaseAnimator(PulsePhase.allCases) { content, phase in
            content
                .scaleEffect(phase == .scaled ? 1.2 : 1.0)
                .rotationEffect(.degrees(phase == .rotated ? 15 : 0))
                .opacity(phase == .idle ? 0.8 : 1.0)
        } animation: { phase in
            switch phase {
            case .idle: .easeInOut(duration: 0.6)
            case .scaled: .spring(duration: 0.4, bounce: 0.3)
            case .rotated: .spring(duration: 0.3, bounce: 0.2)
            }
        }
    }
}
```

### Trigger-Based (One Cycle)

Pass a `trigger` value. Each time it changes, the animator cycles through all phases once and returns to the first.

```swift
struct NotificationBadge: View {
    var count: Int

    var body: some View {
        PhaseAnimator(
            [false, true, false],
            trigger: count
        ) { content, phase in
            content
                .scaleEffect(phase ? 1.3 : 1.0)
                .brightness(phase ? 0.1 : 0)
        } animation: { phase in
            phase ? .spring(duration: 0.2, bounce: 0.5) : .spring(duration: 0.3)
        }
    }
}
```

### Using an Array of Values

Phases don't have to be an enum — any `Equatable` sequence works:

```swift
PhaseAnimator([0.0, 1.0, 0.5, 1.0]) { content, opacity in
    content.opacity(opacity)
} animation: { _ in
    .easeInOut(duration: 0.4)
}
```

### Enum Phases with Computed Properties

For more than a couple of modifiers, give the phase enum computed properties instead of scattering `phase == .x` checks through the content closure — the closure stays declarative and each phase's look lives in one place:

```swift
enum EmphasisPhase: CaseIterable {
    case idle, lifting, settling

    var scale: Double {
        switch self {
        case .idle: 1.0
        case .lifting: 1.15
        case .settling: 1.05
        }
    }

    var shadowRadius: Double { self == .idle ? 2 : 10 }
}

PhaseAnimator(EmphasisPhase.allCases, trigger: didScore) { content, phase in
    content
        .scaleEffect(phase.scale)
        .shadow(radius: phase.shadowRadius)
}
```

### Anti-Patterns

```swift
// ❌ WRONG: Content closure takes ONE parameter (only phase)
PhaseAnimator(PulsePhase.allCases) { phase in
    Image(systemName: "star.fill")
        .scaleEffect(phase == .big ? 1.5 : 1.0)
}

// ✅ RIGHT: Content closure takes TWO parameters (content, phase)
PhaseAnimator(PulsePhase.allCases) { content, phase in
    content
        .scaleEffect(phase == .big ? 1.5 : 1.0)
}

// ❌ WRONG: Treating phase as a numeric value
PhaseAnimator([0.0, 1.0, 0.0]) { content, phase in
    content.opacity(phase)  // phase is Double here, this IS valid
}
// But if using an enum:
PhaseAnimator(PulsePhase.allCases) { content, phase in
    content.scaleEffect(phase)  // ❌ phase is PulsePhase, not a number
}

// ❌ WRONG: Missing animation closure (defaults to .default for all)
PhaseAnimator(PulsePhase.allCases) { content, phase in
    content.scaleEffect(phase == .big ? 1.5 : 1.0)
}
// ✅ Better: Provide animation per phase for intentional timing
```

## KeyframeAnimator

Timeline-based animation with independent tracks for different properties. Each property follows its own keyframe sequence.

### API Shape

```swift
KeyframeAnimator(
    initialValue: AnimationValues,       // Custom struct with animatable properties
    trigger: some Equatable,             // Triggers the animation
    content: (AnimationValues) -> some View,
    keyframes: (AnimationValues) -> some Keyframes
)
```

### Step 1: Define an Animatable Values Struct

The struct holds all properties you want to animate. It does NOT need to conform to `Animatable`.

```swift
struct BounceValues {
    var scale: Double = 1.0
    var yOffset: Double = 0.0
    var rotation: Double = 0.0
}
```

### Step 2: Build the Animator

```swift
struct BouncingLogo: View {
    @State private var trigger = false

    var body: some View {
        KeyframeAnimator(
            initialValue: BounceValues(),
            trigger: trigger
        ) { values in
            // content closure — read values, apply to view
            Image(systemName: "star.fill")
                .scaleEffect(values.scale)
                .offset(y: values.yOffset)
                .rotationEffect(.degrees(values.rotation))
        } keyframes: { _ in
            // keyframes closure — define tracks per property
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.5, duration: 0.3)
                SpringKeyframe(1.0, duration: 0.3)
            }

            KeyframeTrack(\.yOffset) {
                LinearKeyframe(-30, duration: 0.2)
                SpringKeyframe(0, duration: 0.4, spring: .bouncy)
            }

            KeyframeTrack(\.rotation) {
                CubicKeyframe(15, duration: 0.15)
                CubicKeyframe(-15, duration: 0.15)
                CubicKeyframe(0, duration: 0.2)
            }
        }
        .onTapGesture {
            trigger.toggle()
        }
    }
}
```

### Keyframe Types

| Type | Behavior | Parameters |
|------|----------|------------|
| `LinearKeyframe` | Constant-speed interpolation | `(_ value:, duration:)` |
| `SpringKeyframe` | Spring physics to reach value | `(_ value:, duration:, spring:)` |
| `CubicKeyframe` | Bezier curve interpolation | `(_ value:, duration:, timingCurve:)` |
| `MoveKeyframe` | Jump to value instantly (no interpolation) | `(_ value:)` |

```swift
KeyframeTrack(\.opacity) {
    MoveKeyframe(0.0)                          // Start invisible
    LinearKeyframe(1.0, duration: 0.3)         // Fade in linearly
    CubicKeyframe(0.5, duration: 0.2)          // Ease to half opacity
    SpringKeyframe(1.0, duration: 0.4)         // Spring back to full
}
```

Two behaviors that change how tracks feel (WWDC23):

- `SpringKeyframe.duration` **caps** the spring — advances to the next keyframe even if unsettled.
- Consecutive `CubicKeyframe`s blend into a single Catmull-Rom spline, drawing one smooth curve through all their values rather than separate eased segments — ideal for arcs and loops.

### Multi-Property Example

```swift
struct ShakeValues {
    var xOffset: Double = 0
    var angle: Double = 0
    var scale: Double = 1
}

struct ErrorShake: View {
    @State private var shakeTrigger = 0

    var body: some View {
        KeyframeAnimator(
            initialValue: ShakeValues(),
            trigger: shakeTrigger
        ) { values in
            TextField("Email", text: .constant(""))
                .offset(x: values.xOffset)
                .rotationEffect(.degrees(values.angle))
                .scaleEffect(values.scale)
        } keyframes: { _ in
            KeyframeTrack(\.xOffset) {
                LinearKeyframe(10, duration: 0.07)
                LinearKeyframe(-10, duration: 0.07)
                LinearKeyframe(8, duration: 0.07)
                LinearKeyframe(-8, duration: 0.07)
                LinearKeyframe(4, duration: 0.07)
                LinearKeyframe(0, duration: 0.07)
            }

            KeyframeTrack(\.angle) {
                LinearKeyframe(2, duration: 0.07)
                LinearKeyframe(-2, duration: 0.07)
                LinearKeyframe(1, duration: 0.07)
                LinearKeyframe(-1, duration: 0.07)
                LinearKeyframe(0, duration: 0.14)
            }

            KeyframeTrack(\.scale) {
                SpringKeyframe(1.05, duration: 0.15)
                SpringKeyframe(1.0, duration: 0.25)
            }
        }
    }
}
```

### Keyframes Are Clips, Not Interactive Animations

Treat a keyframe animation like a video clip: it plays exactly as authored (WWDC23). Unlike springs, keyframes never retarget — changing the trigger mid-flight restarts the clip rather than smoothly redirecting it. Don't use KeyframeAnimator where the UI must stay interactive or track a gesture; springs merge and preserve velocity, keyframes don't.

Performance: the `content` closure runs **every frame** while the animation plays. Read the values and apply modifiers — no formatting, allocation, or layout math inside it.

### Continuous KeyframeAnimator

Omit `trigger` and add `repeating: true` for looping animations:

```swift
KeyframeAnimator(
    initialValue: FloatValues(),
    repeating: true
) { values in
    Circle()
        .offset(y: values.yOffset)
        .opacity(values.opacity)
} keyframes: { _ in
    KeyframeTrack(\.yOffset) {
        CubicKeyframe(-10, duration: 1.0)
        CubicKeyframe(0, duration: 1.0)
    }
    KeyframeTrack(\.opacity) {
        CubicKeyframe(0.5, duration: 1.0)
        CubicKeyframe(1.0, duration: 1.0)
    }
}
```

### MapKit Camera Keyframes (iOS 17+)

`.mapCameraKeyframeAnimator(trigger:)` drives a `MapCamera` along keyframe tracks. If the user touches the map mid-animation, the animation cancels and the user keeps control — no extra handling required (WWDC23):

```swift
Map(initialPosition: .region(region))
    .mapCameraKeyframeAnimator(trigger: selectedLandmark) { initialCamera in
        KeyframeTrack(\MapCamera.centerCoordinate) {
            CubicKeyframe(selectedLandmark.coordinate, duration: 2.0)
        }
        KeyframeTrack(\MapCamera.distance) {
            CubicKeyframe(initialCamera.distance * 1.5, duration: 1.0)  // pull back...
            CubicKeyframe(800, duration: 1.0)                            // ...then dive in
        }
    }
```

### KeyframeTimeline — Sample Values Anywhere

The same keyframes work outside the animator. `KeyframeTimeline` turns them into a pure function of time — use it to scrub an animation from scroll position, or to drive custom rendering from a `TimelineView`:

```swift
let timeline = KeyframeTimeline(initialValue: BounceValues()) {
    KeyframeTrack(\.scale) {
        SpringKeyframe(1.5, duration: 0.3)
        SpringKeyframe(1.0, duration: 0.3)
    }
    KeyframeTrack(\.yOffset) {
        LinearKeyframe(-30, duration: 0.2)
        SpringKeyframe(0, duration: 0.4, spring: .bouncy)
    }
}

// Scrub by scroll: map progress (0...1) into the timeline
let values = timeline.value(progress: scrollProgress)

// Or sample by absolute time (e.g. from TimelineView(.animation))
let values = timeline.value(time: elapsed)   // timeline.duration = total length
```

### Anti-Patterns

```swift
// ❌ WRONG: Using a raw Double instead of a struct
KeyframeAnimator(initialValue: 0.0, trigger: trigger) { value in
    Circle().scaleEffect(value)
} keyframes: { _ in
    KeyframeTrack(\.self) {  // \.self works but limits to ONE property
        SpringKeyframe(1.5, duration: 0.3)
    }
}
// ✅ Use a struct so you can animate multiple properties independently

// ❌ WRONG: Key path into the view instead of the values struct
KeyframeTrack(\.scaleEffect) { ... }  // Does NOT compile
// ✅ Key path into your values struct
KeyframeTrack(\.scale) { ... }

// ❌ WRONG: Using withAnimation to drive keyframes
withAnimation {
    KeyframeAnimator(...)  // KeyframeAnimator manages its own timing
}
// ✅ Use the trigger parameter to start the animation

// ❌ WRONG: Forgetting duration on LinearKeyframe / CubicKeyframe
LinearKeyframe(1.0)  // Missing duration — won't compile
// ✅ Always provide duration
LinearKeyframe(1.0, duration: 0.3)
// Note: MoveKeyframe does NOT take a duration (it's instantaneous)
```

## PhaseAnimator vs KeyframeAnimator

| | PhaseAnimator | KeyframeAnimator |
|---|---|---|
| **Mental model** | Cycle through states | Timeline with tracks |
| **Properties** | All change together per phase | Each property has independent timeline |
| **Timing** | One animation per phase transition | Per-keyframe timing within each track |
| **Use when** | 2-4 distinct visual states | Complex choreography, physics-based sequences |
| **Difficulty** | Simpler | More setup, more control |

### Choose PhaseAnimator when:
- You have discrete visual states (idle → active → settled)
- All properties change at the same time
- You want automatic looping with `CaseIterable`

### Choose KeyframeAnimator when:
- Properties need different timing (scale peaks before rotation)
- You need precise timeline control
- You want spring physics on some properties and linear on others

## CustomAnimation Protocol (iOS 17+)

For entirely custom animation curves. Rarely needed — prefer built-in springs and timing curves.

```swift
struct CustomBounce: CustomAnimation {
    var target: Double = 1.0

    func animate<V: VectorArithmetic>(
        value: V, time: TimeInterval, context: inout AnimationContext<V>
    ) -> V? {
        // Return nil when animation is done
        guard time < 1.0 else { return nil }
        // Return interpolated value
        let progress = time / 1.0
        let bounce = sin(progress * .pi * 3) * (1 - progress) * 0.3
        return value.scaled(by: 1.0 + bounce)
    }

    func shouldMerge<V: VectorArithmetic>(
        previous: Animation, value: V, time: TimeInterval,
        context: inout AnimationContext<V>
    ) -> Bool {
        // Return true to merge with in-flight animation of same type
        false
    }
}

// Usage
withAnimation(Animation(CustomBounce())) {
    isExpanded.toggle()
}
```

The protocol hooks map directly onto built-in behavior (WWDC23):

| Hook | Role | How built-ins use it |
|------|------|----------------------|
| `animate(value:time:context:)` | Return the interpolated vector for `time`, or `nil` when finished | `value` is the *delta* being animated, not an absolute value |
| `shouldMerge(previous:value:time:context:)` | Return `true` to take over an in-flight animation of the same type | Springs return `true` — they retarget, preserving state; timing curves return `false`, so old and new run concurrently and their deltas combine additively |
| `velocity(value:time:context:)` | Report current velocity (has a default implementation) | Lets a merging successor preserve momentum — implement it if your animation may be interrupted |
