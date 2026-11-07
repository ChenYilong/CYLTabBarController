# Gesture Patterns — Advanced Reference

Extended patterns for SwiftUI gesture handling. See the main `SKILL.md` for
core APIs and common mistakes.

## Contents

- [Pinch-to-Zoom with MagnifyGesture](#pinch-to-zoom-with-magnifygesture)
- [Combined Rotate + Scale](#combined-rotate--scale)
- [Drag-to-Reorder](#drag-to-reorder)
- [Gesture Velocity Calculations](#gesture-velocity-calculations)
- [Long-Press then Drag](#long-press-then-drag-sequenced-gesture-with-state-enum)
- [SwiftUI + UIKit Gesture Interop](#swiftui--uikit-gesture-interop)
- [Accessibility Considerations](#accessibility-considerations)

## Pinch-to-Zoom with MagnifyGesture

Full implementation with clamped scale, double-tap reset, and smooth animation:

```swift
struct PinchToZoomView: View {
    @State private var currentScale = 1.0
    @State private var currentOffset = CGSize.zero
    @GestureState private var gestureScale = 1.0
    @GestureState private var dragOffset = CGSize.zero

    private let minScale = 0.5
    private let maxScale = 5.0

    var body: some View {
        Image("photo")
            .resizable()
            .scaledToFit()
            .scaleEffect(currentScale * gestureScale)
            .offset(
                x: currentOffset.width + dragOffset.width,
                y: currentOffset.height + dragOffset.height
            )
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture)
            .onTapGesture(count: 2) {
                withAnimation(.spring) {
                    currentScale = 1.0
                    currentOffset = .zero
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($gestureScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                let newScale = currentScale * value.magnification
                withAnimation(.spring) {
                    currentScale = min(max(newScale, minScale), maxScale)
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                guard currentScale > 1.0 else { return }
                state = value.translation
            }
            .onEnded { value in
                guard currentScale > 1.0 else { return }
                currentOffset.width += value.translation.width
                currentOffset.height += value.translation.height
            }
    }
}
```

## Combined Rotate + Scale

Simultaneous rotation and magnification for image editing:

```swift
struct RotateScaleView: View {
    @State private var currentAngle = Angle.zero
    @State private var currentScale = 1.0
    @GestureState private var gestureAngle = Angle.zero
    @GestureState private var gestureScale = 1.0

    var body: some View {
        Image("sticker")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .rotationEffect(currentAngle + gestureAngle)
            .scaleEffect(currentScale * gestureScale)
            .gesture(
                RotateGesture()
                    .updating($gestureAngle) { value, state, _ in
                        state = value.rotation
                    }
                    .onEnded { value in
                        currentAngle += value.rotation
                    }
                    .simultaneously(with:
                        MagnifyGesture()
                            .updating($gestureScale) { value, state, _ in
                                state = value.magnification
                            }
                            .onEnded { value in
                                currentScale *= value.magnification
                                currentScale = min(max(currentScale, 0.3), 5.0)
                            }
                    )
            )
    }
}
```

## Drag-to-Reorder

Drag gesture with haptic feedback for list reordering:

```swift
struct ReorderableList: View {
    @State private var items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    @State private var draggingItem: String?
    @State private var dragOffset = CGSize.zero

    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                ItemRow(title: item, isDragging: draggingItem == item)
                    .offset(y: draggingItem == item ? dragOffset.height : 0)
                    .zIndex(draggingItem == item ? 1 : 0)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                switch value {
                                case .first(true):
                                    withAnimation(.spring) {
                                        draggingItem = item
                                    }
                                case .second(true, let drag):
                                    dragOffset = drag?.translation ?? .zero
                                    updateOrder(for: item, translation: dragOffset.height)
                                default:
                                    break
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring) {
                                    draggingItem = nil
                                    dragOffset = .zero
                                }
                            }
                    )
            }
        }
    }

    private func updateOrder(for item: String, translation: CGFloat) {
        guard let sourceIndex = items.firstIndex(of: item) else { return }
        let rowHeight: CGFloat = 50
        let offset = Int(translation / rowHeight)
        let destinationIndex = min(max(sourceIndex + offset, 0), items.count - 1)
        if sourceIndex != destinationIndex {
            withAnimation(.spring) {
                items.move(
                    fromOffsets: IndexSet(integer: sourceIndex),
                    toOffset: destinationIndex > sourceIndex
                        ? destinationIndex + 1 : destinationIndex
                )
            }
        }
    }
}

struct ItemRow: View {
    let title: String
    let isDragging: Bool

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(isDragging ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 8))
            .shadow(radius: isDragging ? 4 : 0)
            .scaleEffect(isDragging ? 1.05 : 1.0)
    }
}
```

## Gesture Velocity Calculations

Use `DragGesture.Value.velocity` for the current drag velocity. Use
`predictedEndTranslation` when you need a projection of where the drag would
end if the user stopped now.

```swift
struct FlickDismissView: View {
    @State private var offset = CGSize.zero
    @State private var isDismissed = false

    private let dismissThreshold: CGFloat = 200
    private let velocityThreshold: CGFloat = 800

    var body: some View {
        if !isDismissed {
            CardView()
                .offset(y: offset.height)
                .opacity(opacity)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                offset = value.translation
                            }
                        }
                        .onEnded { value in
                            let velocity = value.velocity.height
                            let distance = value.translation.height

                            if distance > dismissThreshold
                                || velocity > velocityThreshold
                            {
                                withAnimation(.spring) {
                                    isDismissed = true
                                }
                            } else {
                                withAnimation(.spring) {
                                    offset = .zero
                                }
                            }
                        }
                )
        }
    }

    private var opacity: Double {
        let progress = min(offset.height / dismissThreshold, 1.0)
        return 1.0 - (progress * 0.5)
    }
}
```

Projection heuristic from predicted end translation:

```swift
DragGesture()
    .onEnded { value in
        // Approximate velocity from predicted vs actual
        let predictedDelta = CGSize(
            width: value.predictedEndTranslation.width - value.translation.width,
            height: value.predictedEndTranslation.height - value.translation.height
        )
        let speed = sqrt(
            predictedDelta.width * predictedDelta.width
            + predictedDelta.height * predictedDelta.height
        )
        if speed > 500 { handleFlick() }
    }
```

## Long-Press then Drag (Sequenced Gesture with State Enum)

Model complex gesture states with an enum for clarity:

```swift
enum DragState {
    case inactive
    case pressing
    case dragging(translation: CGSize)

    var translation: CGSize {
        switch self {
        case .inactive, .pressing: return .zero
        case .dragging(let t): return t
        }
    }

    var isActive: Bool {
        switch self {
        case .inactive: return false
        case .pressing, .dragging: return true
        }
    }
}

struct LongPressDragView: View {
    @GestureState private var dragState = DragState.inactive
    @State private var position = CGSize.zero

    var body: some View {
        Circle()
            .fill(dragState.isActive ? .red : .blue)
            .frame(width: 80, height: 80)
            .shadow(radius: dragState.isActive ? 8 : 0)
            .offset(
                x: position.width + dragState.translation.width,
                y: position.height + dragState.translation.height
            )
            .animation(.spring, value: dragState.isActive)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture())
                    .updating($dragState) { value, state, _ in
                        switch value {
                        case .first(true):
                            state = .pressing
                        case .second(true, let drag):
                            state = .dragging(
                                translation: drag?.translation ?? .zero
                            )
                        default:
                            state = .inactive
                        }
                    }
                    .onEnded { value in
                        guard case .second(true, let drag?) = value else {
                            return
                        }
                        position.width += drag.translation.width
                        position.height += drag.translation.height
                    }
            )
    }
}
```

## SwiftUI + UIKit Gesture Interop

### UIGestureRecognizerRepresentable (iOS 18+)

Bridge UIKit gesture recognizers into SwiftUI:

```swift
struct PinchGestureView: UIGestureRecognizerRepresentable {
    @Binding var scale: CGFloat

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        UIPinchGestureRecognizer()
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPinchGestureRecognizer,
        context: Context
    ) {
        switch recognizer.state {
        case .changed:
            scale = recognizer.scale
        case .ended:
            scale = recognizer.scale
            recognizer.scale = 1.0
        default:
            break
        }
    }
}

// Usage in SwiftUI
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image("photo")
            .scaleEffect(scale)
            .gesture(PinchGestureView(scale: $scale))
    }
}
```

### Using SwiftUI gestures in UIKit via UIHostingController

```swift
class GestureHostingController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIView = InteractiveCard()
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}

struct InteractiveCard: View {
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.blue.gradient)
            .frame(width: 200, height: 300)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
            )
    }
}
```

### Coordinating UIKit and SwiftUI gestures

When mixing gesture recognizers, use `simultaneousGesture` on the SwiftUI side
and `UIGestureRecognizerDelegate` on the UIKit side to prevent conflicts:

```swift
// In your UIViewRepresentable coordinator
func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
) -> Bool {
    true  // allow both UIKit and SwiftUI gestures to fire
}
```

## Accessibility Considerations

Always provide accessible alternatives for gesture-driven interactions:

```swift
Image("draggable")
    .offset(offset)
    .gesture(dragGesture)
    .accessibilityAction(.default) { showAccessibleUI() }
    .accessibilityAction(named: "Move up") {
        withAnimation { offset.height -= 50 }
    }
    .accessibilityAction(named: "Move down") {
        withAnimation { offset.height += 50 }
    }
```
