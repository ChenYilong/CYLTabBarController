# Transitions

View insertion/removal transitions, matched geometry effects, navigation transitions, and content transitions.

## View Transitions

Transitions define how a view appears and disappears when added to or removed from the view hierarchy via conditional rendering (`if`, `switch`, `ForEach`).

### Built-in Transitions

```swift
.transition(.opacity)                   // Fade in/out (iOS 13+)
.transition(.slide)                     // Slide from leading edge (iOS 13+)
.transition(.scale)                     // Scale from center (iOS 13+)
.transition(.scale(scale: 0.5))         // Scale from 50%
.transition(.scale(scale: 0, anchor: .bottom))  // Scale from bottom
.transition(.move(edge: .bottom))       // Slide from specific edge (iOS 13+)
.transition(.move(edge: .trailing))
.transition(.offset(x: 0, y: 50))      // Move from offset position (iOS 13+)
.transition(.push(from: .bottom))       // Push from edge with depth (iOS 16+)
.transition(.blurReplace)               // Blur out old, blur in new (iOS 17+)
.transition(.blurReplace(.downUp))      // Directional blur replace
.transition(.blurReplace(.upUp))
```

### Combined Transitions

```swift
// Both effects applied simultaneously
.transition(.opacity.combined(with: .scale))
.transition(.move(edge: .bottom).combined(with: .opacity))
```

### Asymmetric Transitions

Different animation for insertion vs removal:

```swift
.transition(.asymmetric(
    insertion: .push(from: .bottom),
    removal: .opacity
))

.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .move(edge: .trailing).combined(with: .opacity)
))
```

### Usage with Conditional Views

Transitions only work on views that are conditionally rendered:

```swift
VStack {
    if showDetail {
        DetailView()
            .transition(.slide)  // ✅ Works — view is added/removed
    }
}

VStack {
    DetailView()
        .opacity(showDetail ? 1 : 0)  // This is NOT a transition — it's an animation
        .transition(.slide)             // ❌ No effect — view is always present
}
```

Animate the state change to see the transition:

```swift
Button("Toggle") {
    withAnimation(.spring) {
        showDetail.toggle()
    }
}
```

### Custom Transitions

Build custom transitions using `ViewModifier`:

```swift
struct SlideAndFade: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isActive ? 30 : 0)
            .opacity(isActive ? 0 : 1)
            .scaleEffect(isActive ? 0.9 : 1)
    }
}

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .modifier(
            active: SlideAndFade(isActive: true),
            identity: SlideAndFade(isActive: false)
        )
    }
}

// Usage
DetailView()
    .transition(.slideAndFade)
```

### Transition Protocol (iOS 17+)

Compose built-ins first — `.scale.combined(with: .opacity)` covers most needs. When it can't, conform to `Transition` (the typed successor to `AnyTransition.modifier`):

```swift
struct Twirl: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.5)
            .opacity(phase.isIdentity ? 1 : 0)
            .rotationEffect(.degrees(
                phase == .willAppear ? 30 :
                phase == .didDisappear ? -30 : 0
            ))
    }
}

DetailView()
    .transition(Twirl())
```

The three-case `TransitionPhase` (`.willAppear`, `.identity`, `.didDisappear`) expresses what the `active`/`identity` modifier pair can't: insertion and removal can move in the *same* visual direction — e.g. content always exits downward instead of playing its entrance in reverse (WWDC24).

## matchedGeometryEffect (iOS 14+)

Creates a visual connection between two views by matching their geometry (position, size). Used for shared element transitions within the same view hierarchy.

### How It Works

Two views share an `id` and `namespace`. When one disappears and the other appears, SwiftUI animates the geometry change.

