---
name: swiftui-uikit-interop
description: "Bridges UIKit and SwiftUI with UIViewRepresentable, UIViewControllerRepresentable, UIHostingController, UIHostingConfiguration, coordinator delegates, and UIKit automatic observation tracking for shared @Observable state. Use when wrapping UIKit-only or third-party UIKit views/controllers in SwiftUI, embedding SwiftUI in UIKit, integrating mail/share/document/PDF/text-view surfaces, or migrating UIKit apps to SwiftUI incrementally."
---

# SwiftUI-UIKit Interop

Bridge UIKit and SwiftUI in both directions: wrap UIKit views and controllers, embed SwiftUI in UIKit screens, and synchronize state without duplicating lifecycle ownership.

See [references/representable-recipes.md](references/representable-recipes.md) for complete wrapping recipes and [references/hosting-migration.md](references/hosting-migration.md) for UIKit-to-SwiftUI migration patterns.

## Contents

- [UIViewRepresentable Protocol](#uiviewrepresentable-protocol)
- [UIViewControllerRepresentable Protocol](#uiviewcontrollerrepresentable-protocol)
- [The Coordinator Pattern](#the-coordinator-pattern)
- [UIHostingController](#uihostingcontroller)
- [Sizing and Layout](#sizing-and-layout)
- [State Synchronization Patterns](#state-synchronization-patterns)
- [UIKit Automatic Observation Tracking](#uikit-automatic-observation-tracking)
- [Sendable Considerations](#sendable-considerations)
- [Common Mistakes](#common-mistakes)
- [Review Checklist](#review-checklist)
- [References](#references)

## UIViewRepresentable Protocol

Use `UIViewRepresentable` to wrap any `UIView` subclass for use in SwiftUI.

### Required Methods

```swift
struct WrappedTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        // Called ONCE when SwiftUI inserts this view into the hierarchy.
        // Create and return the UIKit view. One-time setup goes here.
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Called on EVERY SwiftUI state change that affects this view.
        // Synchronize SwiftUI state into the UIKit view.
        // Guard against redundant updates to avoid loops.
        if uiView.text != text {
            uiView.text = text
        }
    }
}
```

### Lifecycle Timing

| Method | When Called | Purpose |
|--------|-----------|---------|
| `makeCoordinator()` | Before `makeUIView`. Once per representable lifetime. | Create the delegate/datasource reference type. |
| `makeUIView(context:)` | Once, when the representable enters the view tree. | Allocate and configure the UIKit view. |
| `updateUIView(_:context:)` | Immediately after `makeUIView`, then on every relevant state change. | Push SwiftUI state into the UIKit view. |
| `dismantleUIView(_:coordinator:)` | When the representable is removed from the view tree. | Clean up observers, timers, subscriptions. |
| `sizeThatFits(_:uiView:context:)` | During layout, when SwiftUI needs the view's ideal size. iOS 16+. | Return a custom size proposal. |

**Why `updateUIView` is the most important method:** SwiftUI calls it every time any `@Binding`, `@State`, `@Environment`, or `@Observable` property read by the representable changes. All state synchronization from SwiftUI to UIKit happens here. If you skip a property, the UIKit view will fall out of sync.

### Optional: dismantleUIView

```swift
static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
    // Remove observers, invalidate timers, cancel subscriptions.
    // The coordinator is passed in so you can access state stored on it.
    coordinator.cancellables.removeAll()
}
```

### Optional: sizeThatFits (iOS 16+)

```swift
@available(iOS 16.0, *)
func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView: UITextView,
    context: Context
) -> CGSize? {
    // Return nil to fall back to UIKit's intrinsicContentSize.
    // Return a CGSize to override SwiftUI's sizing for this view.
    let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
    let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    return size
}
```

## UIViewControllerRepresentable Protocol

Use `UIViewControllerRepresentable` to wrap a `UIViewController` subclass -- typically for system pickers, document scanners, mail compose, or any controller that presents modally.

```swift
struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // Usually empty for modal controllers -- nothing to push from SwiftUI.
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
}
```

### Handling Results from Presented Controllers

The coordinator captures delegate callbacks and routes results back to SwiftUI through the parent's `@Binding` or closures:

```swift
extension DocumentScannerView {
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            parent.scannedImages = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.dismiss()
        }
    }
}
```

## The Coordinator Pattern

### Why Coordinators Exist

UIKit delegates, data sources, and target-action patterns require a reference type (`class`). SwiftUI representable structs are value types and cannot serve as delegates. The Coordinator is a `class` instance that SwiftUI creates and manages for you -- it lives as long as the representable view.

### Structure

Always nest the Coordinator inside the representable or in an extension. Store a reference to `parent` (the representable struct) so the coordinator can write back to `@Binding` properties.

```swift
struct SearchBarView: UIViewRepresentable {
    @Binding var text: String
    var onSearch: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UISearchBar {
        let bar = UISearchBar()
        bar.delegate = context.coordinator  // Set delegate HERE, not in updateUIView
        return bar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBarView

        init(_ parent: SearchBarView) { self.parent = parent }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            parent.onSearch(parent.text)
            searchBar.resignFirstResponder()
        }
    }
}
```

### Key Rules

1. **Set the delegate in `makeUIView`/`makeUIViewController`, never in `updateUIView`.** The update method can run many times for state changes affecting the represented view -- setting the delegate there causes redundant assignment and can trigger unexpected side effects.

2. **Refresh copied parent state yourself.** If the coordinator stores the representable in a `var parent`, assign `context.coordinator.parent = self` at the start of `updateUIView` or `updateUIViewController`. Bindings still point at their source of truth, but closures and non-binding values are copied into the coordinator.

3. **Use `[weak coordinator]` in closures** to avoid retain cycles between the coordinator and UIKit objects that capture it.

## UIHostingController

Embed SwiftUI views inside UIKit view controllers using `UIHostingController`.

### Basic Embedding

```swift
final class ProfileViewController: UIViewController {
    private let hostingController = UIHostingController(rootView: ProfileView())

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Add as child
        addChild(hostingController)

        // 2. Add and constrain the view
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 3. Notify the child
        hostingController.didMove(toParent: self)
    }
}
```

The three-step sequence (addChild, add view, didMove) is mandatory. Skipping any step causes containment callbacks to misfire, which breaks appearance transitions and trait propagation.

### Sizing Options (iOS 16+)

```swift
@available(iOS 16.0, *)
hostingController.sizingOptions = [.intrinsicContentSize]
```

| Option | Effect |
|--------|--------|
| `.intrinsicContentSize` | The hosting controller's view reports its SwiftUI content size as `intrinsicContentSize`. Use in Auto Layout when the hosted view should size itself. |
| `.preferredContentSize` | Updates `preferredContentSize` to match SwiftUI content. Use when presenting as a popover or form sheet. |

### Updating the Root View

When data changes in UIKit, push new state into the hosted SwiftUI view:

```swift
func updateProfile(_ profile: Profile) {
    hostingController.rootView = ProfileView(profile: profile)
}
```

For observable models, pass an `@Observable` object and SwiftUI tracks changes automatically -- no need to reassign `rootView`.

### UIHostingConfiguration (iOS 16+)

Render SwiftUI content directly inside `UICollectionViewCell` or `UITableViewCell` without managing a child hosting controller:

```swift
@available(iOS 16.0, *)
func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.contentConfiguration = UIHostingConfiguration {
        ItemRow(item: items[indexPath.item])
    }
    return cell
}
```

## Sizing and Layout

### intrinsicContentSize Bridging

UIKit views wrapped in `UIViewRepresentable` communicate their natural size to SwiftUI through `intrinsicContentSize`. SwiftUI respects this during layout unless overridden by `frame()` or `fixedSize()`.

### SwiftUI-Owned Geometry

SwiftUI owns the represented view's `center`, `bounds`, `frame`, and `transform`. Do not set those properties directly on the `uiView` in `makeUIView` or `updateUIView`. Use `sizeThatFits`, intrinsic content size, SwiftUI layout modifiers, or layout code inside a custom UIKit subview for internal sublayers.

### fixedSize() and frame() Interactions

| SwiftUI Modifier | Effect on Representable |
|-----------------|------------------------|
| No modifier | SwiftUI uses `intrinsicContentSize` as ideal size; the view is flexible. |
| `.fixedSize()` | Forces the representable to its ideal (intrinsic) size in both axes. |
| `.fixedSize(horizontal: true, vertical: false)` | Fixes width to intrinsic; height remains flexible. |
| `.frame(width:height:)` | Overrides the proposed size; UIKit view receives this size. |

### Auto Layout with UIHostingController

When embedding `UIHostingController` as a child, pin its view with constraints. Use `.sizingOptions = [.intrinsicContentSize]` so Auto Layout can query the SwiftUI content's natural size for self-sizing cells or variable-height sections.

## State Synchronization Patterns

### `@Binding`: Two-Way Sync (SwiftUI <-> UIKit)

Use `@Binding` when both sides read and write the same value. The coordinator writes to `parent.bindingProperty` in delegate callbacks; `updateUIView` reads the binding and pushes it into the UIKit view.

```swift
// SwiftUI -> UIKit: in updateUIView
if uiView.text != text { uiView.text = text }

// UIKit -> SwiftUI: in Coordinator delegate method
func textViewDidChange(_ textView: UITextView) {
    parent.text = textView.text
}
```

### Closures: One-Way Events (UIKit -> SwiftUI)

For fire-and-forget events (button tapped, search submitted, scan completed), pass a closure instead of a binding:

```swift
struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    var onNavigationFinished: ((URL) -> Void)?
}
```

### Environment Values

Access SwiftUI environment values inside representable methods via `context.environment`:

```swift
func updateUIView(_ uiView: UITextView, context: Context) {
    let isEnabled = context.environment.isEnabled
    uiView.isEditable = isEnabled

    // Respond to color scheme changes
    let colorScheme = context.environment.colorScheme
    uiView.backgroundColor = colorScheme == .dark ? .systemGray6 : .white
}
```

### Avoiding Update Loops

`updateUIView` is called when SwiftUI has new state for the represented view -- including changes triggered by the coordinator writing to a `@Binding`. Guard against redundant updates to prevent infinite loops:

```swift
func updateUIView(_ uiView: UITextView, context: Context) {
    // GUARD: Only update if values actually differ
    if uiView.text != text {
        uiView.text = text
    }
}
```

Without the guard, setting `uiView.text` may trigger the delegate's `textViewDidChange`, which writes to `parent.text`, which triggers `updateUIView` again.

## UIKit Automatic Observation Tracking

For UIKit screens that share an `@Observable` model with SwiftUI, keep the screen UIKit and read observed state from UIKit's tracked update hooks:

- iOS 26+: use `updateProperties()` for labels, colors, visibility, enabled state, and other non-layout UI; use layout hooks for geometry; use cell configuration update handlers for cells.
- iOS 18: automatic UIKit tracking requires `UIObservationTrackingEnabled` in `Info.plist`.
- iOS 17: `@Observable` exists, but UIKit automatic observation tracking is not available. Manual `withObservationTracking` is one-shot; do not build polling loops around it.
- iOS 15-16 or existing `ObservableObject`: use Combine `objectWillChange`, delegates, notifications, or explicit callbacks.

See [references/hosting-migration.md](references/hosting-migration.md#automatic-observation-tracking-in-uikit) for migration patterns.

## Sendable Considerations

UIKit delegate protocols are not `Sendable`. When the coordinator conforms to a UIKit delegate, it inherits main-actor isolation from UIKit. Mark coordinators `@MainActor` or use `nonisolated` only for methods that truly do not touch UIKit state. In Swift 6 strict concurrency:

```swift
@MainActor
final class Coordinator: NSObject, UISearchBarDelegate {
    var parent: SearchBarView
    init(_ parent: SearchBarView) { self.parent = parent }
    // Delegate methods are main-actor-isolated -- safe to access UIKit and @Binding.
}
```

If passing closures across isolation boundaries, ensure they are `@Sendable` or captured on the correct actor.

## Common Mistakes

| Mistake | Fix |
|---|---|
| UIKit object or delegate recreated in `update*` | Create once in `make*`; update only changed state. |
| Represented frame/bounds/transform mutated directly | Let SwiftUI size it; use intrinsic size, `sizeThatFits`, modifiers, or internal layout. |
| Coordinator retained by UIKit closures | Capture it weakly and keep one lifecycle owner. |
| Picker/controller exit path misses dismissal or completion | Route every delegate exit through one coordinator cleanup path. |
| Observers, timers, or subscriptions outlive the view | Remove/cancel them in `dismantle*`. |
| Hosting controller uses manual frame without containment | Use Auto Layout and `addChild`/`didMove(toParent:)`. |
| `@State` used inside a coordinator | Use stored properties and communicate through bindings/callbacks. |
| `withObservationTracking` is polled manually | Use UIKit automatic observation hooks where available or explicit invalidation on older targets. |

## Review Checklist

- [ ] View/controller created in `make*`, not `update*`
- [ ] Coordinator set as delegate in `make*`, not `update*`
- [ ] `@Binding` used for two-way state sync
- [ ] `updateUIView` handles all SwiftUI state changes with redundancy guards
- [ ] `dismantleUIView` cleans up observers/timers if needed
- [ ] No retain cycles between coordinator and closures (`[weak coordinator]`)
- [ ] `UIHostingController` properly added as child (`addChild` + `didMove(toParent:)`)
- [ ] Sizing strategy chosen (`intrinsicContentSize` vs fixed `frame` vs `sizeThatFits`)
- [ ] Represented view geometry left to SwiftUI (`frame`, `bounds`, `center`, `transform` not mutated directly)
- [ ] Environment values read in `updateUIView` via `context.environment` where needed
- [ ] UIKit `@Observable` reads use automatic tracking hooks on iOS 18+/26+, not polling; iOS 17 is manual one-shot only
- [ ] Coordinator marked `@MainActor` for strict concurrency
- [ ] Modal controllers dismiss in all delegate exit paths (success, cancel, error)
- [ ] `UIHostingConfiguration` used for collection/table view cells instead of manual hosting (iOS 16+)

## References

- Wrapping recipes: [references/representable-recipes.md](references/representable-recipes.md)
- Migration patterns: [references/hosting-migration.md](references/hosting-migration.md)
- Apple docs: [UIViewRepresentable](https://sosumi.ai/documentation/swiftui/UIViewRepresentable)
- Apple docs: [UIViewControllerRepresentable](https://sosumi.ai/documentation/swiftui/UIViewControllerRepresentable)
- Apple docs: [UIHostingController](https://sosumi.ai/documentation/swiftui/UIHostingController)
