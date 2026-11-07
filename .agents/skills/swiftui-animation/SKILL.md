---
name: swiftui-animation
description: "Implement, diagnose, or review SwiftUI motion using explicit and scoped implicit animations, springs, transitions, PhaseAnimator, KeyframeAnimator, matched geometry or navigation zoom, SF Symbol effects, and custom Animation types. Use when views should animate on state changes, insertion, removal, navigation, or multi-step choreography, or when motion must respect Reduce Motion and Swift concurrency."
---

# SwiftUI Animation (iOS 26+)

Review, write, and fix SwiftUI animations. Apply modern animation APIs with
correct timing, transitions, and accessibility handling using Swift 6.3 patterns.

## Contents

- [Triage Workflow](#triage-workflow)
- [withAnimation (Explicit Animation)](#withanimation-explicit-animation)
- [Implicit Animation](#implicit-animation)
- [Spring Type (iOS 17+)](#spring-type-ios-17)
- [PhaseAnimator (iOS 17+)](#phaseanimator-ios-17)
- [KeyframeAnimator (iOS 17+)](#keyframeanimator-ios-17)
- [`@Animatable Macro`](#animatable-macro)
- [matchedGeometryEffect (iOS 14+)](#matchedgeometryeffect-ios-14)
- [Navigation Zoom Transition (iOS 18+)](#navigation-zoom-transition-ios-18)
- [Transitions (iOS 17+)](#transitions-ios-17)
- [ContentTransition (iOS 16+)](#contenttransition-ios-16)
- [Symbol Effects (iOS 17+)](#symbol-effects-ios-17)
- [Symbol Rendering Modes](#symbol-rendering-modes)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Triage Workflow

### Step 1: Identify the animation category

| Category | API | When to use |
|---|---|---|
| State-driven | `withAnimation`, `.animation(_:body:)`, `.animation(_:value:)` | Explicit state changes, selective modifier animation, or simple value-bound changes |
| Multi-phase | `PhaseAnimator` | Sequenced multi-step animations |
| Keyframe | `KeyframeAnimator` | Complex multi-property choreography |
| Shared element | `matchedGeometryEffect` | Layout-driven hero transitions |
| Navigation | `matchedTransitionSource` + `.navigationTransition(.zoom)` | NavigationStack push/pop zoom |
| View lifecycle | `.transition()` | Insertion and removal |
| Text content | `.contentTransition()` | In-place text/number changes |
| Symbol | `.symbolEffect()` | SF Symbol animations |
| Custom | `CustomAnimation` protocol | Novel timing curves |
| Core Animation bridge | `CALayer`, `CAAnimation`, `CADisplayLink` | Read `references/core-animation-bridge.md` before advising |

### Step 2: Choose the animation curve

```swift
.easeInOut(duration: 0.3)       // mechanical timing
.smooth                         // fluid, no bounce
.snappy                         // responsive, small bounce
.bouncy                         // playful, visible bounce
.spring(duration: 0.5, bounce: 0.3)
```

Use [the advanced catalog](references/animation-advanced.md#spring-type-all-initializer-variants)
when presets do not express the intended motion.

### Step 3: Apply and verify

- Confirm animation triggers on the correct state change.
- Test with Accessibility > Reduce Motion enabled.
- Verify no expensive work runs inside animation content closures.
- For CA bridges, use Coordinators for delegates, invalidate display links, treat frame-rate ranges as hints, and adapt work to the actual refresh rate.

## withAnimation (Explicit Animation)

```swift
withAnimation(.spring) { isExpanded.toggle() }

// With completion (iOS 17+)
withAnimation(.smooth(duration: 0.35), completionCriteria: .logicallyComplete) {
    isExpanded = true
} completion: { loadContent() }
```

## Implicit Animation

Use `withAnimation` for state-mutation ownership, `.animation(_:body:)` for
selected modifiers, and `.animation(_:value:)` for simple value-bound changes.

```swift
Badge()
    .foregroundStyle(isActive ? .green : .secondary)
    .animation(.snappy) { content in
        content
            .scaleEffect(isActive ? 1.15 : 1.0)
            .opacity(isActive ? 1.0 : 0.7)
    }
```

```swift
Circle()
    .scaleEffect(isActive ? 1.2 : 1.0)
    .opacity(isActive ? 1.0 : 0.6)
    .animation(.bouncy, value: isActive)
```

## Spring Type (iOS 17+)

Prefer the perceptual form or a preset. Load the advanced reference only when
physical, response-based, or settling parameters are required.

```swift
Spring(duration: 0.5, bounce: 0.3)
Spring.smooth
Spring.snappy
Spring.bouncy
```

## PhaseAnimator (iOS 17+)

Cycle through discrete phases with per-phase animation curves.

```swift
enum PulsePhase: CaseIterable {
    case idle, grow, shrink
}

struct PulsingDot: View {
    var body: some View {
        PhaseAnimator(PulsePhase.allCases) { phase in
            Circle()
                .frame(width: 40, height: 40)
                .scaleEffect(phase == .grow ? 1.4 : 1.0)
                .opacity(phase == .shrink ? 0.5 : 1.0)
        } animation: { phase in
            switch phase {
            case .idle: .easeIn(duration: 0.2)
            case .grow: .spring(duration: 0.4, bounce: 0.3)
            case .shrink: .easeOut(duration: 0.3)
            }
        }
    }
}
```

Trigger-based variant advances to the next phase on each trigger change:

```swift
PhaseAnimator(PulsePhase.allCases, trigger: tapCount) { phase in
    // ...
} animation: { _ in .spring(duration: 0.4) }
```

## KeyframeAnimator (iOS 17+)

Animate multiple properties along independent timelines.

```swift
struct AnimValues {
    var scale: Double = 1.0
    var yOffset: Double = 0.0
    var opacity: Double = 1.0
}

struct BounceView: View {
    @State private var trigger = false

    var body: some View {
        Button { trigger.toggle() } label: {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .keyframeAnimator(
                    initialValue: AnimValues(),
                    trigger: trigger
                ) { content, value in
                    content
                        .scaleEffect(value.scale)
                        .offset(y: value.yOffset)
                        .opacity(value.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.5, duration: 0.3)
                        CubicKeyframe(1.0, duration: 0.4)
                    }
                    KeyframeTrack(\.yOffset) {
                        CubicKeyframe(-30, duration: 0.2)
                        CubicKeyframe(0, duration: 0.4)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0.6, duration: 0.15)
                        LinearKeyframe(1.0, duration: 0.25)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
```

Keyframe types: `LinearKeyframe` (linear), `CubicKeyframe` (smooth curve),
`SpringKeyframe` (spring physics), `MoveKeyframe` (instant jump).

Use `repeating: true` for looping keyframe animations.
Swift 6: keyframe closures are `@Sendable`; capture state/env values before the modifier.

## `@Animatable` Macro

Replaces manual `AnimatableData` boilerplate. Attach to any type with
animatable stored properties.

```swift
@Animatable
struct WaveShape: Shape {
    var frequency: Double
    var amplitude: Double
    var phase: Double
    @AnimatableIgnored var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        // draw wave using frequency, amplitude, phase
    }
}
```

Rules:
- Stored properties must conform to `VectorArithmetic`.
- Use `@AnimatableIgnored` to exclude non-animatable properties.
- Computed properties are never included.

## matchedGeometryEffect (iOS 14+)

Synchronize geometry between views for shared-element animations.

```swift
struct HeroView: View {
    @Namespace private var heroSpace
    @State private var isExpanded = false

    var body: some View {
        Group {
            if isExpanded {
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                        isExpanded = false
                    }
                } label: {
                    DetailCard()
                        .matchedGeometryEffect(id: "card", in: heroSpace)
                }
            } else {
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                        isExpanded = true
                    }
                } label: {
                    ThumbnailCard()
                        .matchedGeometryEffect(id: "card", in: heroSpace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
```

Exactly one source view per ID should be visible; otherwise results are undefined.

## Navigation Zoom Transition (iOS 18+)

Pair `matchedTransitionSource` on the source view with
`.navigationTransition(.zoom(...))` on the destination.

```swift
struct GalleryView: View {
    @Namespace private var zoomSpace
    let items: [GalleryItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(items) { item in
                        NavigationLink {
                            GalleryDetail(item: item)
                                .navigationTransition(
                                    .zoom(sourceID: item.id, in: zoomSpace)
                                )
                        } label: {
                            ItemThumbnail(item: item)
                                .matchedTransitionSource(
                                    id: item.id, in: zoomSpace
                                )
                        }
                    }
                }
            }
        }
    }
}
```

Apply `.navigationTransition` on the destination view, not on inner containers.

## Transitions (iOS 17+)

Control how views animate on insertion and removal.

```swift
if showBanner {
    BannerView()
        .transition(.move(edge: .top).combined(with: .opacity))
}
```

See [All Transition Types](references/animation-advanced.md#all-transition-types-ios-17)
for the built-in catalog and custom `Transition` examples.

Asymmetric transitions:

```swift
.transition(.asymmetric(
    insertion: .push(from: .bottom),
    removal: .opacity
))
```

## ContentTransition (iOS 16+)

Animate in-place content changes without insertion/removal.

```swift
Text("\(score)")
    .contentTransition(.numericText(countsDown: false))
    .animation(.snappy, value: score)

// For SF Symbols
Image(systemName: isMuted ? "speaker.slash" : "speaker.wave.3")
    .contentTransition(.symbolEffect(.replace.downUp))
```

Types: `.identity`, `.interpolate`, `.opacity`,
`.numericText(countsDown:)`, `.numericText(value:)`, `.symbolEffect`.

## Symbol Effects (iOS 17+)

Animate SF Symbols with semantic effects. `.bounce`, `.pulse`, `.variableColor`,
`.scale`, `.appear`, `.disappear`, and `.replace` are iOS 17+; `.breathe`,
`.rotate`, and `.wiggle` require iOS 18+.

```swift
// Discrete (triggers on value change)
Image(systemName: "bell.fill").symbolEffect(.bounce, value: notificationCount)

// iOS 18+
Image(systemName: "arrow.clockwise")
    .symbolEffect(.wiggle.clockwise, value: refreshCount)

// Indefinite (active while condition holds)
Image(systemName: "wifi").symbolEffect(.pulse, isActive: isSearching)

// iOS 18+
Image(systemName: "mic.fill")
    .symbolEffect(.breathe, isActive: isRecording)

// Variable color with chaining
Image(systemName: "speaker.wave.3.fill")
    .symbolEffect(
        .variableColor.iterative.reversing.dimInactiveLayers,
        options: .repeating,
        isActive: isPlaying
    )
```

Scope: `.byLayer`, `.wholeSymbol`. Direction varies per effect.

## Symbol Rendering Modes

Choose `.monochrome`, `.hierarchical`, `.multicolor`, or `.palette` with
`.symbolRenderingMode(_:)`; use `.foregroundStyle` to supply palette colors.

**Variable symbols:** use `Image(systemName:variableValue:)` (iOS 16+) for percentage fill. Use `.symbolVariableValueMode(_:)` (iOS 26+) to choose `.draw` or `.color`.

```swift
Image(systemName: "wifi", variableValue: signalStrength) // 0.0...1.0
    .symbolVariableValueMode(.draw) // iOS 26+
```

> **Docs:** [SymbolRenderingMode](https://sosumi.ai/documentation/swiftui/symbolrenderingmode) · [symbolRenderingMode(_:)](https://sosumi.ai/documentation/swiftui/view/symbolrenderingmode(_:)) · [Image(systemName:variableValue:)](https://sosumi.ai/documentation/swiftui/image/init(systemname:variablevalue:)) · [symbolVariableValueMode(_:)](https://sosumi.ai/documentation/swiftui/view/symbolvariablevaluemode(_:))

## Common Mistakes

### 1. Using bare `.animation(_:)` when you need precise scope

```swift
// TOO BROAD — applies when the view changes
.animation(.easeIn)

.animation(.easeIn, value: isVisible) // CORRECT: value-bound

// CORRECT — scope animation to selected modifiers
.animation(.easeIn) { content in
    content.opacity(isVisible ? 1.0 : 0.0)
}

withAnimation(.easeIn) { isVisible.toggle() } // CORRECT: own mutation
```

### 2. Expensive work or actor-isolated reads inside animation closures

`keyframeAnimator` / `PhaseAnimator` content closures run every frame. Precompute expensive values, animate only visual properties, and capture state/env values before `@Sendable` keyframe closures.

### 3. Missing reduce motion support

For symbols, remove inherited effects; gate larger motion with `reduceMotion ? .none : animation`.
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
Image(systemName: "wifi").symbolEffect(.pulse, isActive: isSearching).symbolEffectsRemoved(reduceMotion)
```

### 4. Multiple matchedGeometryEffect sources

Only one source view per ID should be visible at a time. Multiple visible sources with the same ID cause undefined layout.

### 5. Using DispatchQueue or UIView.animate

```swift
// WRONG
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { withAnimation { isVisible = true } }
// CORRECT
withAnimation(.spring.delay(0.5)) { isVisible = true }
```

### 6. Forgetting animation on ContentTransition

```swift
// WRONG — no animation, content transition has no effect
Text("\(count)").contentTransition(.numericText(countsDown: true))
// CORRECT — pair with animation
Text("\(count)")
    .contentTransition(.numericText(countsDown: true))
    .animation(.snappy, value: count)
```

### 7. navigationTransition on wrong view

Apply `.navigationTransition(.zoom(sourceID:in:))` on the outermost destination view, not inside a container.

## Review Checklist

- [ ] Animation curve matches intent (spring for natural, ease for mechanical)
- [ ] `withAnimation` wraps the state change; implicit animation uses `.animation(_:body:)` for selective modifier scope or `.animation(_:value:)` with an explicit value
- [ ] `matchedGeometryEffect` has exactly one source per ID; zoom uses matching `id`/`namespace`
- [ ] `@Animatable` macro used when synthesis fits; manual `animatableData` kept only when custom packing is clearer
- [ ] `accessibilityReduceMotion` checked; no `DispatchQueue`/`UIView.animate`
- [ ] Transitions use `.transition()`; `contentTransition` is paired with animation and uses the narrowest implicit animation scope that fits
- [ ] Animated state changes on @MainActor; animation-driving types are Sendable

## References

- See [references/animation-advanced.md](references/animation-advanced.md) for CustomAnimation protocol, Spring variants, Transition types, symbol effects, Transaction system, UnitCurve, and performance guidance; Core Animation bridging patterns: [references/core-animation-bridge.md](references/core-animation-bridge.md).