```swift
struct ExpandableCard: View {
    @Namespace private var animation
    @State private var isExpanded = false

    var body: some View {
        if isExpanded {
            ExpandedView()
                .matchedGeometryEffect(id: "card", in: animation)
                .onTapGesture {
                    withAnimation(.spring) {
                        isExpanded = false
                    }
                }
        } else {
            CompactView()
                .matchedGeometryEffect(id: "card", in: animation)
                .onTapGesture {
                    withAnimation(.spring) {
                        isExpanded = true
                    }
                }
        }
    }
}
```

### Rules

1. **@Namespace** — must declare a namespace with `@Namespace private var animation`
2. **Same id, same namespace** — both views use the same `id` and `in:` namespace
3. **Only one view at a time** — at any given moment, only one view with a given id should be in the hierarchy (use `if/else`, not showing both)
4. **isSource parameter** — when both views exist simultaneously (e.g., overlay), set `isSource: true` on the source and `isSource: false` on the target

```swift
// When both views coexist — source dictates geometry
SmallPhoto()
    .matchedGeometryEffect(id: "photo", in: ns, isSource: true)

LargePhoto()
    .matchedGeometryEffect(id: "photo", in: ns, isSource: false)
```

### Anti-Patterns

```swift
// ❌ WRONG: Both set isSource: true
view1.matchedGeometryEffect(id: "x", in: ns, isSource: true)
view2.matchedGeometryEffect(id: "x", in: ns, isSource: true)
// ✅ Only ONE should be isSource: true

// ❌ WRONG: Forgetting @Namespace
let animation = Namespace()  // This is wrong
// ✅ @Namespace private var animation

// ❌ WRONG: Using for NavigationStack push/pop transitions
NavigationLink { DetailView().matchedGeometryEffect(id: "item", in: ns) }
// matchedGeometryEffect does NOT work across NavigationStack push/pop
// ✅ Use matchedTransitionSource (iOS 18+) instead — see below
```

## Navigation Transitions (iOS 18+)

### matchedTransitionSource + navigationTransition(.zoom)

The correct way to create hero/zoom transitions with NavigationStack.

```swift
struct GalleryView: View {
    @Namespace private var namespace
    let photos: [Photo]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoThumbnail(photo: photo)
                                .matchedTransitionSource(id: photo.id, in: namespace)
                        }
                    }
                }
            }
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetailView(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
            }
        }
    }
}
```

### How It Differs from matchedGeometryEffect

| | matchedGeometryEffect | matchedTransitionSource |
|---|---|---|
| **Purpose** | Shared element within same hierarchy | Navigation push/pop transitions |
| **Works with NavigationStack** | No | Yes |
| **Availability** | iOS 14+ | iOS 18+ |
| **Both views exist** | Must coordinate with `isSource` | Source and destination are separate screens |
| **Configuration** | On both views | Source: `.matchedTransitionSource`, Destination: `.navigationTransition(.zoom)` |

### Other Navigation Transitions

```swift
// Slide transition (default NavigationStack behavior)
.navigationTransition(.slide)

// Zoom from a source
.navigationTransition(.zoom(sourceID: id, in: namespace))

// Automatic — system chooses based on context
.navigationTransition(.automatic)
```

### Customizing Zoom Appearance

```swift
PhotoThumbnail(photo: photo)
    .matchedTransitionSource(id: photo.id, in: namespace) { source in
        source
            .clipShape(.rect(cornerRadius: 12))
            .shadow(radius: 5)
    }

PhotoDetailView(photo: photo)
    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
```

### Zoom for Sheets and Full-Screen Covers

The same pairing works for modal presentation, not just push (WWDC24):

```swift
CardView(item: item)
    .matchedTransitionSource(id: item.id, in: namespace)

.sheet(item: $selectedItem) { item in
    ItemDetailView(item: item)
        .navigationTransition(.zoom(sourceID: item.id, in: namespace))
}
```

### UIKit Zoom Transitions (iOS 18+)

Set `preferredTransition` on the *pushed* view controller, capturing stable model identifiers — not views — since cells get reused and the closure re-runs on demand:

