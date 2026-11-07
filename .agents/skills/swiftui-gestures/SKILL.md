---
name: swiftui-gestures
description: "Implement, review, or improve SwiftUI gesture handling. Use when adding tap, long press, drag, magnify, or rotate gestures, composing gestures with simultaneously/sequenced/exclusively, managing transient state with @GestureState, resolving parent/child gesture conflicts with highPriorityGesture or simultaneousGesture, building custom Gesture protocol conformances, or migrating from deprecated MagnificationGesture to MagnifyGesture or using the newer RotateGesture."
---

# SwiftUI Gestures (iOS 26+)

Review, write, and fix SwiftUI gesture interactions. Apply modern gesture APIs
with correct composition, state management, and conflict resolution using
Swift 6.3 patterns.

**Scope boundary:** This skill owns SwiftUI gesture recognition, composition,
gesture state, and gesture-specific accessibility alternatives. Broader
SwiftUI architecture/state ownership belongs in `swiftui-patterns`; list,
scroll, form, and control layout belongs in `swiftui-layout-components`; broad
UIKit bridging belongs in `swiftui-uikit-interop`.

When correcting Apple API availability, deprecation, or behavior claims, cite
the relevant Sosumi or official Apple documentation URL in the response.

## Contents

- [Gesture Overview](#gesture-overview)
- [TapGesture](#tapgesture)
- [LongPressGesture](#longpressgesture)
- [DragGesture](#draggesture)
- [MagnifyGesture (iOS 17+)](#magnifygesture-ios-17)
- [RotateGesture (iOS 17+)](#rotategesture-ios-17)
- [Gesture Composition](#gesture-composition)
- [`@GestureState`](#gesturestate)
- [Adding Gestures to Views](#adding-gestures-to-views)
- [Custom Gesture Protocol](#custom-gesture-protocol)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## Gesture Overview

| Gesture | Type | Value | Since |
|---|---|---|---|
| `TapGesture` | Discrete | `Void` | iOS 13 |
| `LongPressGesture` | Discrete | `Bool` | iOS 13 |
| `DragGesture` | Continuous | `DragGesture.Value` | iOS 13 |
| `MagnifyGesture` | Continuous | `MagnifyGesture.Value` | iOS 17 |
| `RotateGesture` | Continuous | `RotateGesture.Value` | iOS 17 |
| `SpatialTapGesture` | Discrete | `SpatialTapGesture.Value` | iOS 16 |

**Discrete** gestures fire once (`.onEnded`). **Continuous** gestures stream
updates (`.onChanged`, `.onEnded`, `.updating`).

## TapGesture

Recognizes one or more taps. Use the `count` parameter for multi-tap.

```swift
// Single, double, and triple tap
TapGesture()            .onEnded { tapped.toggle() }
TapGesture(count: 2)    .onEnded { handleDoubleTap() }
TapGesture(count: 3)    .onEnded { handleTripleTap() }

// Shorthand modifier
Text("Tap me").onTapGesture(count: 2) { handleDoubleTap() }
```

## LongPressGesture

Succeeds after the user holds for `minimumDuration`. Fails if finger moves
beyond `maximumDistance`.

```swift
// Basic long press (0.5s default)
LongPressGesture()
    .onEnded { _ in showMenu = true }

// Custom duration and distance tolerance
LongPressGesture(minimumDuration: 1.0, maximumDistance: 10)
    .onEnded { _ in triggerHaptic() }
```

With visual feedback via `@GestureState` + `.updating()`:

```swift
@GestureState private var isPressing = false

Circle()
    .fill(isPressing ? .red : .blue)
    .scaleEffect(isPressing ? 1.2 : 1.0)
    .gesture(
        LongPressGesture(minimumDuration: 0.8)
            .updating($isPressing) { current, state, _ in state = current }
            .onEnded { _ in completedLongPress = true }
    )
```

Shorthand: `.onLongPressGesture(minimumDuration:perform:onPressingChanged:)`.

## DragGesture

Tracks finger movement. `Value` provides `startLocation`, `location`,
`translation`, `velocity`, and `predictedEndTranslation`.
`DragGesture.Value.velocity` is available with `DragGesture` from iOS 13+;
do not confuse it with iOS 17+ gesture types such as `MagnifyGesture` and
`RotateGesture`.

```swift
@State private var offset = CGSize.zero

RoundedRectangle(cornerRadius: 16)
    .fill(.blue)
    .frame(width: 100, height: 100)
    .offset(offset)
    .gesture(
        DragGesture()
            .onChanged { value in offset = value.translation }
            .onEnded { _ in withAnimation(.spring) { offset = .zero } }
    )
```

Configure minimum distance and coordinate space:

```swift
DragGesture(minimumDistance: 20, coordinateSpace: .global)
```

## MagnifyGesture (iOS 17+)

Replaces the deprecated `MagnificationGesture`. Tracks pinch-to-zoom scale.

```swift
@GestureState private var magnifyBy = 1.0

Image("photo")
    .resizable().scaledToFit()
    .scaleEffect(magnifyBy)
    .gesture(
        MagnifyGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value.magnification
            }
    )
```

## RotateGesture (iOS 17+)

`RotateGesture` is the newer alternative to `RotationGesture`. Tracks two-finger rotation angle.

```swift
@State private var angle = Angle.zero

Rectangle()
    .fill(.blue).frame(width: 200, height: 200)
    .rotationEffect(angle)
    .gesture(
        RotateGesture(minimumAngleDelta: .degrees(1))
            .onChanged { value in angle = value.rotation }
    )
```

For persisted, clamped magnification and combined rotation examples, load
[references/gesture-patterns.md](references/gesture-patterns.md).

## Gesture Composition

### `.simultaneously(with:)` — both gestures recognized at the same time

```swift
let magnify = MagnifyGesture()
    .onChanged { value in scale = value.magnification }

let rotate = RotateGesture()
    .onChanged { value in angle = value.rotation }

Image("photo")
    .scaleEffect(scale)
    .rotationEffect(angle)
    .gesture(magnify.simultaneously(with: rotate))
```

The value is `SimultaneousGesture.Value` with `.first` and `.second` optionals.

### `.sequenced(before:)` — first must succeed before second begins

```swift
let longPressBeforeDrag = LongPressGesture(minimumDuration: 0.5)
    .sequenced(before: DragGesture())
    .onEnded { value in
        guard case .second(true, let drag?) = value else { return }
        finalOffset.width += drag.translation.width
        finalOffset.height += drag.translation.height
    }
```

### `.exclusively(before:)` — only one succeeds (first has priority)

```swift
let doubleTapOrLongPress = TapGesture(count: 2)
    .exclusively(before:
        LongPressGesture()
    )
    .onEnded { result in
        switch result {
        case .first(_): handleDoubleTap()
        case .second(_): handleLongPress()
        }
    }
```

## `@GestureState`

`@GestureState` is a property wrapper that **automatically resets** to its
initial value when the gesture ends. Use for transient feedback; use `@State`
for values that persist.

```swift
@GestureState private var dragOffset = CGSize.zero  // resets to .zero
@State private var position = CGSize.zero            // persists

Circle()
    .offset(
        x: position.width + dragOffset.width,
        y: position.height + dragOffset.height
    )
    .gesture(
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                position.width += value.translation.width
                position.height += value.translation.height
            }
    )
```

Custom reset with animation: `@GestureState(resetTransaction: Transaction(animation: .spring))`

## Adding Gestures to Views

Three modifiers control gesture priority in the view hierarchy:

| Modifier | Behavior |
|---|---|
| `.gesture()` | Lower precedence than gestures already defined by the view or its children. |
| `.highPriorityGesture()` | Added gesture takes precedence over existing gestures. |
| `.simultaneousGesture()` | Added gesture processes at the same priority as existing gestures. |

```swift
let parentTap = TapGesture().onEnded { handleParent() }

VStack {
    Image(systemName: "star.fill")
        .onTapGesture { handleChild() }
}
.simultaneousGesture(parentTap) // Both handlers run on child content.
```

Use `.gesture(parentTap)` for the default lower-precedence parent gesture, or
`.highPriorityGesture(parentTap)` when the added parent gesture should win.

### GestureMask

Control which gestures participate when using `.gesture(_:including:)`:

```swift
.gesture(drag, including: .gesture)   // added gesture; disables subview gestures
.gesture(drag, including: .subviews)  // subview gestures; disables added gesture
.gesture(drag, including: .all)       // default: added + subview gestures
.gesture(drag, including: .none)      // disables added + subview gestures
```

## Custom Gesture Protocol

Create reusable gestures by conforming to `Gesture`:

```swift
struct SwipeGesture: Gesture {
    enum Direction { case left, right, up, down }
    typealias Value = Direction

    let minimumDistance: CGFloat

    init(minimumDistance: CGFloat = 50) {
        self.minimumDistance = minimumDistance
    }

    var body: AnyGesture<Direction> {
        AnyGesture(
            DragGesture(minimumDistance: minimumDistance)
                .map { value in
                    let h = value.translation.width, v = value.translation.height
                    if abs(h) > abs(v) {
                        return h > 0 ? .right : .left
                    } else {
                        return v > 0 ? .down : .up
                    }
                }
        )
    }
}

// Usage
Rectangle().gesture(SwipeGesture().onEnded { print("Swiped \($0)") })
```

Wrap in a `View` extension for ergonomic API:

```swift
extension View {
    func onSwipe(perform action: @escaping (SwipeGesture.Direction) -> Void) -> some View {
        gesture(SwipeGesture().onEnded(action))
    }
}
```

## Common Mistakes

### 1. Misreading parent/child gesture precedence

Do not assume a parent `.gesture()` overrides child gestures. Choose the
relationship explicitly as shown in [Adding Gestures to Views](#adding-gestures-to-views).

### 2. Using `@State` instead of `@GestureState` for transient state

Use `@GestureState` for values that should reset when recognition ends; keep
persistent results in `@State`. See [`@GestureState`](#gesturestate).

### 3. Not using .updating() for intermediate feedback

```swift
// DON'T: No visual feedback during long press
LongPressGesture(minimumDuration: 2.0)
    .onEnded { _ in showResult = true }

// DO: Provide feedback while pressing
@GestureState private var isPressing = false

LongPressGesture(minimumDuration: 2.0)
    .updating($isPressing) { current, state, _ in
        state = current
    }
    .onEnded { _ in showResult = true }
```

### 4. Using deprecated gesture types on iOS 17+

```swift
// DON'T: Deprecated since iOS 17
MagnificationGesture()   // deprecated — use MagnifyGesture()

// DO: Use newer gesture types
MagnifyGesture()         // iOS 17+
RotateGesture()          // iOS 17+ (newer alternative to RotationGesture)
```

### 5. Heavy computation in onChanged

```swift
// DON'T: Expensive work called every frame (~60-120 Hz)
DragGesture()
    .onChanged { value in
        let result = performExpensiveHitTest(at: value.location)
        let filtered = applyComplexFilter(result)
        updateModel(filtered)
    }

// DO: Throttle or defer expensive work
DragGesture()
    .onChanged { value in
        dragPosition = value.location  // lightweight state update only
    }
    .onEnded { value in
        performExpensiveHitTest(at: value.location)  // once at end
    }
```

### 6. Using onTapGesture for actions that should be a Button

```swift
// DON'T: onTapGesture has no accessibility traits, VoiceOver role,
// Voice Control targeting, Switch Control scanning, or keyboard activation
Text("Delete")
    .onTapGesture { deleteItem() }

// DO: Button provides all of these automatically
Button("Delete", role: .destructive) { deleteItem() }

// DO: For custom visuals, use ButtonStyle instead of onTapGesture
Button { toggleExpanded() } label: {
    CardView()
}
.buttonStyle(.plain)
```

Reserve `onTapGesture` for multi-tap (`count: 2+`), tap-location-dependent
behavior, or adding tap recognition to non-interactive content that already
has appropriate accessibility traits.

## Review Checklist

- [ ] Correct gesture type: `MagnifyGesture`/`RotateGesture` (not deprecated `Magnification`/`Rotation` variants)
- [ ] `@GestureState` used for transient values that should reset; `@State` for persisted values
- [ ] `.updating()` provides intermediate visual feedback during continuous gestures
- [ ] Parent/child conflicts resolved with `.highPriorityGesture()` or `.simultaneousGesture()`
- [ ] `onChanged` closures are lightweight — no heavy computation every frame
- [ ] Composed gestures use correct combinator: `simultaneously`, `sequenced`, or `exclusively`
- [ ] Persisted scale/rotation clamped to reasonable bounds in `onEnded`
- [ ] Custom `Gesture` conformances return a gesture body; use `AnyGesture<Value>` when mapping to a custom `Value`
- [ ] Gesture-driven animations use `.spring` or similar for natural deceleration
- [ ] `GestureMask` considered when mixing gestures across view hierarchy levels
- [ ] `onTapGesture` only used where `count > 1`, tap location, or coordinate space matters — plain single-tap actions use `Button` instead

## References

- Read [references/gesture-patterns.md](references/gesture-patterns.md) when the task needs full drag-to-reorder, pinch-to-zoom, combined rotate+scale, velocity/projection, sequenced gesture state-machine, or gesture-specific UIKit interop examples.
- [Gesture protocol](https://sosumi.ai/documentation/swiftui/gesture)
- [TapGesture](https://sosumi.ai/documentation/swiftui/tapgesture)
- [LongPressGesture](https://sosumi.ai/documentation/swiftui/longpressgesture)
- [DragGesture](https://sosumi.ai/documentation/swiftui/draggesture)
- [DragGesture.Value.velocity](https://sosumi.ai/documentation/swiftui/draggesture/value/velocity)
- [MagnifyGesture](https://sosumi.ai/documentation/swiftui/magnifygesture)
- [RotateGesture](https://sosumi.ai/documentation/swiftui/rotategesture)
- [GestureState](https://sosumi.ai/documentation/swiftui/gesturestate)
- [Composing SwiftUI gestures](https://sosumi.ai/documentation/swiftui/composing-swiftui-gestures)
- [Adding interactivity with gestures](https://sosumi.ai/documentation/swiftui/adding-interactivity-with-gestures)
