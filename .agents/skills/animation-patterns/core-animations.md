# Core Animations

Fundamentals of SwiftUI animation: `withAnimation`, spring configurations, completions, transactions, timing curves — and how the animation system actually works.

## How Animation Works (WWDC23)

Every SwiftUI animation has two separable halves: an **animatable attribute** — anything conforming to `Animatable` (opacity, scale, position, color) — and an **`Animation`** that supplies the timing. When state changes inside an animated transaction, SwiftUI interpolates the attribute in the render tree; the view's `body` does not re-run per frame for built-in effects.

- **SwiftUI animates the delta, not the destination.** The animation runs over the vector *difference* between old and new values. A second change landing mid-flight adds its own delta animation on top, so concurrent animations merge additively instead of jumping.
- **Springs preserve velocity.** A retargeted spring merges with the in-flight one and carries its velocity toward the new target — the reason springs are the right default for anything interactive. Timing curves don't merge; overlapping ones run concurrently and their deltas sum.
- **The bare default is a smooth spring.** `withAnimation { }` with no argument uses `.smooth` on iOS 17+. Think of a spring as *perceived duration + bounce*, not physics homework — that's exactly what the Gen 3 parameters encode.

## withAnimation vs .animation Modifier

Two ways to animate state changes. Use one or the other — never both on the same property.

### withAnimation (Explicit — Preferred)

Wraps a state change and animates all views that depend on that state:

```swift
Button("Toggle") {
    withAnimation(.spring) {
        isExpanded.toggle()
    }
}
```

Use when: you control the state change site (button tap, gesture, event).

### .animation(_:value:) (Implicit)

Watches a value and animates whenever it changes:

```swift
Circle()
    .offset(y: isActive ? -20 : 0)
    .animation(.spring, value: isActive)
```

Use when: the state change comes from somewhere else (parent view, environment, binding).

### Deprecated: .animation Without value:

```swift
// ❌ Deprecated in iOS 15 — animates ALL state changes, causes unexpected behavior
Circle()
    .animation(.spring())

// ✅ Always pass value:
Circle()
    .animation(.spring, value: isActive)
```

### Scoped Variants (iOS 17+)

Two further scoping tools keep animation from leaking where you didn't intend it (WWDC23):

**Body-closure variant** — the animation applies only to the attributes inside the closure. Essential for reusable components: the animation cannot propagate to child views the caller passes in:

```swift
content
    .animation(.smooth) { view in
        view
            .opacity(isSelected ? 1 : 0.6)
            .scaleEffect(isSelected ? 1.03 : 1)
    }
```

**Stacked per-property timing** — `.animation(_:value:)` animates the modifiers *above* it in the chain, up to the previous `.animation`. Stack several at different points for per-property timing without reaching for a KeyframeAnimator:

```swift
Circle()
    .scaleEffect(selected ? 1.2 : 1)
    .animation(.bouncy, value: selected)   // scale animates with bounce
    .opacity(selected ? 1 : 0.5)
    .animation(.smooth, value: selected)   // opacity animates smoothly
```

## Spring Configurations

Three API generations exist. **Never mix parameter names across generations.**

### Generation 1: Physics Parameters (iOS 13+)

Raw physics model. Rarely needed — hard to reason about visually.

```swift
Spring(mass: 1.0, stiffness: 100.0, damping: 10.0, initialVelocity: 0.0)
```

### Generation 2: Response / Damping Fraction (iOS 13+)

The most common in existing codebases:

```swift
.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
```

| Parameter | Meaning | Range |
|-----------|---------|-------|
| `response` | Duration of one oscillation (seconds) | 0.0+ (0 = instantaneous) |
| `dampingFraction` | How quickly oscillation dies | 0 = forever, 1 = no bounce, >1 = overdamped |
| `blendDuration` | Smoothing when interrupted (usually 0) | 0.0+ |

### Generation 3: Duration / Bounce (iOS 17+)

Simpler API. **Use this for new code targeting iOS 17+.**

```swift
.spring(duration: 0.5, bounce: 0.3)
```

| Parameter | Meaning | Range |
|-----------|---------|-------|
| `duration` | Approximate settling time (seconds) | 0.0+ |
| `bounce` | Bounciness | -1 to 1 (0 = no bounce, negative = overdamped) |

### Spring Presets (iOS 17+)

Use these instead of manual configuration when possible:

```swift
.spring            // Default spring — slight bounce, natural feel
.bouncy            // .spring(duration: 0.5, bounce: 0.3) — playful
.snappy            // .spring(duration: 0.3, bounce: 0.15) — quick, subtle bounce
.smooth            // .spring(duration: 0.5, bounce: 0.0) — no bounce, gentle settle
```

### Migration Table

| Generation 2 | Generation 3 Equivalent |
|--------------|------------------------|
| `.spring(response: 0.5, dampingFraction: 0.7)` | `.spring(duration: 0.5, bounce: 0.3)` |
| `.spring(response: 0.3, dampingFraction: 0.85)` | `.snappy` |
| `.spring(response: 0.5, dampingFraction: 1.0)` | `.smooth` |
| `.spring()` (default) | `.spring` |

### Anti-Patterns

```swift
// ❌ WRONG: Mixing generation 2 and 3 parameter names
.spring(response: 0.5, bounce: 0.3)   // Does NOT compile

// ❌ WRONG: Mixing generation 1 and 2
.spring(mass: 1.0, dampingFraction: 0.7)  // Does NOT compile

// ✅ Pick ONE generation:
.spring(response: 0.5, dampingFraction: 0.7)  // Gen 2
.spring(duration: 0.5, bounce: 0.3)            // Gen 3
.bouncy                                         // Gen 3 preset
```

## Animation Completions (iOS 17+)

Run code after an animation finishes. Uses `withAnimation` with a `completion` closure.

```swift
withAnimation(.spring) {
    isExpanded = true
} completion: {
    showContent = true
}
```

Full signature:

```swift
withAnimation(
    _ animation: Animation,
    completionCriteria: AnimationCompletionCriteria = .logicallyComplete,
    _ body: () -> Void,
    completion: @Sendable () -> Void
)
```

### Completion Criteria

| Criteria | Meaning |
|----------|---------|
| `.logicallyComplete` | Fires when animation reaches target (spring may still be settling) |
| `.removed` | Fires when animation is fully removed (spring has fully settled) |

```swift
// Wait for spring to fully settle before enabling interaction
withAnimation(.bouncy, completionCriteria: .removed) {
    cardOffset = .zero
} completion: {
    isInteractive = true
}
```

### Anti-Pattern

```swift
// ❌ WRONG: This modifier does NOT exist
view.onAnimationCompleted(for: offset) { }

// ❌ WRONG: This modifier does NOT exist
view.onAnimationEnd { }

// ✅ Use withAnimation completion:
withAnimation(.default) {
    offset = targetOffset
} completion: {
    handleAnimationDone()
}
```

## Transaction Control

### withTransaction — Override Animation

Replace the animation for a specific state change:

```swift
var transaction = Transaction(animation: .none)
withTransaction(transaction) {
    // This state change happens instantly, no animation
    selectedTab = newTab
}
```

### Disabling Animation

```swift
// Disable animation for a specific change
var transaction = Transaction()
transaction.disablesAnimations = true
withTransaction(transaction) {
    resetPosition()
}

// Or use withAnimation(.none) — simpler for one-off cases (iOS 17+)
withAnimation(.none) {
    resetPosition()
}
```

### transaction Modifier

Override animations on a per-view basis:

```swift
Text(count, format: .number)
    .contentTransition(.numericText())
    .transaction { transaction in
        transaction.animation = .snappy
    }
```

A bare `.transaction { }` rewrites the transaction for *every* change flowing through the view. Prefer `.animation(_:value:)` scoped to a value — or the scoped variants `.transaction(value:)` (fires only when that value changes) and `.transaction(_:body:)` (applies only to the attributes inside the closure), both iOS 17+.

### TransactionKey — Animate by Cause (iOS 17+)

When the same state change should animate differently depending on *why* it happened, define a custom `TransactionKey`, tag the change site, and read the cause where the view reacts (WWDC23):

```swift
struct FromUserTapKey: TransactionKey {
    static let defaultValue = false
}

extension Transaction {
    var fromUserTap: Bool {
        get { self[FromUserTapKey.self] }
        set { self[FromUserTapKey.self] = newValue }
    }
}

// Change site: tag the cause
withTransaction(\.fromUserTap, true) {
    model.selection = item
}

// Reacting view: pick the animation from the cause
ItemView(item)
    .transaction { t in
        t.animation = t.fromUserTap ? .bouncy : .smooth
    }
```