```swift
let detail = ItemDetailViewController(item: item)
detail.preferredTransition = .zoom { [id = item.id] context in
    // Re-resolve the source view from the identifier on every call
    collectionView.cellForItem(withID: id)
}
navigationController?.pushViewController(detail, animated: true)
```

### Interruptibility Rules (WWDC24)

Zoom transitions are continuously interactive — users can grab the view mid-push:

- An interrupted push is **never cancelled**. It completes to the Appeared state, then converts into a pop. Write appearance code assuming the push finishes.
- ❌ Don't gate push/pop calls on "is a transition running" — deferring navigation until animations settle makes the app feel unresponsive.
- ✅ Put cleanup in `viewDidAppear` / `viewDidDisappear` — with interruptible transitions these are the only callbacks guaranteed to fire.

## Bridging UIKit and SwiftUI Animations (iOS 18+)

Animate UIKit views with SwiftUI animation types, including springs that preserve gesture velocity (WWDC24):

```swift
UIView.animate(.spring(duration: 0.5)) {
    circleView.center = targetPoint
}
```

This animates the **layer's presentation values directly** — no `CAAnimation` is created, so presentation and model stay in sync mid-flight.

Inside `UIViewRepresentable.updateUIView`, bridge the SwiftUI transaction to UIKit changes with `context.animate`:

```swift
func updateUIView(_ uiView: BeadView, context: Context) {
    context.animate {
        uiView.beadPosition = beadPosition  // runs with the surrounding SwiftUI animation, if any
    }
}
```

## Gesture-Driven Transitions

Use `.interactiveSpring` while the gesture is changing and `.spring` when it ends — SwiftUI merges the two, retargets mid-flight, and carries the gesture's velocity into the settling spring automatically:

```swift
.gesture(
    DragGesture()
        .onChanged { value in
            withAnimation(.interactiveSpring) { offset = value.translation }
        }
        .onEnded { _ in
            withAnimation(.spring) { offset = .zero }
        }
)
```

## Content Transitions

Animate the content inside a view without adding/removing the view itself.

### Numeric Text (iOS 16+)

Animates number changes digit-by-digit:

```swift
Text(score, format: .number)
    .contentTransition(.numericText())
    .animation(.snappy, value: score)
```

With counting direction:

```swift
Text(value, format: .number)
    .contentTransition(.numericText(countsDown: value < previousValue))
```

### Interpolate (iOS 16+)

Smoothly interpolates between text styles (color, size):

```swift
Text("Status")
    .foregroundStyle(isActive ? .green : .red)
    .fontWeight(isActive ? .bold : .regular)
    .contentTransition(.interpolate)
    .animation(.smooth, value: isActive)
```

### Symbol Effect Replace (iOS 17+)

Animate SF Symbol changes:

```swift
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))
    .animation(.smooth, value: isPlaying)
```

With direction:

```swift
.contentTransition(.symbolEffect(.replace.downUp))
.contentTransition(.symbolEffect(.replace.upUp))
.contentTransition(.symbolEffect(.replace.offUp))
```

### Identity (No Transition)

Opt out of content transitions:

```swift
.contentTransition(.identity)
```

## Accessibility — Reduce Motion

Always provide alternatives for users with reduced motion enabled.

### Check Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    if showDetail {
        DetailView()
            .transition(reduceMotion ? .opacity : .slide.combined(with: .opacity))
    }
}
```

### Conditional Animation

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

func toggleDetail() {
    if reduceMotion {
        showDetail.toggle()  // No animation
    } else {
        withAnimation(.spring) {
            showDetail.toggle()
        }
    }
}
```

### Simplified Transitions

Replace complex multi-step transitions with simple fades:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var transition: AnyTransition {
    if reduceMotion {
        .opacity
    } else {
        .asymmetric(
            insertion: .push(from: .bottom).combined(with: .opacity),
            removal: .push(from: .top).combined(with: .opacity)
        )
    }
}
```