This beats threading a `Bool` through view initializers: the cause travels with the state change itself, so a model updated from both user taps and server pushes animates correctly from either source.

## Timing Curves

Non-spring animations for specific use cases (opacity fades, progress bars).

```swift
.linear                        // Constant speed
.linear(duration: 0.3)         // Constant speed, 0.3s

.easeIn                        // Slow start, fast end
.easeIn(duration: 0.3)

.easeOut                       // Fast start, slow end
.easeOut(duration: 0.3)

.easeInOut                     // Slow start and end
.easeInOut(duration: 0.3)

.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)  // Custom cubic bezier
```

**When to use timing curves vs springs:**
- Springs: interactive elements, things that feel physical (cards, buttons, toggles)
- `easeInOut`: opacity fades, color transitions
- `linear`: progress indicators, continuous rotation

## Animation Modifiers

Higher-order modifiers: each wraps a base animation and transforms its timing, so they compose with springs, timing curves, and `CustomAnimation`s alike. Chain them onto any `Animation` value:

```swift
// Repeat forever (for loading spinners, pulsing effects)
.linear(duration: 1.0).repeatForever(autoreverses: false)

// Repeat a fixed number of times
.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)

// Delay before starting
.spring.delay(0.2)

// Change speed (2x faster)
.spring.speed(2.0)
```

### Loading Spinner Example

```swift
struct Spinner: View {
    @State private var isRotating = false

    var body: some View {
        Image(systemName: "arrow.trianglehead.2.clockwise")
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}
```

### Staggered Animation Example

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemRow(item: item)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(
            .spring.delay(Double(index) * 0.05),
            value: isVisible
        )
}
```

## Common Patterns

### Animate on Appear

```swift
struct AppearAnimation: View {
    @State private var appeared = false

    var body: some View {
        ContentView()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .onAppear {
                withAnimation(.spring) {
                    appeared = true
                }
            }
    }
}
```

### Animatable Modifier for Custom Properties

For properties SwiftUI doesn't natively animate (like text size, stroke dash):

```swift
struct CountingText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value))")
    }
}
```

Use `withAnimation` to drive the value change — SwiftUI interpolates `animatableData` each frame.

Requirements and mechanics (WWDC23):

- `animatableData` must be **readwrite** and conform to `VectorArithmetic`. The built-in types are vectors too: `CGFloat`/`Double` animate as 1D vectors, `CGPoint`/`CGSize` as 2D, `CGRect` as 4D.
- Combine multiple properties with `AnimatablePair` (nest pairs for more dimensions):

```swift
var animatableData: AnimatablePair<Double, Double> {
    get { AnimatablePair(angle, radius) }
    set { angle = newValue.first; radius = newValue.second }
}
```

- **Cost warning:** when a `View` conforms to `Animatable`, the animatable attribute is the view itself — SwiftUI calls its `body` **every frame** of the animation, skipping the render-tree fast path that built-in effects use. Reach for it only when no built-in effect can express the motion — e.g. moving views along an arc by animating the angle input of a custom layout, where interpolating an `offset` would cut straight across the chord instead of following the curve. Keep that `body` trivial.

## Fluid Interface Principles (WWDC18)

Gesture/animation rules from Apple's "Designing Fluid Interfaces" — framework-agnostic and still the baseline:

- **Tune springs by damping + response, not duration.** A spring never truly "ends"; choose how tightly it tracks the finger (`response`) and how it settles (`dampingFraction`) and let duration fall out. (Gen 3's `duration:` is an approximate settling time, not a hard stop.)
- **Project momentum.** Combine release velocity with a deceleration rate to compute the coast target, then animate there — not from the raw release position:

  ```swift
  func project(value: CGFloat, velocity: CGFloat,
               decelerationRate: CGFloat = UIScrollView.DecelerationRate.normal.rawValue) -> CGFloat {
      value + velocity * decelerationRate / (1 - decelerationRate)
  }
  ```

- **~10pt hysteresis before committing to a direction** — lock the gesture axis only after ~10pt of travel; instant commitment misreads diagonal starts.
- **Rubber-band soft boundaries.** Past a limit, move at a diminishing fraction of the finger's travel instead of stopping dead — the boundary communicates itself while staying responsive.
- **Every gesture interruptible and redirectable mid-flight.** The user must be able to catch, reverse, or redirect an animating element at any moment — see the `.interactiveSpring` → `.spring` hand-off in transitions.md.
